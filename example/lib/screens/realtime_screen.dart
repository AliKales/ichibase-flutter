import 'package:flutter/material.dart';
import 'package:ichibase/ichibase.dart';

import '../app_config.dart';
import '../widgets/section_card.dart';

/// Subscribe to live database changes and stream them into a scrolling list.
///
/// For postgres / both flavors it watches the `posts` table; for mongo-only it
/// watches the `orders` collection.
class RealtimeScreen extends StatefulWidget {
  const RealtimeScreen({super.key});

  @override
  State<RealtimeScreen> createState() => _RealtimeScreenState();
}

class _RealtimeScreenState extends State<RealtimeScreen> {
  Subscription? _sub;
  final List<_Event> _events = [];
  bool _busy = false;
  // _id of the last inserted test doc, so update/delete can target it.
  dynamic _lastId;

  bool get _isMongo => AppConfig.current!.flavor == DbFlavor.mongo;

  @override
  void dispose() {
    _sub?.unsubscribe();
    super.dispose();
  }

  void _start() {
    if (_sub != null) return;
    final ichi = Ichibase.instance;
    final mongo = _isMongo;
    final sub = ichi.realtime.subscribe(
      kind: mongo ? 'mongo' : 'postgres',
      table: mongo ? null : 'posts',
      collection: mongo ? 'orders' : null,
      // Event names are case-sensitive on the wire: Mongo emits lowercase
      // (insert/update/delete), Postgres uppercase (INSERT/UPDATE/DELETE).
      // Passing the wrong case here silently filters out every event.
      events: mongo
          ? const ['insert', 'update', 'delete']
          : const ['INSERT', 'UPDATE', 'DELETE'],
      onMessage: _onMessage,
    );
    setState(() => _sub = sub);
    _snack('Subscribed. Insert/update/delete a row to see events.');
  }

  void _stop() {
    _sub?.unsubscribe();
    setState(() => _sub = null);
    _snack('Unsubscribed.');
  }

  /// Insert a test record from THIS screen while subscribed, so the event
  /// arrives here. Navigating to another screen to make a change would
  /// dispose this screen and close the subscription first.
  Future<void> _trigger() async {
    setState(() => _busy = true);
    try {
      final ichi = Ichibase.instance;
      final res = _isMongo
          ? await ichi.mongo
              .collection('orders')
              .insertOne({'item': 'rt-test', 'total': 1})
          : await ichi.from('posts').insert(
              {'title': 'rt-${DateTime.now().millisecondsSinceEpoch}'},
            );
      if (!mounted) return;
      if (res.ok && _isMongo) {
        final d = res.data;
        _lastId = d is Map ? (d['_id'] ?? d['insertedId']) : null;
      }
      _snack(res.ok
          ? 'Inserted — watch for an event, then try update / delete.'
          : '${res.error?.code}: ${res.error?.detail}');
    } catch (e) {
      if (mounted) _snack('Insert failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Update ($inc) / delete the last inserted doc, so all three Mongo event
  /// types can be seen from this screen without leaving it.
  Future<void> _bumpLast() async {
    if (_lastId == null) return;
    setState(() => _busy = true);
    try {
      final res = await Ichibase.instance.mongo.collection('orders').updateOne(
        {'_id': _lastId},
        {
          r'$inc': {'total': 1},
        },
      );
      if (mounted) {
        _snack(res.ok
            ? 'Updated — watch for an event.'
            : '${res.error?.code}: ${res.error?.detail}');
      }
    } catch (e) {
      if (mounted) _snack('Update failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteLast() async {
    if (_lastId == null) return;
    setState(() => _busy = true);
    try {
      final res = await Ichibase.instance.mongo
          .collection('orders')
          .deleteOne({'_id': _lastId});
      if (mounted) {
        if (res.ok) _lastId = null;
        _snack(res.ok
            ? 'Deleted — watch for an event.'
            : '${res.error?.code}: ${res.error?.detail}');
      }
    } catch (e) {
      if (mounted) _snack('Delete failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onMessage(Map<String, dynamic> m) {
    if (m['type'] != 'change') return;
    if (!mounted) return;
    setState(() {
      _events.insert(
        0,
        _Event(
          event: '${m['event']}',
          target: '${m['table'] ?? m['collection'] ?? ''}',
          record: m['record'],
          at: TimeOfDay.now().format(context),
        ),
      );
      if (_events.length > 100) _events.removeRange(100, _events.length);
    });
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final running = _sub != null;
    final target = _isMongo ? 'orders (collection)' : 'posts (table)';

    return Scaffold(
      appBar: AppBar(title: const Text('Realtime')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          SectionCard(
            title: 'Subscription',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      running ? Icons.podcasts : Icons.podcasts_outlined,
                      color: running ? Colors.green : null,
                    ),
                    const SizedBox(width: 8),
                    Text(running ? 'Listening on $target' : 'Stopped'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: running ? null : _start,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: running ? _stop : null,
                        icon: const Icon(Icons.stop),
                        label: const Text('Stop'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: (running && !_busy) ? _trigger : null,
                  icon: const Icon(Icons.add),
                  label: Text(_isMongo ? 'insertOne test doc' : 'insert test row'),
                ),
                if (_isMongo) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: (running && !_busy && _lastId != null)
                              ? _bumpLast
                              : null,
                          icon: const Icon(Icons.exposure_plus_1),
                          label: const Text('updateOne'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: (running && !_busy && _lastId != null)
                              ? _deleteLast
                              : null,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('deleteOne'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Events (${_events.length})',
            child: _events.isEmpty
                ? Text(
                    'No events yet. Start a subscription, then tap '
                    '"${_isMongo ? 'insertOne test doc' : 'insert test row'}" '
                    'above to generate one without leaving this screen.',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                : Column(
                    children: [for (final e in _events) _eventTile(e)],
                  ),
          ),
          const SizedBox(height: 12),
          InfoCard(
            icon: Icons.bolt_outlined,
            title: 'How realtime fires',
            body: _isMongo
                ? 'Mongo realtime is emitted on writes to the collection — no '
                    'extra setup beyond a collection that you can read.'
                : 'Postgres realtime requires the table to be enabled for '
                    'realtime in the dashboard. Each change arrives as a message '
                    'with m[\'event\'] and m[\'record\'].',
          ),
          const SizedBox(height: 12),
          const InfoCard(
            icon: Icons.cleaning_services_outlined,
            title: 'Always unsubscribe',
            body:
                'The subscription is closed in dispose() so the WebSocket does '
                'not leak when you leave this screen. One socket is shared and '
                'multiplexes all subscriptions.',
          ),
        ],
      ),
    );
  }

  Widget _eventTile(_Event e) {
    final color = switch (e.event) {
      'INSERT' => Colors.green,
      'UPDATE' => Colors.amber,
      'DELETE' => Colors.red,
      _ => Theme.of(context).colorScheme.outline,
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Container(
        width: 10,
        height: 10,
        margin: const EdgeInsets.only(top: 6),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      title: Text('${e.event}  ·  ${e.target}  ·  ${e.at}'),
      subtitle: Text(
        '${e.record}',
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
    );
  }
}

class _Event {
  _Event({
    required this.event,
    required this.target,
    required this.record,
    required this.at,
  });

  final String event;
  final String target;
  final dynamic record;
  final String at;
}

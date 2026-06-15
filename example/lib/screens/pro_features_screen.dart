import 'package:flutter/material.dart';

import '../widgets/pro_badge.dart';
import '../widgets/section_card.dart';

/// Info-only screen describing Pro / Business tier features and how a client
/// app reaches each one (almost always: via an Edge Function).
class ProFeaturesScreen extends StatelessWidget {
  const ProFeaturesScreen({super.key});

  static const _features = <_Pro>[
    _Pro(
      icon: Icons.search,
      title: 'Full-text search (Typesense)',
      body:
          'A managed Typesense cluster powers fast full-text and typo-tolerant '
          'search. The admin key stays server-side: expose search by calling an '
          'Edge Function that runs the query and returns hits. See '
          'edge_functions/search.ts; the client just does '
          "functions.invoke('search', body: {'q': '...'}).",
    ),
    _Pro(
      icon: Icons.memory,
      title: 'Redis cache & queues',
      body:
          'A Redis instance for caching, rate limiting, and background queues. '
          'It is server-side only — read/write it from an Edge Function (the '
          'function holds the connection), then call that function from the '
          'client. Never connect to Redis directly from the app.',
    ),
    _Pro(
      icon: Icons.schedule,
      title: 'Scheduled functions',
      body:
          'Run an Edge Function on a cron/interval, configured in the dashboard '
          'under Functions → Schedules. Pro: up to 10 schedules at ≥5 min; '
          'Business: up to 50 at ≥1 min. Great for digests, cleanups, and syncs '
          '— no client code, the platform triggers it.',
    ),
    _Pro(
      icon: Icons.storage,
      title: 'Both databases on one project',
      body:
          'Run Postgres and MongoDB together on a single project. This needs a '
          'dedicated VPS (Pro), since the two engines run side by side. Pick '
          '"Both" on the setup screen once your project is provisioned for it.',
    ),
    _Pro(
      icon: Icons.dns_outlined,
      title: 'Dedicated VPS & higher quotas',
      body:
          'Pro/Business projects run on a dedicated VPS with higher storage and '
          'row quotas, isolated CPU/RAM, and headroom for realtime and search. '
          'Free projects share capacity with conservative caps.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pro features')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const InfoCard(
            icon: Icons.workspace_premium_outlined,
            title: 'Mostly: call an Edge Function',
            body:
                'Pro capabilities that need secrets (search, Redis) live behind '
                'your own Edge Functions, which hold the admin keys server-side. '
                'The client SDK stays anon-only and just invokes them.',
            trailing: ProBadge(),
          ),
          const SizedBox(height: 12),
          for (final f in _features) ...[
            SectionCard(
              title: f.title,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(f.icon, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: ProBadge(),
                        ),
                        const SizedBox(height: 8),
                        Text(f.body,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _Pro {
  const _Pro({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;
}

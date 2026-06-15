import 'package:flutter/material.dart';

import '../app_config.dart';

/// The first screen: collect the project slug, anon key, and database flavor,
/// then persist them and hand control back to the bootstrapper.
class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key, required this.onConfigured});

  /// Called after a valid config has been saved.
  final VoidCallback onConfigured;

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _slug = TextEditingController();
  final _anonKey = TextEditingController();
  DbFlavor _flavor = DbFlavor.postgres;
  bool _saving = false;

  @override
  void dispose() {
    _slug.dispose();
    _anonKey.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final config = AppConfig(
      slug: _slug.text.trim(),
      anonKey: _anonKey.text.trim(),
      flavor: _flavor,
    );
    await config.save();
    if (!mounted) return;
    setState(() => _saving = false);
    widget.onConfigured();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slug = _slug.text.trim();
    final previewUrl =
        slug.isEmpty ? 'https://<slug>.ichibase.net' : 'https://$slug.ichibase.net';

    return Scaffold(
      appBar: AppBar(title: const Text('Connect a project')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const _Header(),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _slug,
                        decoration: const InputDecoration(
                          labelText: 'Project slug',
                          hintText: 'myapp',
                          prefixText: 'https://',
                          suffixText: '.ichibase.net',
                          border: OutlineInputBorder(),
                        ),
                        autocorrect: false,
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          final s = v?.trim() ?? '';
                          if (s.isEmpty) return 'Required';
                          if (s.contains('.') || s.contains('/')) {
                            return 'Just the slug, e.g. "myapp"';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        previewUrl,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _anonKey,
                        decoration: const InputDecoration(
                          labelText: 'Anon (publishable) key',
                          hintText: 'ich_pub_…',
                          helperText:
                              'Safe to ship. ich_admin_ keys are rejected by the SDK.',
                          helperMaxLines: 2,
                          border: OutlineInputBorder(),
                        ),
                        autocorrect: false,
                        obscureText: false,
                        validator: (v) {
                          final s = v?.trim() ?? '';
                          if (s.isEmpty) return 'Required';
                          if (s.startsWith('ich_admin_')) {
                            return 'Service keys (ich_admin_) bypass RLS — never '
                                'ship them. Use an ich_pub_ key.';
                          }
                          if (!s.startsWith('ich_pub_')) {
                            return 'Anon keys start with "ich_pub_".';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      Text('Database flavor', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      RadioGroup<DbFlavor>(
                        groupValue: _flavor,
                        onChanged: (v) =>
                            setState(() => _flavor = v ?? DbFlavor.postgres),
                        child: const Column(
                          children: [
                            RadioListTile<DbFlavor>(
                              value: DbFlavor.postgres,
                              title: Text('Postgres only'),
                              subtitle: Text('Relational tables + RLS'),
                              contentPadding: EdgeInsets.zero,
                            ),
                            RadioListTile<DbFlavor>(
                              value: DbFlavor.mongo,
                              title: Text('Mongo only'),
                              subtitle: Text('Document collections + policies'),
                              contentPadding: EdgeInsets.zero,
                            ),
                            RadioListTile<DbFlavor>(
                              value: DbFlavor.both,
                              title: Text('Both (Postgres + Mongo)'),
                              subtitle:
                                  Text('Requires a Pro plan (dedicated VPS)'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                      if (_flavor == DbFlavor.both) ...[
                        const SizedBox(height: 4),
                        const _InfoLine(
                          icon: Icons.workspace_premium_outlined,
                          text:
                              'Running both databases on one project needs a Pro '
                              'plan (dedicated VPS). Free projects have one.',
                        ),
                      ],
                      const SizedBox(height: 28),
                      FilledButton.icon(
                        onPressed: _saving ? null : _submit,
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.login),
                        label: const Text('Connect'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFCB2957),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Text(
                'i',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text('ichibase', style: theme.textTheme.headlineSmall),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Point this example at your project. The anon key lives in the '
          'client; all data calls respect your RLS / collection policies.',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: theme.textTheme.bodySmall),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:ichibase/ichibase.dart';

import 'app_config.dart';
import 'ichibase_scope.dart';
import 'prefs_session_store.dart';
import 'screens/config_screen.dart';
import 'screens/home_screen.dart';

/// The ichibase brand color — used as the Material 3 seed.
const kBrand = Color(0xFFCB2957);

void main() {
  runApp(const IchibaseExampleApp());
}

class IchibaseExampleApp extends StatelessWidget {
  const IchibaseExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ichibase example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kBrand,
          brightness: Brightness.dark,
        ),
        // No animations: keep transitions instant to match the dashboard feel.
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: _NoTransitionsBuilder(),
            TargetPlatform.iOS: _NoTransitionsBuilder(),
            TargetPlatform.macOS: _NoTransitionsBuilder(),
            TargetPlatform.windows: _NoTransitionsBuilder(),
            TargetPlatform.linux: _NoTransitionsBuilder(),
          },
        ),
      ),
      home: const _Bootstrap(),
    );
  }
}

/// Decides the first screen: if a project is configured, build the client and
/// show [HomeScreen]; otherwise show [ConfigScreen].
class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  Future<AppConfig?>? _future;

  @override
  void initState() {
    super.initState();
    _future = AppConfig.load();
  }

  void _reload() {
    setState(() => _future = AppConfig.load());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppConfig?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final config = snap.data;
        if (config == null) {
          // Not set up yet — show the config screen. On success it pops back
          // here and we re-run the future to pick up the saved config.
          return ConfigScreen(onConfigured: _reload);
        }
        // Configured — build the client (once) and host the app under it.
        return _ConfiguredApp(config: config, onChangeProject: _reload);
      },
    );
  }
}

/// Owns the [Ichibase] client for the lifetime of a configured session. Builds
/// the client with a persistent [SessionStore], rehydrates any saved session,
/// then installs an [IchibaseScope] over [HomeScreen].
class _ConfiguredApp extends StatefulWidget {
  const _ConfiguredApp({required this.config, required this.onChangeProject});

  final AppConfig config;
  final VoidCallback onChangeProject;

  @override
  State<_ConfiguredApp> createState() => _ConfiguredAppState();
}

class _ConfiguredAppState extends State<_ConfiguredApp> {
  Ichibase? _client;
  Object? _buildError;
  bool _loadingSession = true;

  @override
  void initState() {
    super.initState();
    _build();
  }

  Future<void> _build() async {
    try {
      // The SDK throws if the key is empty or an ich_admin_ (service) key.
      final client = Ichibase.createClient(
        widget.config.url,
        widget.config.anonKey,
        store: PrefsSessionStore(),
      );
      // Rehydrate a persisted session (async store needs an explicit call).
      await client.loadSession();
      if (!mounted) {
        client.dispose();
        return;
      }
      setState(() {
        _client = client;
        _loadingSession = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _buildError = e;
        _loadingSession = false;
      });
    }
  }

  @override
  void dispose() {
    _client?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingSession) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final error = _buildError;
    if (error != null || _client == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Configuration error')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: kBrand),
              const SizedBox(height: 16),
              Text(
                'Could not build the client:\n$error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  await AppConfig.clear();
                  widget.onChangeProject();
                },
                child: const Text('Re-enter project details'),
              ),
            ],
          ),
        ),
      );
    }

    return IchibaseScope(
      client: _client!,
      config: widget.config,
      child: HomeScreen(onChangeProject: widget.onChangeProject),
    );
  }
}

/// A page transition builder that performs no animation.
class _NoTransitionsBuilder extends PageTransitionsBuilder {
  const _NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      child;
}

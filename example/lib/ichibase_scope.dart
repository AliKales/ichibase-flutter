import 'package:flutter/widgets.dart';
import 'package:ichibase/ichibase.dart';

import 'app_config.dart';

/// Makes the configured [Ichibase] client and [AppConfig] available to the
/// whole widget tree.
///
/// Read it from any descendant with `IchibaseScope.of(context)`. The client is
/// built once (with a persistent [SessionStore]) by whoever installs this scope
/// and is disposed when that owner is torn down.
class IchibaseScope extends InheritedWidget {
  const IchibaseScope({
    super.key,
    required this.client,
    required this.config,
    required super.child,
  });

  /// The single, shared SDK client.
  final Ichibase client;

  /// The configuration the [client] was built from.
  final AppConfig config;

  static IchibaseScope of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<IchibaseScope>();
    assert(scope != null, 'No IchibaseScope found in the widget tree.');
    return scope!;
  }

  @override
  bool updateShouldNotify(IchibaseScope oldWidget) =>
      client != oldWidget.client || config != oldWidget.config;
}

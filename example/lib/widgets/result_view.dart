import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ichibase/ichibase.dart';

/// Pretty-prints an [IchibaseResponse]: indented JSON of `.data` on success
/// (green), or the `.error` code / detail / status (red) on failure.
///
/// Pass `null` for [response] to show a neutral placeholder before the first
/// call has been made.
class ResultView extends StatelessWidget {
  const ResultView({super.key, required this.response, this.placeholder});

  final IchibaseResponse<dynamic>? response;
  final String? placeholder;

  static const _encoder = JsonEncoder.withIndent('  ');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final res = response;

    if (res == null) {
      return _shell(
        context,
        color: theme.colorScheme.surfaceContainerHighest,
        child: Text(
          placeholder ?? 'No result yet.',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }

    if (res.ok) {
      return _shell(
        context,
        color: Colors.green.withValues(alpha: 0.10),
        border: Colors.green.withValues(alpha: 0.40),
        child: SelectableText(
          _format(res.data),
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12.5,
            color: Color(0xFF7CD992),
          ),
        ),
      );
    }

    final err = res.error;
    return _shell(
      context,
      color: Colors.red.withValues(alpha: 0.10),
      border: Colors.red.withValues(alpha: 0.40),
      child: SelectableText(
        'error\n'
        'code:   ${err?.code}\n'
        'status: ${err?.status}\n'
        'detail: ${err?.detail ?? '—'}',
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12.5,
          color: Color(0xFFFF8A80),
        ),
      ),
    );
  }

  String _format(dynamic data) {
    if (data == null) return 'data: null (the call succeeded with no body)';
    try {
      return _encoder.convert(data);
    } catch (_) {
      return data.toString();
    }
  }

  Widget _shell(
    BuildContext context, {
    required Color color,
    Color? border,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: border != null ? Border.all(color: border) : null,
      ),
      child: child,
    );
  }
}

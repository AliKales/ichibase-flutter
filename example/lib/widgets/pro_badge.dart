import 'package:flutter/material.dart';

/// A small "PRO" pill rendered in the ichibase brand color. Used to mark
/// features that require a paid plan.
class ProBadge extends StatelessWidget {
  const ProBadge({super.key, this.label = 'PRO'});

  final String label;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFCB2957);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: brand.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: brand),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: brand,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

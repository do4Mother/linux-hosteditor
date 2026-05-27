import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../services/apply_status.dart';

class ApplyStatusIndicator extends ConsumerWidget {
  const ApplyStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(applyStatusProvider);
    return switch (s) {
      Idle() => const SizedBox.shrink(),
      Authenticating() =>
        const _Chip(icon: Icons.lock_outline, label: 'Auth needed'),
      Writing() =>
        const _Chip(icon: Icons.sync, label: 'Saving…', spinning: true),
      ApplyError(message: final m) =>
        _Chip(icon: Icons.error_outline, label: m, isError: true),
    };
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isError;
  final bool spinning;
  const _Chip({
    required this.icon,
    required this.label,
    this.isError = false,
    this.spinning = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError
        ? Colors.redAccent
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Tooltip(
      message: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (spinning)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240),
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

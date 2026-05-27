import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/host.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import 'nav_item.dart';

class Sidebar extends ConsumerWidget {
  final VoidCallback onNewHost;
  const Sidebar({super.key, required this.onNewHost});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hosts = ref.watch(hostsProvider);
    final activeNav = ref.watch(activeNavProvider);
    final envCounts = {for (final e in Env.values) e: hosts.where((h) => h.env == e).length};
    final totalCount = hosts.length;
    final inactiveCount = hosts.where((h) => !h.active).length;
    void onNav(String k) => ref.read(activeNavProvider.notifier).state = k;

    return Container(
      width: 248,
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border(right: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.dns, size: 20, color: AppColors.onPrimaryContainer),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Host Editor',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Material(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(14),
              elevation: 1,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onNewHost,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Row(
                    children: [
                      Icon(Icons.add, size: 20, color: AppColors.onPrimaryContainer),
                      SizedBox(width: 8),
                      Text(
                        'New host',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.onPrimaryContainer, letterSpacing: 0.1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          NavItem(icon: Icons.dns, label: 'All Hosts', count: totalCount, active: activeNav == 'all', onTap: () => onNav('all')),
          NavItem(
            icon: Icons.pause_circle_outline,
            label: 'Inactive',
            count: inactiveCount,
            active: activeNav == 'inactive',
            onTap: () => onNav('inactive'),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Text(
              'ENVIRONMENTS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: AppColors.onSurfaceVariant),
            ),
          ),
          for (final env in Env.values)
            NavItem(envColor: env.accent, label: env.label, count: envCounts[env] ?? 0, active: activeNav == env.name, onTap: () => onNav(env.name)),
          const Spacer(),
        ],
      ),
    );
  }
}

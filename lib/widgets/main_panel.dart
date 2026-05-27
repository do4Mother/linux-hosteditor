import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/host.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import 'bulk_bar.dart';
import 'empty_state.dart';
import 'host_checkbox.dart';
import 'host_filter_chip.dart';
import 'host_row.dart';
import 'host_search_bar.dart';

const _hdr = TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: AppColors.onSurfaceVariant);

class MainPanel extends ConsumerWidget {
  final VoidCallback onNewHost;
  final void Function(Host host, RelativeRect pos) onRowMenu;
  final VoidCallback onBulkDelete;

  const MainPanel({super.key, required this.onNewHost, required this.onRowMenu, required this.onBulkDelete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hosts = ref.watch(hostsProvider);
    final filtered = ref.watch(filteredHostsProvider);
    final selected = ref.watch(selectedProvider);
    final pings = ref.watch(pingsProvider);
    final activeNav = ref.watch(activeNavProvider);
    final filterStatus = ref.watch(filterStatusProvider);
    final search = ref.watch(searchProvider);

    final activeCount = hosts.where((h) => h.active).length;
    final visibleIds = filtered.map((h) => h.id).toSet();
    final allVisibleSelected = visibleIds.isNotEmpty && visibleIds.every(selected.contains);
    final someVisibleSelected = visibleIds.any(selected.contains) && !allVisibleSelected;

    final title = activeNav == 'all'
        ? 'All hosts'
        : activeNav == 'inactive'
        ? 'Inactive'
        : Env.values.firstWhere((e) => e.name == activeNav).label;
    final sub = '${filtered.length} entr${filtered.length == 1 ? 'y' : 'ies'} · $activeCount active proxying';

    void setFilter(String v) => ref.read(filterStatusProvider.notifier).state = v;

    return Container(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
            ),
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 22, height: 28 / 22, fontWeight: FontWeight.w500, color: AppColors.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                  ],
                ),
                const Spacer(),
                const HostSearchBar(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 12),
            child: Row(
              children: [
                HostFilterChip(label: 'All', selected: filterStatus == 'all', onTap: () => setFilter('all')),
                const SizedBox(width: 8),
                HostFilterChip(label: 'Active', icon: Icons.check, selected: filterStatus == 'active', onTap: () => setFilter('active')),
                const SizedBox(width: 8),
                HostFilterChip(label: 'Inactive', icon: Icons.pause, selected: filterStatus == 'inactive', onTap: () => setFilter('inactive')),
                const Spacer(),
              ],
            ),
          ),
          if (selected.isNotEmpty)
            BulkBar(
              count: selected.length,
              onClear: () => ref.read(selectedProvider.notifier).clear(),
              onEnable: () {
                ref.read(hostsProvider.notifier).bulkSetActive(selected, true);
              },
              onDisable: () {
                ref.read(hostsProvider.notifier).bulkSetActive(selected, false);
              },
              onPing: () {
                for (final id in selected) {
                  ref.read(pingsProvider.notifier).start(id);
                }
              },
              onDelete: onBulkDelete,
            ),
          if (filtered.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: Center(
                      child: HostCheckbox(
                        checked: allVisibleSelected,
                        indeterminate: someVisibleSelected,
                        onChanged: (_) => ref.read(selectedProvider.notifier).toggleAll(visibleIds),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(child: Text('HOSTNAME → TARGET', style: _hdr)),
                  const SizedBox(width: 16),
                  const SizedBox(
                    width: 72,
                    child: Text('ENV', textAlign: TextAlign.right, style: _hdr),
                  ),
                  const SizedBox(width: 16),
                  const SizedBox(
                    width: 80,
                    child: Text('PING', textAlign: TextAlign.right, style: _hdr),
                  ),
                  const SizedBox(width: 16),
                  const SizedBox(
                    width: 60,
                    child: Text('STATUS', textAlign: TextAlign.center, style: _hdr),
                  ),
                  const SizedBox(width: 16),
                  const SizedBox(width: 40),
                ],
              ),
            ),
          if (filtered.isNotEmpty) const Divider(height: 1, color: AppColors.outlineVariant),
          Expanded(
            child: filtered.isEmpty
                ? EmptyState(search: search, onNewHost: onNewHost)
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Padding(
                      padding: EdgeInsets.only(left: 88),
                      child: Divider(height: 1, color: AppColors.outlineVariant),
                    ),
                    itemBuilder: (_, i) {
                      final h = filtered[i];
                      return HostRow(
                        host: h,
                        selected: selected.contains(h.id),
                        ping: pings[h.id],
                        onTap: () => ref.read(selectedProvider.notifier).toggle(h.id),
                        onToggleSelect: () => ref.read(selectedProvider.notifier).toggle(h.id),
                        onToggleHost: () => ref.read(hostsProvider.notifier).toggle(h.id),
                        onPing: () => ref.read(pingsProvider.notifier).start(h.id),
                        onMenu: (pos) => onRowMenu(h, pos),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

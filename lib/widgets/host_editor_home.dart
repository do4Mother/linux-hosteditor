import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/host.dart';
import '../providers/providers.dart';
import '../services/apply_status.dart';
import '../theme/app_colors.dart';
import 'apply_status_indicator.dart';
import 'confirm_dialog.dart';
import 'host_dialog.dart';
import 'main_panel.dart';
import 'sidebar.dart';

enum _SnackKind { def, success }

class HostEditorHome extends ConsumerStatefulWidget {
  const HostEditorHome({super.key});

  @override
  ConsumerState<HostEditorHome> createState() => _HostEditorHomeState();
}

class _HostEditorHomeState extends ConsumerState<HostEditorHome> {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  void _snack(String msg, {_SnackKind kind = _SnackKind.def, String? actionLabel, VoidCallback? onAction}) {
    final messenger = _messengerKey.currentState;
    if (messenger == null) return;
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 4200),
        backgroundColor: AppColors.surfaceContainerHighest,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        content: Row(
          children: [
            if (kind != _SnackKind.def) ...[const Icon(Icons.check_circle, size: 20, color: AppColors.success), const SizedBox(width: 16)],
            Expanded(
              child: Text(msg, style: const TextStyle(fontSize: 14, color: AppColors.onSurface)),
            ),
          ],
        ),
        action: actionLabel != null ? SnackBarAction(label: actionLabel, textColor: AppColors.primary, onPressed: onAction ?? () {}) : null,
      ),
    );
  }

  Future<void> _openHostDialog({Host? host}) async {
    final existing = ref.read(hostsProvider);
    final edited = await showDialog<Host>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => HostDialog(host: host, existing: existing),
    );
    if (edited == null) return;
    final notifier = ref.read(hostsProvider.notifier);
    if (host == null) {
      notifier.add(edited);
      _snack('Added ${edited.hostname}', kind: _SnackKind.success);
    } else {
      notifier.update(edited);
      _snack('Updated ${edited.hostname}', kind: _SnackKind.success);
    }
  }

  Future<void> _confirmDelete(Host host) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => ConfirmDialog(
        icon: Icons.delete_forever,
        title: 'Delete host?',
        body: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
            children: [
              const TextSpan(text: 'The redirect '),
              TextSpan(text: host.hostname, style: mono.copyWith(color: AppColors.onSurface)),
              const TextSpan(text: ' → '),
              TextSpan(text: host.target, style: mono.copyWith(color: AppColors.onSurface)),
              const TextSpan(text: " will be removed. You'll have a brief window to undo from the snackbar."),
            ],
          ),
        ),
        confirmLabel: 'Delete',
      ),
    );
    if (ok != true) return;
    final backup = ref.read(hostsProvider.notifier).deleteOne(host.id);
    _snack(
      'Deleted ${host.hostname}',
      kind: _SnackKind.success,
      actionLabel: 'UNDO',
      onAction: () => ref.read(hostsProvider.notifier).restore(backup),
    );
  }

  Future<void> _confirmBulkDelete() async {
    final selected = ref.read(selectedProvider);
    final n = selected.length;
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => ConfirmDialog(
        icon: Icons.delete_forever,
        title: 'Delete $n hosts?',
        body: Text('$n redirects will be permanently removed.', style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
        confirmLabel: 'Delete all',
      ),
    );
    if (ok != true) return;
    final ids = Set<int>.from(selected);
    final backup = ref.read(hostsProvider.notifier).deleteMany(ids);
    ref.read(selectedProvider.notifier).clear();
    _snack(
      '$n host${n == 1 ? '' : 's'} deleted',
      kind: _SnackKind.success,
      actionLabel: 'UNDO',
      onAction: () => ref.read(hostsProvider.notifier).restore(backup),
    );
  }

  Future<void> _showRowMenu(Host host, RelativeRect pos) async {
    final action = await showMenu<String>(
      context: context,
      position: pos,
      color: AppColors.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      items: [
        _menuItem('edit', Icons.edit, 'Edit…'),
        _menuItem('duplicate', Icons.content_copy, 'Duplicate'),
        _menuItem('toggle', host.active ? Icons.toggle_off : Icons.toggle_on, host.active ? 'Disable' : 'Enable'),
        _menuItem('ping', Icons.network_ping, 'Test connection'),
        const PopupMenuDivider(),
        _menuItem('delete', Icons.delete, 'Delete…', danger: true),
      ],
    );
    switch (action) {
      case 'edit':
        await _openHostDialog(host: host);
      case 'duplicate':
        ref.read(hostsProvider.notifier).duplicate(host.id);
        _snack('Host duplicated', kind: _SnackKind.success);
      case 'toggle':
        ref.read(hostsProvider.notifier).toggle(host.id);
      case 'ping':
        ref.read(pingsProvider.notifier).start(host.id);
      case 'delete':
        await _confirmDelete(host);
    }
  }

  PopupMenuItem<String> _menuItem(String v, IconData icon, String label, {bool danger = false}) {
    final color = danger ? AppColors.error : AppColors.onSurface;
    return PopupMenuItem<String>(
      value: v,
      height: 48,
      child: Row(
        children: [
          Icon(icon, size: 20, color: danger ? AppColors.error : AppColors.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 14, color: color)),
        ],
      ),
    );
  }

  Widget _maybeBanner(BuildContext context, WidgetRef ref) {
    final dismissed = ref.watch(firstWriteBannerDismissedProvider);
    if (dismissed) return const SizedBox.shrink();
    return MaterialBanner(
      content: const Text(
        "Editing /etc/hosts needs admin permission. You'll be prompted once.",
      ),
      leading: const Icon(Icons.info_outline),
      actions: [
        TextButton(
          onPressed: () =>
              ref.read(firstWriteBannerDismissedProvider.notifier).state = true,
          child: const Text('Got it'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ApplyStatus>(applyStatusProvider, (prev, next) {
      if (next is ApplyError && prev is! ApplyError) {
        _messengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Could not update /etc/hosts: ${next.message}'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => ref.read(hostsProvider.notifier).retrySync(),
            ),
          ),
        );
      }
    });

    return ScaffoldMessenger(
      key: _messengerKey,
      child: Scaffold(
        backgroundColor: AppColors.windowBg,
        body: Column(
          children: [
            _maybeBanner(context, ref),
            Expanded(
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.windowBorder),
                    boxShadow: const [BoxShadow(color: Color(0x4D000000), blurRadius: 10, offset: Offset(0, 6), spreadRadius: 4)],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Sidebar(onNewHost: () => _openHostDialog()),
                      Expanded(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: const [
                                  ApplyStatusIndicator(),
                                ],
                              ),
                            ),
                            Expanded(
                              child: MainPanel(
                                onNewHost: () => _openHostDialog(),
                                onRowMenu: _showRowMenu,
                                onBulkDelete: _confirmBulkDelete,
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
          ],
        ),
      ),
    );
  }
}

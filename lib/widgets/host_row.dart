import 'package:flutter/material.dart';

import '../models/host.dart';
import '../models/ping.dart';
import '../theme/app_colors.dart';
import 'dot.dart';
import 'env_chip.dart';
import 'host_checkbox.dart';
import 'icon_btn.dart';
import 'm3_switch.dart';
import 'ping_result.dart';

class HostRow extends StatelessWidget {
  final Host host;
  final bool selected;
  final Ping? ping;
  final VoidCallback onTap;
  final VoidCallback onToggleSelect;
  final VoidCallback onToggleHost;
  final VoidCallback onPing;
  final void Function(RelativeRect pos) onMenu;
  const HostRow({
    super.key,
    required this.host,
    required this.selected,
    required this.ping,
    required this.onTap,
    required this.onToggleSelect,
    required this.onToggleHost,
    required this.onPing,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = host.active ? 1.0 : 0.55;
    final bg = selected ? const Color(0x14D0BCFF) : Colors.transparent;
    return Material(
      color: bg,
      child: InkWell(
        onTap: onTap,
        hoverColor: const Color(0x0AE6E0E9),
        child: Container(
          constraints: const BoxConstraints(minHeight: 80),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 48,
                child: Center(
                  child: HostCheckbox(checked: selected, onChanged: (_) => onToggleSelect()),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Opacity(
                  opacity: opacity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            host.hostname,
                            style: mono.copyWith(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.onSurface, letterSpacing: 0.1),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.arrow_forward, size: 16, color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              host.target,
                              style: mono.copyWith(fontSize: 13, color: AppColors.onSurfaceVariant),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (host.note.isNotEmpty)
                            Text(host.note, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant))
                          else
                            const Text(
                              'No description',
                              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.onSurfaceVariant),
                            ),
                          const SizedBox(width: 12),
                          const Dot(color: AppColors.onSurfaceVariant, size: 3),
                          const SizedBox(width: 12),
                          Text('Updated ${host.updated}', style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 72,
                child: Align(alignment: Alignment.centerRight, child: EnvChip(host.env)),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 80,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ping == null ? IconBtn(icon: Icons.network_ping, onTap: onPing, tooltip: 'Test connection') : PingResult(ping: ping!),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 60,
                child: Center(
                  child: M3Switch(on: host.active, onChanged: (_) => onToggleHost()),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 40,
                child: Center(
                  child: Builder(
                    builder: (ctx) => IconBtn(
                      icon: Icons.more_vert,
                      onTap: () {
                        final box = ctx.findRenderObject() as RenderBox;
                        final overlay = Overlay.of(ctx).context.findRenderObject() as RenderBox;
                        final pos = RelativeRect.fromRect(
                          Rect.fromPoints(
                            box.localToGlobal(Offset.zero, ancestor: overlay),
                            box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
                          ),
                          Offset.zero & overlay.size,
                        );
                        onMenu(pos);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'host_checkbox.dart';
import 'icon_btn.dart';

class BulkBar extends StatelessWidget {
  final int count;
  final VoidCallback onClear;
  final VoidCallback onEnable;
  final VoidCallback onDisable;
  final VoidCallback onPing;
  final VoidCallback onDelete;
  const BulkBar({
    super.key,
    required this.count,
    required this.onClear,
    required this.onEnable,
    required this.onDisable,
    required this.onPing,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: AppColors.secondaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          HostCheckbox(checked: true, onChanged: (_) => onClear()),
          const SizedBox(width: 16),
          Text(
            '$count selected',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.onSecondaryContainer),
          ),
          const Spacer(),
          IconBtn(icon: Icons.toggle_on, color: AppColors.onSecondaryContainer, onTap: onEnable, tooltip: 'Enable selected'),
          IconBtn(icon: Icons.toggle_off, color: AppColors.onSecondaryContainer, onTap: onDisable, tooltip: 'Disable selected'),
          IconBtn(icon: Icons.network_ping, color: AppColors.onSecondaryContainer, onTap: onPing, tooltip: 'Ping selected'),
          IconBtn(icon: Icons.delete, color: AppColors.error, onTap: onDelete, tooltip: 'Delete selected'),
          IconBtn(icon: Icons.close, color: AppColors.onSecondaryContainer, onTap: onClear, tooltip: 'Clear selection'),
        ],
      ),
    );
  }
}

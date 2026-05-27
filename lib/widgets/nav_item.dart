import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class NavItem extends StatelessWidget {
  final IconData? icon;
  final Color? envColor;
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;
  const NavItem({super.key, this.icon, this.envColor, required this.label, required this.count, this.active = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = active ? AppColors.secondaryContainer : Colors.transparent;
    final fg = active ? AppColors.onSecondaryContainer : AppColors.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 22, color: fg),
                  const SizedBox(width: 12),
                ] else if (envColor != null) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: envColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: fg, letterSpacing: 0.1),
                  ),
                ),
                Text(
                  '$count',
                  style: TextStyle(fontSize: 12, color: fg, fontFeatures: const [FontFeature.tabularFigures()]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

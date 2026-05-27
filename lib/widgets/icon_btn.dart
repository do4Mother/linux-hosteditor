import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  final String? tooltip;
  const IconBtn({super.key, required this.icon, this.onTap, this.color, this.tooltip});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        onPressed: onTap ?? () {},
        padding: EdgeInsets.zero,
        iconSize: 20,
        tooltip: tooltip,
        icon: Icon(icon, color: color ?? AppColors.onSurfaceVariant),
        splashRadius: 20,
      ),
    );
  }
}

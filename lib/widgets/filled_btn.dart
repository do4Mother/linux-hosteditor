import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class FilledBtn extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  const FilledBtn({super.key, required this.label, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: icon != null ? 16 : 24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 18, color: AppColors.onPrimary), const SizedBox(width: 8)],
              Text(
                label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1, color: AppColors.onPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

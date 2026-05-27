import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class HostCheckbox extends StatelessWidget {
  final bool checked;
  final bool indeterminate;
  final ValueChanged<bool>? onChanged;
  const HostCheckbox({super.key, required this.checked, this.indeterminate = false, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final filled = checked || indeterminate;
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!checked),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: filled ? AppColors.primary : AppColors.onSurfaceVariant, width: 2),
        ),
        child: indeterminate
            ? const Icon(Icons.remove, size: 14, color: AppColors.onPrimary)
            : checked
            ? const Icon(Icons.check, size: 14, color: AppColors.onPrimary)
            : null,
      ),
    );
  }
}

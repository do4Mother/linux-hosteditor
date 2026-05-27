import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class M3Switch extends StatelessWidget {
  final bool on;
  final ValueChanged<bool> onChanged;
  const M3Switch({super.key, required this.on, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const trackW = 52.0, trackH = 32.0;
    final thumbSize = on ? 24.0 : 16.0;
    return GestureDetector(
      onTap: () => onChanged(!on),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: trackW,
        height: trackH,
        decoration: BoxDecoration(
          color: on ? AppColors.primary : AppColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: on ? AppColors.primary : AppColors.outline, width: 2),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              left: on ? trackW - thumbSize - 6 - 2 : 6 - 2,
              top: (trackH - thumbSize) / 2 - 2,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: thumbSize,
                height: thumbSize,
                decoration: BoxDecoration(color: on ? AppColors.onPrimary : AppColors.outline, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: on ? const Icon(Icons.check, size: 16, color: AppColors.primary) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

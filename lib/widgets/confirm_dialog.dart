import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ConfirmDialog extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget body;
  final String confirmLabel;
  const ConfirmDialog({super.key, required this.icon, required this.title, required this.body, required this.confirmLabel});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(icon, size: 28, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, color: AppColors.onSurface),
              ),
              const SizedBox(height: 16),
              DefaultTextStyle(
                style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
                child: body,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => Navigator.of(context).pop(true),
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        alignment: Alignment.center,
                        child: Text(
                          confirmLabel,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.onErrorContainer),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

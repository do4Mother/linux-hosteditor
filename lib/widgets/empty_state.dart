import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'filled_btn.dart';

class EmptyState extends StatelessWidget {
  final String search;
  final VoidCallback onNewHost;
  const EmptyState({super.key, required this.search, required this.onNewHost});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.travel_explore, size: 56, color: AppColors.outline),
            const SizedBox(height: 16),
            Text(
              search.isNotEmpty ? 'No hosts match your search' : 'No hosts in this group yet',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.onSurface),
            ),
            const SizedBox(height: 6),
            Text(
              search.isNotEmpty ? 'Try a different query or clear filters.' : 'Add a host to start redirecting traffic.',
              style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
            ),
            if (search.isEmpty) ...[const SizedBox(height: 20), FilledBtn(label: 'Add host', icon: Icons.add, onTap: onNewHost)],
          ],
        ),
      ),
    );
  }
}

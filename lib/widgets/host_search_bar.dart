import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../theme/app_colors.dart';

class HostSearchBar extends ConsumerStatefulWidget {
  const HostSearchBar({super.key});

  @override
  ConsumerState<HostSearchBar> createState() => _HostSearchBarState();
}

class _HostSearchBarState extends ConsumerState<HostSearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(searchProvider);
    return Container(
      width: 320,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(999)),
      child: Row(
        children: [
          const Icon(Icons.search, size: 20, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: (v) => ref.read(searchProvider.notifier).state = v,
              style: const TextStyle(fontSize: 14, color: AppColors.onSurface),
              cursorColor: AppColors.primary,
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Search hostnames, targets…',
                hintStyle: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
              ),
            ),
          ),
          if (value.isNotEmpty)
            SizedBox(
              width: 28,
              height: 28,
              child: IconButton(
                padding: EdgeInsets.zero,
                iconSize: 16,
                splashRadius: 14,
                onPressed: () {
                  _controller.clear();
                  ref.read(searchProvider.notifier).state = '';
                },
                icon: const Icon(Icons.close, color: AppColors.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}

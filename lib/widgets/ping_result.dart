import 'package:flutter/material.dart';

import '../models/ping.dart';
import '../theme/app_colors.dart';

class PingResult extends StatelessWidget {
  final Ping ping;
  const PingResult({super.key, required this.ping});

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (ping.status) {
      'pending' => ('…ping', AppColors.onSurfaceVariant),
      'ok' => ('${ping.ms}ms', AppColors.success),
      _ => ('timeout', AppColors.error),
    };
    return Text(text, style: mono.copyWith(fontSize: 11, color: color));
  }
}

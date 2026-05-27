import 'package:flutter/material.dart';

import '../models/host.dart';
import 'dot.dart';

class EnvChip extends StatelessWidget {
  final Env env;
  const EnvChip(this.env, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: env.container, borderRadius: BorderRadius.circular(8)),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Dot(color: env.accent, size: 6),
          const SizedBox(width: 6),
          Text(
            env.short,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: env.accent),
          ),
        ],
      ),
    );
  }
}

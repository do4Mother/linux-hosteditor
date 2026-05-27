import 'package:flutter/material.dart';

class Dot extends StatelessWidget {
  final Color color;
  final double size;
  const Dot({super.key, required this.color, required this.size});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

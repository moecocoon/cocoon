import 'package:flutter/material.dart';

class LunaWidget extends StatelessWidget {
  final double size;
  final bool isWalking;
  final VoidCallback? onTap;

  const LunaWidget({
    super.key,
    this.size = 120,
    this.isWalking = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 250),
        scale: isWalking ? 0.95 : 1.0,
        child: AnimatedRotation(
          duration: const Duration(milliseconds: 350),
          turns: isWalking ? -0.02 : 0,
          child: Image.asset(
            'assets/images/luna.png',
            width: size,
            height: size,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
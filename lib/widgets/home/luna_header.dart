import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class LunaHeader extends StatelessWidget {
  final int lunaBond;
  final String bondLevel;

  const LunaHeader({
    super.key,
    required this.lunaBond,
    required this.bondLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'COCOON',
          style: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: AppColors.card.withOpacity(0.9),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Text(
            '🐶 ルナとの絆 $lunaBond\n🌙 $bondLevel',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
          ),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/app_buttons.dart';
import '../widgets/sapu_logo.dart';

/// Top part shared by all registration steps (back button, logo, title, step badge).
class RegisterHeader extends StatelessWidget {
  final int step;
  final String stepTitle;
  const RegisterHeader({
    super.key,
    required this.step,
    required this.stepTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [BackCircleButton(), SapuLogo(height: 34)],
        ),
        const SizedBox(height: 24),
        const Text(
          'SMALL ACT. DELICIOUS IMPACT.',
          style: TextStyle(
            fontSize: 10.5,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w800,
            color: AppColors.green,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Create Your Account',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Every organisation is verified before going live.',
          style: TextStyle(fontSize: 12.5, color: AppColors.textGrey),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                '$step',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              stepTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.dark,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

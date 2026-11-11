import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Logo drawn in code so the app runs without any asset setup.
/// To use your real logo image instead, put it in assets/images/logo.png,
/// declare it in pubspec.yaml and replace the build() body with:
///   return Image.asset('assets/images/logo.png', height: height);
class SapuLogo extends StatelessWidget {
  final double height;
  const SapuLogo({super.key, this.height = 34});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(height * 0.28),
          child: Image.asset(
            'assets/images/logo.jpg',
            width: height,
            height: height,
            fit: BoxFit.cover,
          ),
        ),
        SizedBox(width: height * 0.22),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: height * 0.62,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            children: const [
              TextSpan(
                text: 'Sapu',
                style: TextStyle(color: AppColors.dark),
              ),
              TextSpan(
                text: 'Habis!',
                style: TextStyle(color: AppColors.green),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

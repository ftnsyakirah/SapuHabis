import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/app_buttons.dart';
import '../widgets/sapu_logo.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.eco_outlined,
                        size: 14,
                        color: AppColors.green,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Less waste.',
                        style: TextStyle(fontSize: 11, color: AppColors.green),
                      ),
                    ],
                  ),
                  SapuLogo(height: 34),
                ],
              ),
              const SizedBox(height: 18),
              const _HeroImage(),
              const SizedBox(height: 24),
              const Text(
                'Good food.',
                style: TextStyle(
                  fontSize: 34,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dark,
                ),
              ),
              const Text(
                'Better prices.',
                style: TextStyle(
                  fontSize: 34,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Rescue delicious surplus food from nearby spots.\nSave money with every bite.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 22),
              PrimaryButton(
                label: 'Get started',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
              ),
              const SizedBox(height: 10),
              OutlineWideButton(
                label: 'I already have an account',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
              ),
              const SizedBox(height: 14),
              const Center(
                child: Text(
                  'A little saving. A big difference.',
                  style: TextStyle(fontSize: 11, color: AppColors.textGrey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 270,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Put your food photo at assets/images/food.jpg (and declare it in
            // pubspec.yaml). Until then, the gradient placeholder shows.
            Image.asset(
              'assets/images/food.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE9DCC0), Color(0xFFB9D7B0)],
                  ),
                ),
                child: const Icon(
                  Icons.lunch_dining_rounded,
                  size: 90,
                  color: Colors.white70,
                ),
              ),
            ),
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lime,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Up to 70% off',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 14,
                      color: AppColors.dark,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Too good to go to waste.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

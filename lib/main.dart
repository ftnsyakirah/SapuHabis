import 'package:flutter/material.dart';

import 'auth/welcome_screen.dart';
import 'theme/app_colors.dart';

void main() {
  runApp(const SapuHabisApp());
}

class SapuHabisApp extends StatelessWidget {
  const SapuHabisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SapuHabis!',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.cream,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.green),
      ),
      home: const WelcomeScreen(),
    );
  }
}

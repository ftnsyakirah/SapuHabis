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
      // Stops very large / very small system font sizes from breaking layouts.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.25,
            ),
          ),
          child: child!,
        );
      },
      home: const WelcomeScreen(),
    );
  }
}

import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/app_buttons.dart';

/// "or continue with Google" + "Already have an account? Log in"
class AuthFooter extends StatelessWidget {
  const AuthFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const OrDivider(),
        const SizedBox(height: 16),
        GoogleButton(onPressed: () {}),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('Already have an account? ',
                style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
            GestureDetector(
              onTap: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => route.isFirst,
              ),
              child: const Text('Log in',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.green)),
            ),
          ],
        ),
      ],
    );
  }
}
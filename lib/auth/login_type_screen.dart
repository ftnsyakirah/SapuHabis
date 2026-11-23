import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/account_type_picker.dart';
import '../widgets/app_buttons.dart';
import '../widgets/auth_page.dart';
import '../widgets/sapu_logo.dart';
import 'account_type.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// Welcome -> THIS SCREEN -> Login.
/// The user picks FoodBusiness or Food Charity Organization, then continues to login.
class LoginTypeScreen extends StatefulWidget {
  const LoginTypeScreen({super.key});

  @override
  State<LoginTypeScreen> createState() => _LoginTypeScreenState();
}

class _LoginTypeScreenState extends State<LoginTypeScreen> {
  AccountType? _selected;

  void _continue() {
    if (_selected == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Please choose how you want to log in')),
        );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(accountType: _selected!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [BackCircleButton(), SapuLogo(height: 34)],
          ),
          const SizedBox(height: 28),
          const Text('GOOD TO SEE YOU AGAIN',
              style: TextStyle(
                  fontSize: 10.5,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                  color: AppColors.green)),
          const SizedBox(height: 10),
          const Text('Welcome back.',
              style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dark)),
          const SizedBox(height: 10),
          const Text(
            'Choose how you use SapuHabis!\nso we can log you in.',
            style:
                TextStyle(fontSize: 14, height: 1.4, color: AppColors.textGrey),
          ),
          const SizedBox(height: 28),
          const Text("I'm logging in as",
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark)),
          const SizedBox(height: 10),
          AccountTypePicker(
            value: _selected,
            onChanged: (type) => setState(() => _selected = type),
          ),
          const SizedBox(height: 22),
          PrimaryButton(label: 'Continue', onPressed: _continue),
          const SizedBox(height: 20),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('New to SapuHabis!? ',
                    style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
                GestureDetector(
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  child: const Text('Create an account',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.green)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.softGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.eco_outlined,
                    size: 20, color: AppColors.green),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Every rescue counts.',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.dark)),
                    Text('Good for your wallet. Better for the planet.',
                        style: TextStyle(
                            fontSize: 10.5, color: AppColors.textGrey)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
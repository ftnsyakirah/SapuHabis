import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/app_buttons.dart';
import '../widgets/auth_footer.dart';
import '../widgets/auth_page.dart';
import '../widgets/register_header.dart';
import 'account_type.dart';
import 'organisation_screen.dart';

/// Step 1: choose account type. Continue goes to step 2 (organisation details).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  AccountType? _selected;

  void _continue() {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose an account type')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrganisationScreen(accountType: _selected!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const RegisterHeader(step: 1, stepTitle: 'Account type'),
          const SizedBox(height: 18),
          const Text(
            "I'm registering as",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 10),
          _TypeCard(
            icon: Icons.storefront_outlined,
            title: 'FoodBusiness',
            description: 'Supermarket, bakery or manufacture with surplus food to sell or donate.',
            selected: _selected == AccountType.foodBusiness,
            onTap: () => setState(() => _selected = AccountType.foodBusiness),
          ),
          const SizedBox(height: 14),
          _TypeCard(
            icon: Icons.volunteer_activism_outlined,
            title: 'Food Charity Organization',
            description: 'Registered organisation that purchases, collects and distributes food to charity place in need',
            selected: _selected == AccountType.charity,
            onTap: () => setState(() => _selected = AccountType.charity),
          ),
          const SizedBox(height: 22),
          PrimaryButton(label: 'Continue', onPressed: _continue),
          const SizedBox(height: 16),
          const AuthFooter(),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.green : AppColors.border,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 26, color: AppColors.dark),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.check_circle,
                  size: 20,
                  color: AppColors.green,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

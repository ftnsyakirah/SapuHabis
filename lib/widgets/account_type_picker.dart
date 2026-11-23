import 'package:flutter/material.dart';

import '../auth/account_type.dart';
import '../theme/app_colors.dart';

/// The two selectable cards: FoodBusiness / Food Charity Organization.
/// Used on the register screen and on the "choose how to log in" screen.
class AccountTypePicker extends StatelessWidget {
  final AccountType? value;
  final ValueChanged<AccountType> onChanged;

  const AccountTypePicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TypeCard(
          icon: AccountType.foodBusiness.icon,
          title: AccountType.foodBusiness.label,
          description: 'Supermarket, bakery or manufacture with surplus food to sell or donate.',
          selected: value == AccountType.foodBusiness,
          onTap: () => onChanged(AccountType.foodBusiness),
        ),
        const SizedBox(height: 14),
        _TypeCard(
          icon: AccountType.charity.icon,
          title: AccountType.charity.label,
          description: 'Registered organisation that purchases, collects and distributes food to charity place in need',
          selected: value == AccountType.charity,
          onTap: () => onChanged(AccountType.charity),
        ),
      ],
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
        width: double.infinity,
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

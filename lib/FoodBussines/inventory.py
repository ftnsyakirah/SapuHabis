import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/common.dart';
import 'sell_screen.dart';
import 'donate_screen.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      subtitle: 'Inventory',
      body: Column(
        children: [
          const SizedBox(height: 36),
          ActionCard(
            imagePath: 'assets/images/sell.jpg',
            fallbackIcon: Icons.shopping_cart_outlined,
            text: 'Put discount on\ninventory items.',
            buttonLabel: 'Sell',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SellScreen())),
          ),
          const SizedBox(height: 40),
          ActionCard(
            imagePath: 'assets/images/donate.jpg',
            fallbackIcon: Icons.volunteer_activism_outlined,
            text: 'Donate invetory\nitems to charity\norganization.',
            buttonLabel: 'Donate',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const DonateScreen())),
          ),
        ],
      ),
    );
  }
}

class ActionCard extends StatelessWidget {
  final String imagePath;
  final IconData fallbackIcon;
  final String text;
  final String buttonLabel;
  final VoidCallback onPressed;

  const ActionCard({
    super.key,
    required this.imagePath,
    required this.fallbackIcon,
    required this.text,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ListCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: SizedBox(
          height: 100,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(20),
                ),
                child: SizedBox(
                  width: 148,
                  height: 100,
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: kGreenLight,
                      child: Icon(fallbackIcon, size: 40, color: kGreen),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Text(text,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              height: 1.35)),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: GreenPillButton(
                          label: buttonLabel, onPressed: onPressed),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
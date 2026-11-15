import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class BackNextRow extends StatelessWidget {
  final String nextLabel;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  const BackNextRow({
    super.key,
    required this.nextLabel,
    required this.onNext,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: onBack ?? () => Navigator.maybePop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.green,
                side: const BorderSide(color: AppColors.green),
                shape: shape,
              ),
              child: const Text(
                'Back',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: shape,
              ),
              // FittedBox shrinks long labels instead of overflowing on small phones.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  nextLabel,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Label on top, text field, and a small hint text underneath.
/// If validation fails, the hint is replaced by the red error message.
class LabeledField extends StatelessWidget {
  final String label;
  final String helper;
  final String? placeholder;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final bool obscure;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  const LabeledField({
    super.key,
    required this.label,
    required this.helper,
    required this.controller,
    this.placeholder,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.textCapitalization = TextCapitalization.none,
    this.obscure = false,
    this.suffix,
    this.validator,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            textCapitalization: textCapitalization,
            inputFormatters: inputFormatters,
            validator: validator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            style: const TextStyle(fontSize: 14, color: AppColors.dark),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: const TextStyle(color: AppColors.hint, fontSize: 14),
              helperText: helper,
              helperMaxLines: 3,
              helperStyle: const TextStyle(
                fontSize: 11.5,
                height: 1.3,
                color: AppColors.textGrey,
              ),
              errorMaxLines: 3,
              errorStyle: const TextStyle(fontSize: 11.5, height: 1.3),
              suffixIcon: suffix,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              enabledBorder: border(AppColors.border),
              focusedBorder: border(AppColors.green),
              errorBorder: border(Colors.red.shade400),
              focusedErrorBorder: border(Colors.red.shade400),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small grey title with a line under it ("Organisation", "Contact and login"...).
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: const TextStyle(fontSize: 13.5, color: AppColors.textGrey),
        ),
        const SizedBox(height: 6),
        const Divider(height: 1, thickness: 1, color: Color(0xFF8A8A78)),
      ],
    );
  }
}

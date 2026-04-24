// lib/widgets/app_text_field.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final bool obscure;
  final int maxLines;
  final String? Function(String?)? validator;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint = '',
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.obscure = false,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
          color: AppColors.slate600)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        maxLines: obscure ? 1 : maxLines,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.slate400),
          prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 20, color: AppColors.slate400) : null,
          suffixIcon: suffixIcon,
        ),
      ),
    ],
  );
}

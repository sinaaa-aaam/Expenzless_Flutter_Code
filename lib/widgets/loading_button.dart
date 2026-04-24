// lib/widgets/loading_button.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LoadingButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const LoadingButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => ElevatedButton(
    onPressed: loading ? null : onPressed,
    child: loading
      ? const SizedBox(width: 22, height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.white))
      : Text(label),
  );
}

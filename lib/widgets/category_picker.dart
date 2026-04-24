// lib/widgets/category_picker.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CategoryPicker extends StatelessWidget {
  final String selected;
  final void Function(String) onChanged;

  const CategoryPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 100,
    child: GridView.count(
      crossAxisCount: 4,
      childAspectRatio: 1,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: AppConstants.categories.map((cat) {
        final isSelected = cat == selected;
        final color = AppConstants.categoryColors[cat]  ?? AppColors.slate400;
        final icon  = AppConstants.categoryIcons[cat]   ?? Icons.category;
        return GestureDetector(
          onTap: () => onChanged(cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.15) : AppColors.slate100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : AppColors.slate200,
                width: isSelected ? 2 : 1),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 20, color: isSelected ? color : AppColors.slate400),
              const SizedBox(height: 4),
              Text(cat.split(' ').first,
                style: TextStyle(
                  fontSize: 9,
                  color: isSelected ? color : AppColors.slate400,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal),
                overflow: TextOverflow.ellipsis),
            ]),
          ),
        );
      }).toList(),
    ),
  );
}

// lib/widgets/expense_tile.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../theme/app_theme.dart';

class ExpenseTile extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ExpenseTile({
    super.key,
    required this.expense,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final icon    = AppConstants.categoryIcons[expense.category]  ?? Icons.receipt;
    final color   = AppConstants.categoryColors[expense.category] ?? AppColors.slate400;
    final dateStr = DateFormat('dd MMM').format(expense.date);
    final timeStr = DateFormat('h:mm a').format(expense.date);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(expense.description,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
            color: AppColors.slate800),
          maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Row(children: [
          Text(expense.category,
            style: const TextStyle(fontSize: 11, color: AppColors.slate400)),
          const SizedBox(width: 6),
          Container(width: 3, height: 3,
            decoration: const BoxDecoration(
              color: AppColors.slate400, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('$dateStr · $timeStr',
            style: const TextStyle(fontSize: 11, color: AppColors.slate400)),
          if (expense.locationLat != null && expense.locationLat != 0) ...[
            const SizedBox(width: 6),
            const Icon(Icons.location_on, size: 11, color: AppColors.slate400),
          ],
          if (!expense.isSynced) ...[
            const SizedBox(width: 6),
            const Icon(Icons.cloud_off, size: 11, color: AppColors.warning),
          ],
        ]),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('GH₵ ${expense.amount.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14,
              color: AppColors.slate800)),
          if (onEdit != null || onDelete != null)
            PopupMenuButton(
              icon: const Icon(Icons.more_vert, size: 18, color: AppColors.slate400),
              itemBuilder: (_) => [
                if (onEdit   != null) const PopupMenuItem(value: 'edit',   child: Text('Edit')),
                if (onDelete != null) const PopupMenuItem(value: 'delete',
                  child: Text('Delete', style: TextStyle(color: AppColors.error))),
              ],
              onSelected: (v) {
                if (v == 'edit'   && onEdit   != null) onEdit!();
                if (v == 'delete' && onDelete != null) onDelete!();
              },
            ),
        ]),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

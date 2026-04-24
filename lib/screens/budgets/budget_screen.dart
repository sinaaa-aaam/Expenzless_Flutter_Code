// lib/screens/budgets/budget_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/expense_model.dart';
import '../../providers/budget_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/loading_button.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate100,
      appBar: AppBar(
        title: const Text('Budgets'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.add),
            onPressed: () => _showBudgetDialog(context)),
        ],
      ),
      body: StreamBuilder<List<BudgetModel>>(
        stream: context.read<BudgetProvider>().budgetsStream,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final budgets = snap.data ?? [];
          if (budgets.isEmpty) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.pie_chart_outline, size: 56,
                color: AppColors.slate400),
              const SizedBox(height: 12),
              const Text('No budgets set',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                  color: AppColors.slate600)),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => _showBudgetDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Set a Budget'),
              ),
            ]));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: budgets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _BudgetCard(budget: budgets[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.teal,
        onPressed: () => _showBudgetDialog(context),
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }

  void _showBudgetDialog(BuildContext context, {BudgetModel? existing}) {
    final amtCtrl = TextEditingController(
      text: existing?.monthlyLimit.toStringAsFixed(2) ?? '');
    String category = existing?.category ?? AppConstants.categories.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24,
          MediaQuery.of(context).viewInsets.bottom + 24),
        child: StatefulBuilder(builder: (ctx, setLocal) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(existing != null ? 'Edit Budget' : 'Set Budget',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            const Text('Category',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: AppColors.slate600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: category,
              decoration: InputDecoration(
                filled: true, fillColor: AppColors.slate100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.slate200)),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14)),
              items: AppConstants.categories.map((c) =>
                DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: existing != null
                ? null : (v) => setLocal(() => category = v!),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: amtCtrl, label: 'Monthly Limit (GH₵)', hint: '0.00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: Icons.attach_money,
              validator: (v) => (v == null || double.tryParse(v) == null ||
                double.parse(v) <= 0) ? 'Enter a valid amount' : null,
            ),
            const SizedBox(height: 24),
            LoadingButton(
              label: existing != null ? 'Update' : 'Save Budget',
              loading: false,
              onPressed: () async {
                final amt = double.tryParse(amtCtrl.text);
                if (amt == null || amt <= 0) return;
                final provider = context.read<BudgetProvider>();
                if (existing != null) {
                  await provider.updateLimit(existing.id, amt);
                } else {
                  await provider.createBudget(
                    category: category, monthlyLimit: amt);
                }
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        )),
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final BudgetModel budget;
  const _BudgetCard({required this.budget});

  @override
  Widget build(BuildContext context) {
    final pct      = budget.utilizationPct.clamp(0.0, 100.0);
    final color    = pct >= 100 ? AppColors.error
                   : pct >= 80  ? AppColors.warning : AppColors.teal;
    final icon     = AppConstants.categoryIcons[budget.category] ?? Icons.category;
    final catColor = AppConstants.categoryColors[budget.category] ?? AppColors.slate400;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 40, height: 40,
              decoration: BoxDecoration(
                color: catColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: catColor, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(budget.category,
                  style: const TextStyle(fontWeight: FontWeight.w700,
                    fontSize: 14, color: AppColors.slate800)),
                Text('GH₵ ${budget.currentSpend.toStringAsFixed(2)} of '
                  'GH₵ ${budget.monthlyLimit.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.slate400)),
              ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
              child: Text('${pct.toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                  color: color))),
            PopupMenuButton(
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'delete',
                  child: Text('Delete',
                    style: TextStyle(color: AppColors.error))),
              ],
              onSelected: (v) {
                if (v == 'delete') {
                  context.read<BudgetProvider>().deleteBudget(budget.id);
                }
              },
            ),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: AppColors.slate200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(
              pct >= 100 ? '⚠️ Over budget!'
              : 'GH₵ ${budget.remaining.toStringAsFixed(2)} remaining',
              style: TextStyle(fontSize: 12, color: color,
                fontWeight: FontWeight.w500)),
            Text('Month ${budget.month}/${budget.year}',
              style: const TextStyle(fontSize: 11, color: AppColors.slate400)),
          ]),
        ]),
      ),
    );
  }
}

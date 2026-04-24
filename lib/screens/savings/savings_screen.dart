// lib/screens/savings/savings_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/expense_model.dart';
import '../../providers/savings_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/loading_button.dart';

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate100,
      appBar: AppBar(
        title: const Text('Savings Goals'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.add),
            onPressed: () => _showGoalDialog(context)),
        ],
      ),
      body: StreamBuilder<List<SavingsGoalModel>>(
        stream: context.read<SavingsProvider>().goalsStream,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final goals = snap.data ?? [];
          if (goals.isEmpty) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.savings_outlined, size: 56,
                color: AppColors.slate400),
              const SizedBox(height: 12),
              const Text('No savings goals yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                  color: AppColors.slate600)),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => _showGoalDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Create Goal'),
              ),
            ]));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: goals.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _GoalCard(goal: goals[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.teal,
        onPressed: () => _showGoalDialog(context),
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }

  void _showGoalDialog(BuildContext context, {SavingsGoalModel? existing}) {
    final titleCtrl  = TextEditingController(text: existing?.title ?? '');
    final targetCtrl = TextEditingController(
      text: existing?.targetAmount.toStringAsFixed(2) ?? '');
    DateTime deadline =
      existing?.deadline ?? DateTime.now().add(const Duration(days: 90));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(builder: (ctx, setLocal) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24,
          MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(existing != null ? 'Edit Goal' : 'New Savings Goal',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),

            AppTextField(controller: titleCtrl, label: 'Goal Name',
              hint: 'e.g. New Freezer', prefixIcon: Icons.flag_outlined,
              validator: (v) =>
                (v == null || v.isEmpty) ? 'Required' : null),
            const SizedBox(height: 16),

            AppTextField(controller: targetCtrl, label: 'Target Amount (GH₵)',
              hint: '0.00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: Icons.attach_money,
              validator: (v) => (v == null || double.tryParse(v) == null ||
                double.parse(v) <= 0) ? 'Enter a valid amount' : null),
            const SizedBox(height: 16),

            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: deadline,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                  builder: (c, child) => Theme(
                    data: ThemeData.light().copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppColors.teal)),
                    child: child!),
                );
                if (picked != null) setLocal(() => deadline = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.slate200)),
                child: Row(children: [
                  const Icon(Icons.calendar_today, size: 18,
                    color: AppColors.slate400),
                  const SizedBox(width: 12),
                  Text('Deadline: ${DateFormat('dd MMM yyyy').format(deadline)}',
                    style: const TextStyle(fontSize: 15,
                      color: AppColors.slate800)),
                  const Spacer(),
                  const Icon(Icons.arrow_drop_down,
                    color: AppColors.slate400),
                ]),
              ),
            ),
            const SizedBox(height: 24),

            LoadingButton(
              label: existing != null ? 'Update Goal' : 'Create Goal',
              loading: false,
              onPressed: () async {
                final title  = titleCtrl.text.trim();
                final target = double.tryParse(targetCtrl.text);
                if (title.isEmpty || target == null || target <= 0) return;
                final provider = context.read<SavingsProvider>();
                if (existing != null) {
                  await provider.updateGoal(existing.id,
                    title: title, targetAmount: target, deadline: deadline);
                } else {
                  await provider.createGoal(
                    title: title, targetAmount: target, deadline: deadline);
                }
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      )),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final SavingsGoalModel goal;
  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final daysLeft = goal.deadline.difference(DateTime.now()).inDays;
    final overdue  = daysLeft < 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 40, height: 40,
              decoration: BoxDecoration(
                color: goal.isCompleted
                  ? AppColors.success.withOpacity(0.15) : AppColors.tealBg,
                borderRadius: BorderRadius.circular(10)),
              child: Icon(
                goal.isCompleted ? Icons.check_circle : Icons.savings,
                color: goal.isCompleted ? AppColors.success : AppColors.teal,
                size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(goal.title,
                  style: const TextStyle(fontWeight: FontWeight.w700,
                    fontSize: 15, color: AppColors.slate800)),
                Text(
                  goal.isCompleted ? '🎉 Goal reached!'
                  : overdue ? '⚠️ Overdue by ${-daysLeft}d'
                  : '$daysLeft days remaining',
                  style: TextStyle(fontSize: 12,
                    color: goal.isCompleted ? AppColors.success
                    : overdue ? AppColors.error : AppColors.slate400)),
              ])),
            PopupMenuButton(
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'contribute',
                  child: Text('Add funds')),
                const PopupMenuItem(value: 'delete',
                  child: Text('Delete',
                    style: TextStyle(color: AppColors.error))),
              ],
              onSelected: (v) {
                if (v == 'delete') {
                  context.read<SavingsProvider>().deleteGoal(goal.id);
                } else if (v == 'contribute') {
                  _showContributeDialog(context);
                }
              },
            ),
          ]),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: goal.progressPct,
              backgroundColor: AppColors.slate200,
              valueColor: AlwaysStoppedAnimation<Color>(
                goal.isCompleted ? AppColors.success : AppColors.teal),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('GH₵ ${goal.currentAmount.toStringAsFixed(2)} saved',
              style: const TextStyle(fontSize: 12, color: AppColors.slate600,
                fontWeight: FontWeight.w500)),
            Text('Target: GH₵ ${goal.targetAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12, color: AppColors.slate400)),
          ]),
          if (!goal.isCompleted) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _showContributeDialog(context),
              icon: const Icon(Icons.add, size: 16, color: AppColors.teal),
              label: const Text('Add Funds',
                style: TextStyle(color: AppColors.teal, fontSize: 13)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.teal),
                minimumSize: const Size.fromHeight(36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
            ),
          ],
        ]),
      ),
    );
  }

  void _showContributeDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add funds to "${goal.title}"'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount (GH₵)',
            prefixIcon: Icon(Icons.attach_money)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(ctrl.text);
              if (amt != null && amt > 0) {
                context.read<SavingsProvider>().contribute(goal.id, amt);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

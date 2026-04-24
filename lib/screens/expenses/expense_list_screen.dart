// lib/screens/expenses/expense_list_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/expense_model.dart';
import '../../providers/expense_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/expense_tile.dart';
import 'add_expense_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});
  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  String    _search   = '';
  String?   _category;
  DateTime? _from, _to;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ExpenseProvider>();

    return Scaffold(
      backgroundColor: AppColors.slate100,
      appBar: AppBar(
        title: const Text('Expenses'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.filter_list),
            onPressed: _showFilter),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search expenses…',
              prefixIcon: const Icon(Icons.search, color: AppColors.slate400),
              suffixIcon: _search.isNotEmpty
                ? IconButton(icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => setState(() => _search = ''))
                : null,
              filled: true, fillColor: AppColors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            ),
            onChanged: (v) => setState(() => _search = v.toLowerCase()),
          ),
        ),

        if (_category != null || _from != null)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(children: [
              if (_category != null)
                _filterChip(_category!,
                  () => setState(() => _category = null)),
              if (_from != null)
                _filterChip(
                  '${DateFormat('dd MMM').format(_from!)} – '
                  '${_to != null ? DateFormat('dd MMM').format(_to!) : 'now'}',
                  () => setState(() { _from = null; _to = null; })),
            ]),
          ),

        Expanded(
          child: StreamBuilder<List<ExpenseModel>>(
            stream: provider.filteredStream(
              category: _category, from: _from, to: _to),
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              var expenses = snap.data ?? [];
              if (_search.isNotEmpty) {
                expenses = expenses.where((e) =>
                  e.description.toLowerCase().contains(_search) ||
                  e.category.toLowerCase().contains(_search)).toList();
              }
              if (expenses.isEmpty) {
                return Center(child: Column(
                  mainAxisSize: MainAxisSize.min, children: const [
                    Icon(Icons.receipt_long, size: 48,
                      color: AppColors.slate400),
                    SizedBox(height: 12),
                    Text('No expenses found',
                      style: TextStyle(color: AppColors.slate600,
                        fontSize: 15)),
                  ]));
              }

              final grouped = <String, List<ExpenseModel>>{};
              for (final e in expenses) {
                final key = DateFormat('MMMM yyyy').format(e.date);
                grouped.putIfAbsent(key, () => []).add(e);
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                children: grouped.entries.expand((entry) => [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(children: [
                      Text(entry.key,
                        style: const TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate600)),
                      const SizedBox(width: 8),
                      Expanded(child: Divider(color: AppColors.slate200)),
                      const SizedBox(width: 8),
                      Text('GH₵ ${entry.value.fold(0.0, (s, e) => s + e.amount).toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 12,
                          color: AppColors.slate400)),
                    ]),
                  ),
                  ...entry.value.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ExpenseTile(
                      expense: e,
                      onEdit: () => Navigator.push(context,
                        MaterialPageRoute(
                          builder: (_) => AddExpenseScreen(existing: e))),
                      onDelete: () => _confirmDelete(context, e),
                    ),
                  )),
                ]).toList(),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _filterChip(String label, VoidCallback onRemove) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      deleteIcon: const Icon(Icons.close, size: 14),
      onDeleted: onRemove,
      backgroundColor: AppColors.tealBg,
      side: BorderSide.none,
    ),
  );

  void _showFilter() {
    String? tempCat = _category;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(builder: (ctx, setLocal) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Filter Expenses',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          const Align(alignment: Alignment.centerLeft,
            child: Text('Category',
              style: TextStyle(fontWeight: FontWeight.w600))),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8,
            children: AppConstants.categories.map((c) => ChoiceChip(
              label: Text(c),
              selected: tempCat == c,
              onSelected: (v) => setLocal(() => tempCat = v ? c : null),
              selectedColor: AppColors.tealBg,
              side: BorderSide.none,
            )).toList()),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () {
                setState(() { _category = null; _from = null; _to = null; });
                Navigator.pop(ctx);
              },
              child: const Text('Clear'),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: () {
                setState(() => _category = tempCat);
                Navigator.pop(ctx);
              },
              child: const Text('Apply'),
            )),
          ]),
          const SizedBox(height: 8),
        ]),
      )),
    );
  }

  void _confirmDelete(BuildContext context, ExpenseModel e) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Delete Expense'),
      content: Text('Remove "${e.description}" of '
        'GH₵${e.amount.toStringAsFixed(2)}?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
          child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () {
            Navigator.pop(context);
            context.read<ExpenseProvider>().removeExpense(e);
          },
          child: const Text('Delete'),
        ),
      ],
    ));
  }
}

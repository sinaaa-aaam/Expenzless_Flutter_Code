// lib/screens/dashboard/dashboard_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/expense_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../services/offline_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/expense_tile.dart';
import '../expenses/add_expense_screen.dart';
import '../expenses/expense_list_screen.dart';
import '../budgets/budget_screen.dart';
import '../savings/savings_screen.dart';
import '../reports/insights_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentTab = 0;

  final _tabs = const [
    _HomeTab(),
    ExpenseListScreen(),
    BudgetScreen(),
    SavingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentTab],
      floatingActionButton: _currentTab == 0
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.teal,
              icon: const Icon(Icons.add, color: AppColors.white),
              label: const Text('Add Expense',
                style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)),
              onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AddExpenseScreen())),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (i) => setState(() => _currentTab = i),
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.tealBg,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.teal), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: AppColors.teal), label: 'Expenses'),
          NavigationDestination(icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart, color: AppColors.teal), label: 'Budgets'),
          NavigationDestination(icon: Icon(Icons.savings_outlined),
            selectedIcon: Icon(Icons.savings, color: AppColors.teal), label: 'Goals'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ExpenseProvider>();
    final auth     = context.read<AuthProvider>();
    final name     = auth.user?.displayName?.split(' ').first ?? 'there';
    final fmt      = NumberFormat('#,##0.00');
    final queueCnt = OfflineService.queueCount();

    return Scaffold(
      backgroundColor: AppColors.slate100,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.teal,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.teal,
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hello, $name 👋',
                            style: const TextStyle(fontSize: 14,
                              color: AppColors.white, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          const Text('This Month',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                              color: AppColors.white)),
                        ],
                      )),
                      GestureDetector(
                        onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const InsightsScreen())),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20)),
                          child: const Row(children: [
                            Icon(Icons.auto_awesome, color: AppColors.white, size: 16),
                            SizedBox(width: 4),
                            Text('AI Insights',
                              style: TextStyle(color: AppColors.white, fontSize: 13)),
                          ]),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    FutureBuilder<double>(
                      future: provider.getTotalThisMonth(),
                      builder: (_, snap) => Text(
                        'GH₵ ${fmt.format(snap.data ?? 0)}',
                        style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800,
                          color: AppColors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              if (queueCnt > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Chip(
                    backgroundColor: AppColors.warning,
                    label: Text('$queueCnt offline',
                      style: const TextStyle(fontSize: 11, color: AppColors.white)),
                    avatar: const Icon(Icons.cloud_off, size: 14, color: AppColors.white),
                  ),
                ),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert, color: AppColors.white),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'logout', child: Text('Log Out')),
                ],
                onSelected: (v) async {
                  if (v == 'logout') {
                    await context.read<AuthProvider>().signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacementNamed('/login');
                    }
                  }
                },
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _ChartCard(provider: provider),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recent Expenses',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                        color: AppColors.slate800)),
                    TextButton(
                      onPressed: () {},
                      child: const Text('See all',
                        style: TextStyle(color: AppColors.teal)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                StreamBuilder<List<ExpenseModel>>(
                  stream: provider.expensesStream,
                  builder: (_, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final expenses = (snap.data ?? []).take(5).toList();
                    if (expenses.isEmpty) return _EmptyState();
                    return Column(
                      children: expenses.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ExpenseTile(expense: e,
                          onDelete: () =>
                            context.read<ExpenseProvider>().removeExpense(e)),
                      )).toList(),
                    );
                  },
                ),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatefulWidget {
  final ExpenseProvider provider;
  const _ChartCard({required this.provider});
  @override State<_ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<_ChartCard> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Spending by Category',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
              color: AppColors.slate800)),
          const SizedBox(height: 16),
          FutureBuilder<Map<String, double>>(
            future: widget.provider.getSpendByCategory(),
            builder: (_, snap) {
              if (!snap.hasData || snap.data!.isEmpty) {
                return const SizedBox(height: 160,
                  child: Center(child: Text('No data yet',
                    style: TextStyle(color: AppColors.slate400))));
              }
              final data   = snap.data!;
              final total  = data.values.fold(0.0, (s, v) => s + v);
              final colors = AppConstants.categoryColors;
              final sections = data.entries.toList().asMap().entries.map((entry) {
                final i  = entry.key;
                final kv = entry.value;
                final pct       = (kv.value / total) * 100;
                final isTouched = i == _touched;
                return PieChartSectionData(
                  value: kv.value,
                  title: isTouched ? '${pct.toStringAsFixed(0)}%' : '',
                  color: colors[kv.key] ?? AppColors.slate400,
                  radius: isTouched ? 70 : 60,
                  titleStyle: const TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w700, color: AppColors.white),
                );
              }).toList();

              return Row(children: [
                SizedBox(
                  height: 160, width: 160,
                  child: PieChart(PieChartData(
                    sections: sections,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, resp) {
                        if (resp?.touchedSection != null) {
                          setState(() =>
                            _touched = resp!.touchedSection!.touchedSectionIndex);
                        } else {
                          setState(() => _touched = -1);
                        }
                      }),
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                  )),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: data.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(children: [
                        Container(width: 10, height: 10,
                          decoration: BoxDecoration(
                            color: colors[e.key] ?? AppColors.slate400,
                            shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(e.key,
                          style: const TextStyle(fontSize: 11,
                            color: AppColors.slate600),
                          overflow: TextOverflow.ellipsis)),
                        Text('GH₵${e.value.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 11,
                            fontWeight: FontWeight.w600, color: AppColors.slate800)),
                      ]),
                    )).toList(),
                  ),
                ),
              ]);
            },
          ),
        ]),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(32),
    child: Column(children: const [
      Icon(Icons.receipt_long, size: 48, color: AppColors.slate400),
      SizedBox(height: 12),
      Text('No expenses yet',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
          color: AppColors.slate600)),
      SizedBox(height: 4),
      Text('Tap + to log your first expense',
        style: TextStyle(fontSize: 13, color: AppColors.slate400)),
    ]),
  );
}

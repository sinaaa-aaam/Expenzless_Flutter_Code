// lib/screens/reports/insights_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/expense_provider.dart';
import '../../services/gemini_service.dart';
import '../../theme/app_theme.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});
  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  String?  _insights;
  bool     _loading  = false;
  String?  _error;
  Map<String, double> _byCategory = {};

  @override
  void initState() { super.initState(); _generate(); }

  Future<void> _generate() async {
    setState(() { _loading = true; _error = null; });
    try {
      final provider  = context.read<ExpenseProvider>();
      final expenses  = await provider.getExpensesForReport();
      _byCategory     = await provider.getSpendByCategory();

      if (expenses.isEmpty) {
        setState(() {
          _insights = 'No expense data found for this period. '
            'Start logging expenses to get personalised insights.';
          _loading = false;
        });
        return;
      }
      final text = await GeminiService.generateInsights(expenses);
      setState(() { _insights = text; _loading = false; });
    } catch (e) {
      setState(() {
        _error = 'Failed to generate insights. Check your connection.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate100,
      appBar: AppBar(
        title: const Row(children: [
          Icon(Icons.auto_awesome, color: AppColors.teal, size: 20),
          SizedBox(width: 8),
          Text('AI Insights'),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _generate),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D9488), Color(0xFF0891B2)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: const [
              Row(children: [
                Icon(Icons.auto_awesome, color: AppColors.white, size: 20),
                SizedBox(width: 8),
                Text('Powered by Gemini AI',
                  style: TextStyle(color: AppColors.white,
                    fontWeight: FontWeight.w700, fontSize: 15)),
              ]),
              SizedBox(height: 6),
              Text('Personalised financial insights from your last 30 days.',
                style: TextStyle(color: AppColors.white, fontSize: 13,
                  height: 1.4)),
            ]),
          ),
          const SizedBox(height: 16),

          if (_byCategory.isNotEmpty) ...[
            const Text('This Month\'s Spending',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                color: AppColors.slate800)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8,
              children: _byCategory.entries.map((e) {
                final color = AppConstants.categoryColors[e.key]
                  ?? AppColors.slate400;
                return Chip(
                  avatar: Icon(
                    AppConstants.categoryIcons[e.key] ?? Icons.category,
                    size: 14, color: color),
                  label: Text('${e.key}  GH₵${e.value.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 12)),
                  backgroundColor: color.withOpacity(0.1),
                  side: BorderSide.none,
                );
              }).toList()),
            const SizedBox(height: 16),
          ],

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _loading
                ? Column(children: const [
                    SizedBox(height: 16),
                    CircularProgressIndicator(color: AppColors.teal),
                    SizedBox(height: 16),
                    Text('Analysing your expenses…',
                      style: TextStyle(color: AppColors.slate400)),
                    SizedBox(height: 16),
                  ])
                : _error != null
                  ? Column(children: [
                      const Icon(Icons.wifi_off, size: 40,
                        color: AppColors.slate400),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.slate600)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _generate,
                        child: const Text('Retry')),
                    ])
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: const [
                        Icon(Icons.lightbulb_outline, color: AppColors.teal,
                          size: 20),
                        SizedBox(width: 8),
                        Text('Your Financial Summary',
                          style: TextStyle(fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.slate800)),
                      ]),
                      const SizedBox(height: 14),
                      const Divider(color: AppColors.slate200),
                      const SizedBox(height: 12),
                      Text(_insights ?? '',
                        style: const TextStyle(fontSize: 14,
                          color: AppColors.slate700, height: 1.65)),
                    ]),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: const [
            Icon(Icons.info_outline, size: 14, color: AppColors.slate400),
            SizedBox(width: 6),
            Expanded(child: Text(
              'AI-generated insights are for guidance only. '
              'Always verify financial decisions.',
              style: TextStyle(fontSize: 11, color: AppColors.slate400,
                height: 1.4))),
          ]),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

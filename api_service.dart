// lib/services/api_service.dart
//
// Replaces firebase_service.dart.
// All CRUD operations now go through the Node.js/Express + MySQL backend
// via HTTP requests. Firebase Auth still handles login/signup — the JWT
// token it issues is sent in the Authorization header on every request.

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/expense_model.dart';
import 'notification_service.dart';
import 'offline_service.dart';
import 'connectivity_service.dart';

class ApiService {
  // ── Change this to your server IP when testing on a real device ──────────
  // Emulator: use 10.0.2.2 (maps to your PC's localhost)
  // Real phone on same WiFi: use your PC's local IP e.g. 192.168.1.5
  static const String _baseUrl = 'http://10.0.2.2:3000/api';

  final _auth = FirebaseAuth.instance;

  // Gets the current user's Firebase JWT token
  Future<String> get _token async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    return await user.getIdToken() ?? '';
  }

  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  Future<Map<String, String>> get _authHeaders async => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${await _token}',
  };

  // ── Sync user profile after login/signup ─────────────────────────────────
  Future<void> syncUser(String displayName) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/users/sync'),
      headers: await _authHeaders,
      body: jsonEncode({
        'display_name': displayName,
        'currency': 'GHS',
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Failed to sync user: ${res.body}');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // EXPENSES — CREATE
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> createExpense({
    required double   amount,
    required String   category,
    required String   description,
    required DateTime date,
    String?  receiptImageUrl,
    double?  lat,
    double?  lng,
  }) async {
    final body = {
      'amount':            amount,
      'category':          category,
      'description':       description,
      'expense_date':      date.toIso8601String().substring(0, 10),
      'receipt_image_url': receiptImageUrl ?? '',
      'location_lat':      lat,
      'location_lng':      lng,
    };

    final online = await ConnectivityService.isOnline();
    if (online) {
      final res = await http.post(
        Uri.parse('$_baseUrl/expenses'),
        headers: await _authHeaders,
        body: jsonEncode(body),
      );
      if (res.statusCode != 201) {
        throw Exception('Failed to create expense: ${res.body}');
      }
      // Check budget alerts after creating expense
      await _checkBudgetAlerts(category);
    } else {
      // Queue locally for offline sync
      await OfflineService.queueExpense({
        ...body,
        'userId': _auth.currentUser!.uid,
        'isSynced': false,
      });
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // EXPENSES — READ
  // ══════════════════════════════════════════════════════════════════════════
  Future<List<ExpenseModel>> fetchExpenses({
    String?   category,
    DateTime? from,
    DateTime? to,
    int       limitDays = 30,
  }) async {
    final params = <String, String>{};
    if (category != null) params['category'] = category;
    if (from     != null) params['from'] = from.toIso8601String().substring(0, 10);
    if (to       != null) params['to']   = to.toIso8601String().substring(0, 10);
    if (from == null && to == null) {
      final since = DateTime.now().subtract(Duration(days: limitDays));
      params['from'] = since.toIso8601String().substring(0, 10);
    }

    final uri = Uri.parse('$_baseUrl/expenses').replace(queryParameters: params);
    final res = await http.get(uri, headers: await _authHeaders);

    if (res.statusCode != 200) {
      throw Exception('Failed to fetch expenses: ${res.body}');
    }
    final List data = jsonDecode(res.body);
    return data.map((e) => ExpenseModel.fromApiMap(e)).toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // EXPENSES — UPDATE
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> updateExpense(ExpenseModel old, ExpenseModel updated) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/expenses/${old.id}'),
      headers: await _authHeaders,
      body: jsonEncode({
        'amount':       updated.amount,
        'category':     updated.category,
        'description':  updated.description,
        'expense_date': updated.date.toIso8601String().substring(0, 10),
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to update expense: ${res.body}');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // EXPENSES — DELETE
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> deleteExpense(String expenseId) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/expenses/$expenseId'),
      headers: await _authHeaders,
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to delete expense: ${res.body}');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUDGETS — CREATE
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> createBudget({
    required String category,
    required double monthlyLimit,
    int? month,
    int? year,
  }) async {
    final now = DateTime.now();
    final res = await http.post(
      Uri.parse('$_baseUrl/budgets'),
      headers: await _authHeaders,
      body: jsonEncode({
        'category':      category,
        'monthly_limit': monthlyLimit,
        'month':         month ?? now.month,
        'year':          year  ?? now.year,
      }),
    );
    if (res.statusCode != 201) {
      throw Exception('Failed to create budget: ${res.body}');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUDGETS — READ
  // ══════════════════════════════════════════════════════════════════════════
  Future<List<BudgetModel>> fetchBudgets({int? month, int? year}) async {
    final now = DateTime.now();
    final uri = Uri.parse('$_baseUrl/budgets').replace(queryParameters: {
      'month': '${month ?? now.month}',
      'year':  '${year  ?? now.year}',
    });
    final res = await http.get(uri, headers: await _authHeaders);
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch budgets: ${res.body}');
    }
    final List data = jsonDecode(res.body);
    return data.map((b) => BudgetModel.fromApiMap(b)).toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUDGETS — UPDATE
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> updateBudgetLimit(String budgetId, double newLimit) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/budgets/$budgetId'),
      headers: await _authHeaders,
      body: jsonEncode({'monthly_limit': newLimit}),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to update budget: ${res.body}');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUDGETS — DELETE
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> deleteBudget(String budgetId) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/budgets/$budgetId'),
      headers: await _authHeaders,
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to delete budget: ${res.body}');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SAVINGS GOALS — CREATE
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> createGoal({
    required String   title,
    required double   targetAmount,
    required DateTime deadline,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/savings'),
      headers: await _authHeaders,
      body: jsonEncode({
        'title':         title,
        'target_amount': targetAmount,
        'deadline':      deadline.toIso8601String().substring(0, 10),
      }),
    );
    if (res.statusCode != 201) {
      throw Exception('Failed to create goal: ${res.body}');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SAVINGS GOALS — READ
  // ══════════════════════════════════════════════════════════════════════════
  Future<List<SavingsGoalModel>> fetchGoals() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/savings'),
      headers: await _authHeaders,
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch goals: ${res.body}');
    }
    final List data = jsonDecode(res.body);
    return data.map((g) => SavingsGoalModel.fromApiMap(g)).toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SAVINGS GOALS — UPDATE
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> updateGoal(String goalId, {
    String? title, double? targetAmount, DateTime? deadline}) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/savings/$goalId'),
      headers: await _authHeaders,
      body: jsonEncode({
        if (title        != null) 'title':         title,
        if (targetAmount != null) 'target_amount': targetAmount,
        if (deadline     != null) 'deadline': deadline.toIso8601String().substring(0, 10),
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to update goal: ${res.body}');
    }
  }

  Future<void> contributeToGoal(String goalId, double amount) async {
    final res = await http.patch(
      Uri.parse('$_baseUrl/savings/$goalId/contribute'),
      headers: await _authHeaders,
      body: jsonEncode({'amount': amount}),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to contribute: ${res.body}');
    }
    final data = jsonDecode(res.body);
    if (data['completed'] == true) {
      await NotificationService.showGoalComplete(title: data['title']);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SAVINGS GOALS — DELETE
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> deleteGoal(String goalId) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/savings/$goalId'),
      headers: await _authHeaders,
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to delete goal: ${res.body}');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // AGGREGATES
  // ══════════════════════════════════════════════════════════════════════════
  Future<Map<String, double>> getMonthlySpendByCategory() async {
    final expenses = await fetchExpenses(limitDays: 30);
    final Map<String, double> result = {};
    for (final e in expenses) {
      result[e.category] = (result[e.category] ?? 0) + e.amount;
    }
    return result;
  }

  Future<double> getTotalSpendThisMonth() async {
    final expenses = await fetchExpenses(limitDays: 30);
    return expenses.fold(0.0, (sum, e) => sum + e.amount);
  }

  // ── Budget alert check after expense create ───────────────────────────────
  Future<void> _checkBudgetAlerts(String category) async {
    try {
      final budgets = await fetchBudgets();
      final budget  = budgets.where((b) => b.category == category).firstOrNull;
      if (budget == null) return;

      final pct = budget.utilizationPct;
      if (pct >= 100 && !budget.alertSent100) {
        await NotificationService.showBudgetAlert(
          title: '🚨 Budget Exceeded!',
          body:  '${budget.category} budget of GH₵${budget.monthlyLimit.toStringAsFixed(2)} is fully used.',
        );
      } else if (pct >= 80 && !budget.alertSent80) {
        await NotificationService.showBudgetAlert(
          title: '⚠️ Budget Warning',
          body:  '80% of ${budget.category} budget used.',
        );
      }
    } catch (_) {}
  }
}

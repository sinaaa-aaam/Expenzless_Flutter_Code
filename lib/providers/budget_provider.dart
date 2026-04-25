// lib/providers/budget_provider.dart
import 'package:flutter/foundation.dart';
import '../models/expense_model.dart';
import '../services/api_service.dart';

class BudgetProvider extends ChangeNotifier {
  final _service = ApiService();

  Stream<List<BudgetModel>> get budgetsStream => _service.readBudgets();

  Future<void> createBudget({
    required String category, required double monthlyLimit}) async {
    await _service.createBudget(category: category, monthlyLimit: monthlyLimit);
    notifyListeners();
  }

  Future<void> updateLimit(String budgetId, double newLimit) async {
    await _service.updateBudgetLimit(budgetId, newLimit);
    notifyListeners();
  }

  Future<void> deleteBudget(String budgetId) async {
    await _service.deleteBudget(budgetId);
    notifyListeners();
  }
}

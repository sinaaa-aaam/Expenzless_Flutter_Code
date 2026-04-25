// lib/providers/savings_provider.dart
import 'package:flutter/foundation.dart';
import '../models/expense_model.dart';
import '../services/api_service.dart';

class SavingsProvider extends ChangeNotifier {
  final _service = ApiService();
  bool _loading  = false;
  bool get loading => _loading;

  Stream<List<SavingsGoalModel>> get goalsStream => _service.readGoals();

  Future<void> createGoal({
    required String title, required double targetAmount,
    required DateTime deadline}) async {
    _loading = true; notifyListeners();
    await _service.createGoal(
      title: title, targetAmount: targetAmount, deadline: deadline);
    _loading = false; notifyListeners();
  }

  Future<void> contribute(String goalId, double amount) async {
    await _service.contributeToGoal(goalId, amount);
    notifyListeners();
  }

  Future<void> updateGoal(String goalId, {
    String? title, double? targetAmount, DateTime? deadline}) async {
    await _service.updateGoal(goalId,
      title: title, targetAmount: targetAmount, deadline: deadline);
    notifyListeners();
  }

  Future<void> deleteGoal(String goalId) async {
    await _service.deleteGoal(goalId);
    notifyListeners();
  }
}

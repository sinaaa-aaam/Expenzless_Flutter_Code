// lib/providers/expense_provider.dart
import 'package:flutter/foundation.dart';
import '../models/expense_model.dart';
import '../services/firebase_service.dart';
import '../services/camera_service.dart';
import '../services/location_service.dart';

enum LoadState { idle, loading, success, error }

class ExpenseProvider extends ChangeNotifier {
  final _service = ApiService();
  LoadState _state = LoadState.idle;
  String?   _error;

  LoadState get state => _state;
  String?   get error => _error;

  Stream<List<ExpenseModel>> get expensesStream => _service.readExpenses();

  Stream<List<ExpenseModel>> filteredStream({
    String? category, DateTime? from, DateTime? to}) =>
      _service.readExpenses(category: category, from: from, to: to);

  Future<bool> addExpense({
    required double amount, required String category,
    required String description, required DateTime date,
    String? receiptImageUrl, bool attachLocation = false,
  }) async {
    _setState(LoadState.loading);
    try {
      double? lat, lng;
      if (attachLocation) {
        final loc = await LocationService.getCurrentLocation();
        lat = loc?.lat; lng = loc?.lng;
      }
      await _service.createExpense(
        amount: amount, category: category,
        description: description, date: date,
        receiptImageUrl: receiptImageUrl, lat: lat, lng: lng,
      );
      _setState(LoadState.success);
      return true;
    } catch (e) {
      _setError('Failed to save expense: $e');
      return false;
    }
  }

  Future<ReceiptScanResult?> scanAndPrepare() async {
    _setState(LoadState.loading);
    try {
      final result = await CameraService.scanReceiptFromCamera();
      _setState(LoadState.idle);
      return result;
    } catch (e) {
      _setError('Camera error: $e');
      return null;
    }
  }

  Future<bool> editExpense(ExpenseModel old, ExpenseModel updated) async {
    _setState(LoadState.loading);
    try {
      await _service.updateExpense(old, updated);
      _setState(LoadState.success);
      return true;
    } catch (e) {
      _setError('Failed to update expense: $e');
      return false;
    }
  }

  Future<bool> removeExpense(ExpenseModel expense) async {
    _setState(LoadState.loading);
    try {
      await _service.deleteExpense(expense);
      _setState(LoadState.success);
      return true;
    } catch (e) {
      _setError('Failed to delete expense: $e');
      return false;
    }
  }

  Future<Map<String, double>> getSpendByCategory() =>
      _service.getMonthlySpendByCategory();

  Future<double> getTotalThisMonth() => _service.getTotalSpendThisMonth();

  Future<List<ExpenseModel>> getExpensesForReport() =>
      _service.fetchExpenses(limitDays: 30);

  Future<String> exportToCsv(List<ExpenseModel> expenses) async {
    final header = 'Date,Category,Description,Amount,Receipt,Lat,Lng\n';
    final rows = expenses.map((e) =>
      '${e.date.toIso8601String().substring(0, 10)},'
      '${e.category},'
      '"${e.description.replaceAll('"', '""')}",'
      '${e.amount.toStringAsFixed(2)},'
      '${e.receiptImageUrl},'
      '${e.locationLat ?? ""},'
      '${e.locationLng ?? ""}'
    ).join('\n');
    return header + rows;
  }

  void _setState(LoadState s) { _state = s; _error = null; notifyListeners(); }
  void _setError(String msg)  { _state = LoadState.error; _error = msg; notifyListeners(); }
  void clearError()           { _error = null; notifyListeners(); }
}

// lib/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/expense_model.dart';
import 'notification_service.dart';
import 'offline_service.dart';
import 'connectivity_service.dart';

class FirebaseService {
  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _uuid = const Uuid();

  String get _uid => _auth.currentUser!.uid;

  // ── EXPENSES CREATE ───────────────────────────────────────────────────────
  Future<void> createExpense({
    required double amount, required String category,
    required String description, required DateTime date,
    String? receiptImageUrl, double? lat, double? lng,
  }) async {
    final id  = _uuid.v4();
    final now = DateTime.now();
    final expense = ExpenseModel(
      id: id, userId: _uid, amount: amount, category: category,
      description: description, date: date,
      receiptImageUrl: receiptImageUrl ?? '',
      locationLat: lat, locationLng: lng,
      isSynced: true, createdAt: now, updatedAt: now,
    );
    final online = await ConnectivityService.isOnline();
    if (online) {
      await _db.collection('expenses').doc(id).set(expense.toMap());
      await _adjustBudgetSpend(category, amount);
    } else {
      await OfflineService.queueExpense(expense.toMap());
    }
  }

  // ── EXPENSES READ ─────────────────────────────────────────────────────────
  Stream<List<ExpenseModel>> readExpenses({
    String? category, DateTime? from, DateTime? to,
  }) {
    Query<Map<String, dynamic>> q = _db
        .collection('expenses')
        .where('userId', isEqualTo: _uid)
        .orderBy('date', descending: true);
    if (category != null) q = q.where('category', isEqualTo: category);
    if (from != null) q = q.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    if (to   != null) q = q.where('date', isLessThanOrEqualTo:    Timestamp.fromDate(to));
    return q.snapshots().map(
      (snap) => snap.docs.map((d) => ExpenseModel.fromMap(d.data())).toList());
  }

  Future<List<ExpenseModel>> fetchExpenses({int limitDays = 30}) async {
    final since = DateTime.now().subtract(Duration(days: limitDays));
    final snap = await _db
        .collection('expenses')
        .where('userId', isEqualTo: _uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .orderBy('date', descending: true)
        .get();
    return snap.docs.map((d) => ExpenseModel.fromMap(d.data())).toList();
  }

  // ── EXPENSES UPDATE ───────────────────────────────────────────────────────
  Future<void> updateExpense(ExpenseModel old, ExpenseModel updated) async {
    await _adjustBudgetSpend(old.category, -old.amount);
    await _adjustBudgetSpend(updated.category, updated.amount);
    await _db.collection('expenses').doc(old.id).update({
      'amount': updated.amount, 'category': updated.category,
      'description': updated.description,
      'date': Timestamp.fromDate(updated.date),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── EXPENSES DELETE ───────────────────────────────────────────────────────
  Future<void> deleteExpense(ExpenseModel expense) async {
    await _adjustBudgetSpend(expense.category, -expense.amount);
    await _db.collection('expenses').doc(expense.id).delete();
  }

  // ── BUDGETS CREATE ────────────────────────────────────────────────────────
  Future<void> createBudget({
    required String category, required double monthlyLimit,
    int? month, int? year,
  }) async {
    final id  = _uuid.v4();
    final now = DateTime.now();
    final budget = BudgetModel(
      id: id, userId: _uid, category: category,
      monthlyLimit: monthlyLimit,
      month: month ?? now.month, year: year ?? now.year,
    );
    await _db.collection('budgets').doc(id).set(budget.toMap());
  }

  // ── BUDGETS READ ──────────────────────────────────────────────────────────
  Stream<List<BudgetModel>> readBudgets({int? month, int? year}) {
    final now = DateTime.now();
    return _db.collection('budgets')
        .where('userId', isEqualTo: _uid)
        .where('month', isEqualTo: month ?? now.month)
        .where('year',  isEqualTo: year  ?? now.year)
        .snapshots()
        .map((s) => s.docs.map((d) => BudgetModel.fromMap(d.data())).toList());
  }

  // ── BUDGETS UPDATE ────────────────────────────────────────────────────────
  Future<void> updateBudgetLimit(String budgetId, double newLimit) async {
    await _db.collection('budgets').doc(budgetId).update({
      'monthlyLimit': newLimit, 'alertSent80': false, 'alertSent100': false,
    });
  }

  // ── BUDGETS DELETE ────────────────────────────────────────────────────────
  Future<void> deleteBudget(String budgetId) async {
    await _db.collection('budgets').doc(budgetId).delete();
  }

  Future<void> _adjustBudgetSpend(String category, double delta) async {
    final now  = DateTime.now();
    final snap = await _db.collection('budgets')
        .where('userId',   isEqualTo: _uid)
        .where('category', isEqualTo: category)
        .where('month',    isEqualTo: now.month)
        .where('year',     isEqualTo: now.year)
        .get();
    if (snap.docs.isEmpty) return;
    final ref = snap.docs.first.reference;
    await ref.update({'currentSpend': FieldValue.increment(delta)});
    final updated = BudgetModel.fromMap((await ref.get()).data()!);
    await _triggerBudgetAlert(ref, updated);
  }

  Future<void> _triggerBudgetAlert(DocumentReference ref, BudgetModel b) async {
    final pct = b.utilizationPct;
    if (pct >= 100 && !b.alertSent100) {
      await NotificationService.showBudgetAlert(
        title: '🚨 Budget Exceeded!',
        body: '${b.category} budget of GH₵${b.monthlyLimit.toStringAsFixed(2)} is fully used.',
      );
      await ref.update({'alertSent100': true});
    } else if (pct >= 80 && !b.alertSent80) {
      await NotificationService.showBudgetAlert(
        title: '⚠️ Budget Warning',
        body: '80% of ${b.category} budget used. GH₵${b.remaining.toStringAsFixed(2)} remaining.',
      );
      await ref.update({'alertSent80': true});
    }
  }

  // ── SAVINGS GOALS CREATE ──────────────────────────────────────────────────
  Future<void> createGoal({
    required String title, required double targetAmount,
    required DateTime deadline,
  }) async {
    final id = _uuid.v4();
    final goal = SavingsGoalModel(
      id: id, userId: _uid, title: title,
      targetAmount: targetAmount, deadline: deadline,
      createdAt: DateTime.now(),
    );
    await _db.collection('savingsGoals').doc(id).set(goal.toMap());
  }

  // ── SAVINGS GOALS READ ────────────────────────────────────────────────────
  Stream<List<SavingsGoalModel>> readGoals() => _db
      .collection('savingsGoals')
      .where('userId', isEqualTo: _uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => SavingsGoalModel.fromMap(d.data())).toList());

  // ── SAVINGS GOALS UPDATE ──────────────────────────────────────────────────
  Future<void> contributeToGoal(String goalId, double amount) async {
    final ref = _db.collection('savingsGoals').doc(goalId);
    await ref.update({'currentAmount': FieldValue.increment(amount)});
    final data = SavingsGoalModel.fromMap((await ref.get()).data()!);
    if (data.currentAmount >= data.targetAmount) {
      await ref.update({'isCompleted': true});
      await NotificationService.showGoalComplete(title: data.title);
    }
  }

  Future<void> updateGoal(String goalId,
      {String? title, double? targetAmount, DateTime? deadline}) async {
    final updates = <String, dynamic>{};
    if (title        != null) updates['title']        = title;
    if (targetAmount != null) updates['targetAmount'] = targetAmount;
    if (deadline     != null) updates['deadline']     = Timestamp.fromDate(deadline);
    if (updates.isNotEmpty) {
      await _db.collection('savingsGoals').doc(goalId).update(updates);
    }
  }

  // ── SAVINGS GOALS DELETE ──────────────────────────────────────────────────
  Future<void> deleteGoal(String goalId) async {
    await _db.collection('savingsGoals').doc(goalId).delete();
  }

  // ── AGGREGATES ────────────────────────────────────────────────────────────
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
    double total = 0.0;
    for (final e in expenses) { total += e.amount; }
    return total;
  }
}

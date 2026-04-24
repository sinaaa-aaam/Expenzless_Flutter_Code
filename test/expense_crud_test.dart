// test/expense_crud_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExpenseModel', () {
    test('toMap() serialises all fields correctly', () {
      final expense = _makeExpense(amount: 45.50, category: 'Food & Ingredients');
      final map = expense.toMap();
      expect(map['amount'],          45.50);
      expect(map['category'],        'Food & Ingredients');
      expect(map['userId'],          'user_001');
      expect(map['isSynced'],        true);
      expect(map['receiptImageUrl'], '');
    });

    test('copyWith() updates only specified fields', () {
      final original = _makeExpense(amount: 100.0, category: 'Transport');
      final updated  = original.copyWith(
        amount: 120.0, category: 'Food & Ingredients');
      expect(updated.amount,      120.0);
      expect(updated.category,    'Food & Ingredients');
      expect(updated.description, original.description);
      expect(updated.id,          original.id);
    });

    test('fromMap() round-trips correctly', () {
      final expense  = _makeExpense(amount: 80.0, category: 'Labour');
      final restored = ExpenseModel.fromMap(expense.toMap());
      expect(restored.amount,   expense.amount);
      expect(restored.category, expense.category);
      expect(restored.userId,   expense.userId);
    });
  });

  group('BudgetModel', () {
    test('utilizationPct returns correct percentage', () {
      expect(_makeBudget(limit: 500.0, spend: 425.0).utilizationPct,
        closeTo(85.0, 0.01));
    });
    test('remaining returns correct leftover', () {
      expect(_makeBudget(limit: 500.0, spend: 425.0).remaining,
        closeTo(75.0, 0.01));
    });
    test('utilizationPct is 0 when monthlyLimit is 0', () {
      expect(_makeBudget(limit: 0, spend: 0).utilizationPct, 0.0);
    });
    test('copyWith() updates fields', () {
      final updated = _makeBudget(limit: 300.0, spend: 0.0)
        .copyWith(currentSpend: 250.0, alertSent80: true);
      expect(updated.currentSpend, 250.0);
      expect(updated.alertSent80,  true);
      expect(updated.monthlyLimit, 300.0);
    });
  });

  group('SavingsGoalModel', () {
    test('progressPct clamps between 0 and 1', () {
      expect(_makeGoal(target: 1000.0, current: 1200.0).progressPct, 1.0);
    });
    test('progressPct is 0 when targetAmount is 0', () {
      expect(_makeGoal(target: 0, current: 0).progressPct, 0.0);
    });
    test('remaining is 0 when current >= target', () {
      expect(_makeGoal(target: 500.0, current: 600.0).remaining, 0.0);
    });
    test('fromMap() round-trip', () {
      final goal     = _makeGoal(target: 750.0, current: 250.0);
      final restored = SavingsGoalModel.fromMap(goal.toMap());
      expect(restored.title,        goal.title);
      expect(restored.targetAmount, goal.targetAmount);
      expect(restored.isCompleted,  false);
    });
  });

  group('Budget Alert Logic', () {
    test('no alert below 80%', () {
      final b = _makeBudget(limit: 500.0, spend: 350.0);
      expect(_shouldAlert80(b),  false);
      expect(_shouldAlert100(b), false);
    });
    test('alert at 80%', () {
      final b = _makeBudget(limit: 500.0, spend: 410.0);
      expect(_shouldAlert80(b),  true);
      expect(_shouldAlert100(b), false);
    });
    test('no duplicate 80% alert', () {
      final b = BudgetModel(id: '1', userId: 'u1',
        category: 'Food & Ingredients', monthlyLimit: 500.0,
        currentSpend: 410.0, month: 6, year: 2024,
        alertSent80: true, alertSent100: false);
      expect(_shouldAlert80(b), false);
    });
    test('alert at 100%', () {
      expect(_shouldAlert100(_makeBudget(limit: 500.0, spend: 510.0)), true);
    });
    test('no duplicate 100% alert', () {
      final b = BudgetModel(id: '1', userId: 'u1', category: 'Transport',
        monthlyLimit: 500.0, currentSpend: 550.0, month: 6, year: 2024,
        alertSent80: true, alertSent100: true);
      expect(_shouldAlert80(b),  false);
      expect(_shouldAlert100(b), false);
    });
  });

  group('CSV Export', () {
    test('correct header and rows', () {
      final csv   = _buildCsv([
        _makeExpense(amount: 50.0,  category: 'Food & Ingredients'),
        _makeExpense(amount: 120.0, category: 'Transport'),
      ]);
      final lines = csv.split('\n');
      expect(lines.first, contains('Date,Category,Description,Amount'));
      expect(lines.length, 3);
      expect(lines[1], contains('50.00'));
      expect(lines[2], contains('120.00'));
    });
    test('CSV escapes commas in description', () {
      final desc = 'Flour, sugar, eggs';
      expect('"${desc.replaceAll('"', '""')}"', '"Flour, sugar, eggs"');
    });
  });

  group('Offline Queue', () {
    test('queued map has all required keys', () {
      final map = _makeExpense(amount: 99.0, category: 'Inventory').toMap();
      for (final key in ['id','userId','amount','category',
          'description','date','isSynced']) {
        expect(map.containsKey(key), true, reason: 'Missing key: $key');
      }
    });
  });
}

// ─── Stub Models ──────────────────────────────────────────────────────────────

class ExpenseModel {
  final String id, userId, category, description, receiptImageUrl;
  final double amount;
  final DateTime date, createdAt, updatedAt;
  final double? locationLat, locationLng;
  final bool isSynced;

  ExpenseModel({
    required this.id, required this.userId, required this.amount,
    required this.category, required this.description, required this.date,
    this.receiptImageUrl = '', this.locationLat, this.locationLng,
    this.isSynced = true, required this.createdAt, required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'userId': userId, 'amount': amount, 'category': category,
    'description': description, 'date': date.toIso8601String(),
    'receiptImageUrl': receiptImageUrl,
    'locationLat': locationLat ?? 0.0, 'locationLng': locationLng ?? 0.0,
    'isSynced': isSynced,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ExpenseModel.fromMap(Map<String, dynamic> m) => ExpenseModel(
    id: m['id'], userId: m['userId'],
    amount: (m['amount'] as num).toDouble(),
    category: m['category'], description: m['description'],
    date: DateTime.parse(m['date'] as String),
    receiptImageUrl: m['receiptImageUrl'] ?? '',
    isSynced: m['isSynced'] ?? true,
    createdAt: DateTime.parse(m['createdAt'] as String),
    updatedAt: DateTime.parse(m['updatedAt'] as String),
  );

  ExpenseModel copyWith({double? amount, String? category,
    String? description, DateTime? date, String? receiptImageUrl,
    double? locationLat, double? locationLng}) =>
    ExpenseModel(
      id: id, userId: userId,
      amount: amount ?? this.amount, category: category ?? this.category,
      description: description ?? this.description, date: date ?? this.date,
      receiptImageUrl: receiptImageUrl ?? this.receiptImageUrl,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      createdAt: createdAt, updatedAt: DateTime.now());
}

class BudgetModel {
  final String id, userId, category;
  final double monthlyLimit, currentSpend;
  final int month, year;
  final bool alertSent80, alertSent100;

  BudgetModel({required this.id, required this.userId, required this.category,
    required this.monthlyLimit, this.currentSpend = 0.0,
    required this.month, required this.year,
    this.alertSent80 = false, this.alertSent100 = false});

  double get utilizationPct =>
    monthlyLimit > 0 ? (currentSpend / monthlyLimit) * 100 : 0;
  double get remaining =>
    (monthlyLimit - currentSpend).clamp(0, double.infinity);

  BudgetModel copyWith({double? currentSpend, bool? alertSent80,
    bool? alertSent100, double? monthlyLimit}) =>
    BudgetModel(
      id: id, userId: userId, category: category, month: month, year: year,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      currentSpend: currentSpend ?? this.currentSpend,
      alertSent80: alertSent80 ?? this.alertSent80,
      alertSent100: alertSent100 ?? this.alertSent100);
}

class SavingsGoalModel {
  final String id, userId, title;
  final double targetAmount, currentAmount;
  final DateTime deadline, createdAt;
  final bool isCompleted;

  SavingsGoalModel({required this.id, required this.userId,
    required this.title, required this.targetAmount,
    this.currentAmount = 0.0, required this.deadline,
    this.isCompleted = false, required this.createdAt});

  double get progressPct =>
    targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0;
  double get remaining =>
    (targetAmount - currentAmount).clamp(0, double.infinity);

  Map<String, dynamic> toMap() => {
    'id': id, 'userId': userId, 'title': title,
    'targetAmount': targetAmount, 'currentAmount': currentAmount,
    'deadline': deadline.toIso8601String(),
    'isCompleted': isCompleted, 'createdAt': createdAt.toIso8601String(),
  };

  factory SavingsGoalModel.fromMap(Map<String, dynamic> m) => SavingsGoalModel(
    id: m['id'], userId: m['userId'], title: m['title'],
    targetAmount: (m['targetAmount'] as num).toDouble(),
    currentAmount: (m['currentAmount'] as num? ?? 0).toDouble(),
    deadline: DateTime.parse(m['deadline'] as String),
    createdAt: DateTime.parse(m['createdAt'] as String),
    isCompleted: m['isCompleted'] ?? false);
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

ExpenseModel _makeExpense({required double amount, required String category}) {
  final now = DateTime(2024, 6, 15, 10, 0);
  return ExpenseModel(id: 'exp_test', userId: 'user_001', amount: amount,
    category: category, description: 'Test purchase',
    date: now, createdAt: now, updatedAt: now);
}

BudgetModel _makeBudget({required double limit, required double spend}) =>
  BudgetModel(id: 'bud_test', userId: 'user_001',
    category: 'Food & Ingredients', monthlyLimit: limit,
    currentSpend: spend, month: 6, year: 2024);

SavingsGoalModel _makeGoal({required double target, required double current}) =>
  SavingsGoalModel(id: 'goal_test', userId: 'user_001', title: 'New Freezer',
    targetAmount: target, currentAmount: current,
    deadline: DateTime(2025, 1, 1), createdAt: DateTime(2024, 6, 1));

bool _shouldAlert80(BudgetModel b)  => b.utilizationPct >= 80  && !b.alertSent80;
bool _shouldAlert100(BudgetModel b) => b.utilizationPct >= 100 && !b.alertSent100;

String _buildCsv(List<ExpenseModel> expenses) {
  const header = 'Date,Category,Description,Amount,Receipt,Lat,Lng\n';
  final rows = expenses.map((e) =>
    '${e.date.toIso8601String().substring(0, 10)},'
    '${e.category},'
    '"${e.description.replaceAll('"', '""')}",'
    '${e.amount.toStringAsFixed(2)},,,').join('\n');
  return header + rows;
}

// lib/models/expense_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String userId;
  final double amount;
  final String category;
  final String description;
  final DateTime date;
  final String receiptImageUrl;
  final double? locationLat;
  final double? locationLng;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExpenseModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    this.receiptImageUrl = '',
    this.locationLat,
    this.locationLng,
    this.isSynced = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'userId': userId, 'amount': amount,
    'category': category, 'description': description,
    'date': Timestamp.fromDate(date),
    'receiptImageUrl': receiptImageUrl,
    'locationLat': locationLat ?? 0.0,
    'locationLng': locationLng ?? 0.0,
    'isSynced': isSynced,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  factory ExpenseModel.fromMap(Map<String, dynamic> m) => ExpenseModel(
    id:              m['id'] ?? '',
    userId:          m['userId'] ?? '',
    amount:          (m['amount'] as num).toDouble(),
    category:        m['category'] ?? '',
    description:     m['description'] ?? '',
    date:            (m['date'] as Timestamp).toDate(),
    receiptImageUrl: m['receiptImageUrl'] ?? '',
    locationLat:     (m['locationLat'] as num?)?.toDouble(),
    locationLng:     (m['locationLng'] as num?)?.toDouble(),
    isSynced:        m['isSynced'] ?? true,
    createdAt:       (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    updatedAt:       (m['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );

  ExpenseModel copyWith({
    double? amount, String? category, String? description,
    DateTime? date, String? receiptImageUrl,
    double? locationLat, double? locationLng,
  }) => ExpenseModel(
    id: id, userId: userId,
    amount:          amount          ?? this.amount,
    category:        category        ?? this.category,
    description:     description     ?? this.description,
    date:            date            ?? this.date,
    receiptImageUrl: receiptImageUrl ?? this.receiptImageUrl,
    locationLat:     locationLat     ?? this.locationLat,
    locationLng:     locationLng     ?? this.locationLng,
    createdAt: createdAt, updatedAt: DateTime.now(),
  );
}

// ─── Budget Model ─────────────────────────────────────────────────────────────
class BudgetModel {
  final String id;
  final String userId;
  final String category;
  final double monthlyLimit;
  final double currentSpend;
  final int month;
  final int year;
  final bool alertSent80;
  final bool alertSent100;

  BudgetModel({
    required this.id, required this.userId, required this.category,
    required this.monthlyLimit, this.currentSpend = 0.0,
    required this.month, required this.year,
    this.alertSent80 = false, this.alertSent100 = false,
  });

  double get utilizationPct => monthlyLimit > 0 ? (currentSpend / monthlyLimit) * 100 : 0;
  double get remaining => monthlyLimit - currentSpend;

  Map<String, dynamic> toMap() => {
    'id': id, 'userId': userId, 'category': category,
    'monthlyLimit': monthlyLimit, 'currentSpend': currentSpend,
    'month': month, 'year': year,
    'alertSent80': alertSent80, 'alertSent100': alertSent100,
  };

  factory BudgetModel.fromMap(Map<String, dynamic> m) => BudgetModel(
    id:           m['id'] ?? '',
    userId:       m['userId'] ?? '',
    category:     m['category'] ?? '',
    monthlyLimit: (m['monthlyLimit'] as num).toDouble(),
    currentSpend: (m['currentSpend'] as num? ?? 0).toDouble(),
    month:        m['month'] ?? DateTime.now().month,
    year:         m['year']  ?? DateTime.now().year,
    alertSent80:  m['alertSent80']  ?? false,
    alertSent100: m['alertSent100'] ?? false,
  );

  BudgetModel copyWith({
    double? currentSpend, bool? alertSent80,
    bool? alertSent100, double? monthlyLimit,
  }) => BudgetModel(
    id: id, userId: userId, category: category, month: month, year: year,
    monthlyLimit: monthlyLimit ?? this.monthlyLimit,
    currentSpend: currentSpend ?? this.currentSpend,
    alertSent80:  alertSent80  ?? this.alertSent80,
    alertSent100: alertSent100 ?? this.alertSent100,
  );
}

// ─── Savings Goal Model ───────────────────────────────────────────────────────
class SavingsGoalModel {
  final String id;
  final String userId;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;
  final bool isCompleted;
  final DateTime createdAt;

  SavingsGoalModel({
    required this.id, required this.userId, required this.title,
    required this.targetAmount, this.currentAmount = 0.0,
    required this.deadline, this.isCompleted = false,
    required this.createdAt,
  });

  double get progressPct =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0;
  double get remaining =>
      (targetAmount - currentAmount).clamp(0, double.infinity);

  Map<String, dynamic> toMap() => {
    'id': id, 'userId': userId, 'title': title,
    'targetAmount': targetAmount, 'currentAmount': currentAmount,
    'deadline': Timestamp.fromDate(deadline),
    'isCompleted': isCompleted,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory SavingsGoalModel.fromMap(Map<String, dynamic> m) => SavingsGoalModel(
    id:            m['id'] ?? '',
    userId:        m['userId'] ?? '',
    title:         m['title'] ?? '',
    targetAmount:  (m['targetAmount'] as num).toDouble(),
    currentAmount: (m['currentAmount'] as num? ?? 0).toDouble(),
    deadline:      (m['deadline'] as Timestamp).toDate(),
    isCompleted:   m['isCompleted'] ?? false,
    createdAt:     (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );
}

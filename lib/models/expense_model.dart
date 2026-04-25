// lib/models/expense_model.dart
// Models now have TWO factory constructors:
//   fromMap()    — for local Hive offline queue (old Firestore format)
//   fromApiMap() — for MySQL/REST API responses (snake_case keys)

import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String  id;
  final String  userId;
  final double  amount;
  final String  category;
  final String  description;
  final DateTime date;
  final String  receiptImageUrl;
  final double? locationLat;
  final double? locationLng;
  final bool    isSynced;
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

  // For Hive offline queue
  Map<String, dynamic> toMap() => {
    'id': id, 'userId': userId, 'amount': amount,
    'category': category, 'description': description,
    'date': date.toIso8601String(),
    'receiptImageUrl': receiptImageUrl,
    'locationLat': locationLat ?? 0.0,
    'locationLng': locationLng ?? 0.0,
    'isSynced': isSynced,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  // From Hive offline queue
  factory ExpenseModel.fromMap(Map<String, dynamic> m) => ExpenseModel(
    id:              m['id'] ?? '',
    userId:          m['userId'] ?? '',
    amount:          (m['amount'] as num).toDouble(),
    category:        m['category'] ?? '',
    description:     m['description'] ?? '',
    date:            m['date'] is String
                       ? DateTime.parse(m['date'])
                       : (m['date'] as Timestamp).toDate(),
    receiptImageUrl: m['receiptImageUrl'] ?? '',
    locationLat:     (m['locationLat'] as num?)?.toDouble(),
    locationLng:     (m['locationLng'] as num?)?.toDouble(),
    isSynced:        m['isSynced'] ?? true,
    createdAt:       m['createdAt'] is String
                       ? DateTime.parse(m['createdAt'])
                       : (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    updatedAt:       m['updatedAt'] is String
                       ? DateTime.parse(m['updatedAt'])
                       : (m['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );

  // From MySQL REST API response (snake_case)
  factory ExpenseModel.fromApiMap(Map<String, dynamic> m) => ExpenseModel(
    id:              m['expense_id'] ?? '',
    userId:          m['user_id'] ?? '',
    amount:          double.parse(m['amount'].toString()),
    category:        m['category'] ?? '',
    description:     m['description'] ?? '',
    date:            DateTime.parse(m['expense_date']),
    receiptImageUrl: m['receipt_image_url'] ?? '',
    locationLat:     m['location_lat'] != null
                       ? double.parse(m['location_lat'].toString()) : null,
    locationLng:     m['location_lng'] != null
                       ? double.parse(m['location_lng'].toString()) : null,
    isSynced:        true,
    createdAt:       DateTime.parse(m['created_at'] ?? DateTime.now().toIso8601String()),
    updatedAt:       DateTime.parse(m['updated_at'] ?? DateTime.now().toIso8601String()),
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
  final int    month;
  final int    year;
  final bool   alertSent80;
  final bool   alertSent100;

  BudgetModel({
    required this.id, required this.userId, required this.category,
    required this.monthlyLimit, this.currentSpend = 0.0,
    required this.month, required this.year,
    this.alertSent80 = false, this.alertSent100 = false,
  });

  double get utilizationPct =>
    monthlyLimit > 0 ? (currentSpend / monthlyLimit) * 100 : 0;
  double get remaining => monthlyLimit - currentSpend;

  Map<String, dynamic> toMap() => {
    'id': id, 'userId': userId, 'category': category,
    'monthlyLimit': monthlyLimit, 'currentSpend': currentSpend,
    'month': month, 'year': year,
    'alertSent80': alertSent80, 'alertSent100': alertSent100,
  };

  factory BudgetModel.fromMap(Map<String, dynamic> m) => BudgetModel(
    id: m['id'] ?? '', userId: m['userId'] ?? '', category: m['category'] ?? '',
    monthlyLimit: (m['monthlyLimit'] as num).toDouble(),
    currentSpend: (m['currentSpend'] as num? ?? 0).toDouble(),
    month: m['month'] ?? DateTime.now().month,
    year:  m['year']  ?? DateTime.now().year,
    alertSent80:  m['alertSent80']  ?? false,
    alertSent100: m['alertSent100'] ?? false,
  );

  // From MySQL REST API response (snake_case)
  factory BudgetModel.fromApiMap(Map<String, dynamic> m) => BudgetModel(
    id:           m['budget_id'] ?? '',
    userId:       m['user_id'] ?? '',
    category:     m['category'] ?? '',
    monthlyLimit: double.parse(m['monthly_limit'].toString()),
    currentSpend: double.parse((m['current_spend'] ?? 0).toString()),
    month:        m['month'] ?? DateTime.now().month,
    year:         m['year']  ?? DateTime.now().year,
    alertSent80:  (m['alert_sent_80'] ?? 0) == 1,
    alertSent100: (m['alert_sent_100'] ?? 0) == 1,
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
  final String   id;
  final String   userId;
  final String   title;
  final double   targetAmount;
  final double   currentAmount;
  final DateTime deadline;
  final bool     isCompleted;
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
    'deadline': deadline.toIso8601String(),
    'isCompleted': isCompleted,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SavingsGoalModel.fromMap(Map<String, dynamic> m) => SavingsGoalModel(
    id: m['id'] ?? '', userId: m['userId'] ?? '', title: m['title'] ?? '',
    targetAmount:  (m['targetAmount']  as num).toDouble(),
    currentAmount: (m['currentAmount'] as num? ?? 0).toDouble(),
    deadline:  DateTime.parse(m['deadline']),
    createdAt: DateTime.parse(m['createdAt']),
    isCompleted: m['isCompleted'] ?? false,
  );

  // From MySQL REST API response (snake_case)
  factory SavingsGoalModel.fromApiMap(Map<String, dynamic> m) => SavingsGoalModel(
    id:            m['goal_id'] ?? '',
    userId:        m['user_id'] ?? '',
    title:         m['title'] ?? '',
    targetAmount:  double.parse(m['target_amount'].toString()),
    currentAmount: double.parse((m['current_amount'] ?? 0).toString()),
    deadline:      DateTime.parse(m['deadline']),
    isCompleted:   (m['is_completed'] ?? 0) == 1,
    createdAt:     DateTime.parse(
                     m['created_at'] ?? DateTime.now().toIso8601String()),
  );
}

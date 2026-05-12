import 'package:equatable/equatable.dart';

class FinanceModel extends Equatable {
  final String id;
  final String userId;
  final String type;     // income, expense
  final String category;
  final double amount;
  final String note;
  final DateTime date;
  final DateTime created;
  final DateTime updated;

  const FinanceModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.category,
    required this.amount,
    this.note = '',
    required this.date,
    required this.created,
    required this.updated,
  });

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  factory FinanceModel.fromJson(Map<String, dynamic> json) {
    return FinanceModel(
      id: json['id'] ?? '',
      userId: json['user'] ?? '',
      type: json['type'] ?? 'expense',
      category: json['category'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      note: json['note'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      created: DateTime.tryParse(json['created'] ?? '') ?? DateTime.now(),
      updated: DateTime.tryParse(json['updated'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': userId,
      'type': type,
      'category': category,
      'amount': amount,
      'note': note,
      'date': date.toIso8601String(),
    };
  }

  FinanceModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? category,
    double? amount,
    String? note,
    DateTime? date,
    DateTime? created,
    DateTime? updated,
  }) {
    return FinanceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      date: date ?? this.date,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  @override
  List<Object?> get props =>
      [id, userId, type, category, amount, note, date, created, updated];
}

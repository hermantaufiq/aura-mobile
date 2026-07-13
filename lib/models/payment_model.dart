import 'package:equatable/equatable.dart';
import 'package:pocketbase/pocketbase.dart';
import 'user_model.dart';

class PaymentModel extends Equatable {
  final String id;
  final String userId;
  final String orderId;
  final int grossAmount;
  final String status;
  final String planType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserModel? expandedUser;

  const PaymentModel({
    required this.id,
    required this.userId,
    required this.orderId,
    required this.grossAmount,
    required this.status,
    required this.planType,
    required this.createdAt,
    required this.updatedAt,
    this.expandedUser,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    UserModel? user;
    if (json['expand'] != null && json['expand']['user'] != null) {
      user = UserModel.fromJson(json['expand']['user']);
    }

    return PaymentModel(
      id: json['id'] ?? '',
      userId: json['user'] ?? '',
      orderId: json['order_id'] ?? '',
      grossAmount: (json['gross_amount'] ?? 0).toInt(),
      status: json['status'] ?? 'pending',
      planType: json['plan_type'] ?? '',
      createdAt: DateTime.parse(json['created'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated'] ?? DateTime.now().toIso8601String()),
      expandedUser: user,
    );
  }

  factory PaymentModel.fromRecord(RecordModel record) {
    return PaymentModel.fromJson({
      ...record.toJson(),
      ...record.data,
    });
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'order_id': orderId,
      'gross_amount': grossAmount,
      'status': status,
      'plan_type': planType,
      'created': createdAt.toIso8601String(),
      'updated': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        orderId,
        grossAmount,
        status,
        planType,
        createdAt,
        updatedAt,
        expandedUser,
      ];
}

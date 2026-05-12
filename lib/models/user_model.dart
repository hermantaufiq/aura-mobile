import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool isVerified;
  final bool isPremium;
  final DateTime? premiumExpiredAt;
  final int aiDailyCount;
  final DateTime? aiLastReset;
  final String? avatar;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isVerified = false,
    this.isPremium = false,
    this.premiumExpiredAt,
    this.aiDailyCount = 0,
    this.aiLastReset,
    this.avatar,
  });

  bool get isPremiumActive {
    if (!isPremium) return false;
    if (premiumExpiredAt == null) return false;
    return premiumExpiredAt!.isAfter(DateTime.now());
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      isVerified: json['is_verified'] ?? false,
      isPremium: json['is_premium'] ?? false,
      premiumExpiredAt: json['premium_expired_at'] != null
          ? DateTime.tryParse(json['premium_expired_at'])
          : null,
      aiDailyCount: json['ai_daily_count'] ?? 0,
      aiLastReset: json['ai_last_reset'] != null
          ? DateTime.tryParse(json['ai_last_reset'])
          : null,
      avatar: json['avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'is_verified': isVerified,
      'is_premium': isPremium,
      'premium_expired_at': premiumExpiredAt?.toIso8601String(),
      'ai_daily_count': aiDailyCount,
      'ai_last_reset': aiLastReset?.toIso8601String(),
      'avatar': avatar,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    bool? isVerified,
    bool? isPremium,
    DateTime? premiumExpiredAt,
    int? aiDailyCount,
    DateTime? aiLastReset,
    String? avatar,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      isPremium: isPremium ?? this.isPremium,
      premiumExpiredAt: premiumExpiredAt ?? this.premiumExpiredAt,
      aiDailyCount: aiDailyCount ?? this.aiDailyCount,
      aiLastReset: aiLastReset ?? this.aiLastReset,
      avatar: avatar ?? this.avatar,
    );
  }

  @override
  List<Object?> get props => [
        id, name, email, role, isVerified, isPremium,
        premiumExpiredAt, aiDailyCount, aiLastReset, avatar,
      ];
}

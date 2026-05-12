import 'package:equatable/equatable.dart';

class AiChatModel extends Equatable {
  final String id;
  final String userId;
  final String message;
  final String response;
  final DateTime created;

  const AiChatModel({
    required this.id,
    required this.userId,
    required this.message,
    required this.response,
    required this.created,
  });

  factory AiChatModel.fromJson(Map<String, dynamic> json) {
    return AiChatModel(
      id: json['id'] ?? '',
      userId: json['user'] ?? '',
      message: json['message'] ?? '',
      response: json['response'] ?? '',
      created: DateTime.tryParse(json['created'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': userId,
      'message': message,
      'response': response,
    };
  }

  @override
  List<Object?> get props => [id, userId, message, response, created];
}

// Chat message for local display (not persisted individually)
class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isLoading;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isLoading = false,
  });

  factory ChatMessage.user(String content) => ChatMessage(
        content: content,
        isUser: true,
        timestamp: DateTime.now(),
      );

  factory ChatMessage.ai(String content) => ChatMessage(
        content: content,
        isUser: false,
        timestamp: DateTime.now(),
      );

  factory ChatMessage.loading() => ChatMessage(
        content: '',
        isUser: false,
        timestamp: DateTime.now(),
        isLoading: true,
      );
}

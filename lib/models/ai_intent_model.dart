/// Model untuk hasil parsing intent dari AI
class AiIntent {
  final AiAction action;
  final Map<String, dynamic> fields;
  final String? confirmationMessage;

  const AiIntent({
    required this.action,
    required this.fields,
    this.confirmationMessage,
  });

  bool get isActionable => action != AiAction.none;

  factory AiIntent.none() => const AiIntent(action: AiAction.none, fields: {});

  factory AiIntent.fromJson(Map<String, dynamic> json) {
    final actionStr = json['action'] as String? ?? 'none';
    final action = AiAction.values.firstWhere(
      (a) => a.name == actionStr,
      orElse: () => AiAction.none,
    );
    return AiIntent(
      action: action,
      fields: (json['fields'] as Map<String, dynamic>?) ?? {},
      confirmationMessage: json['confirmation_message'] as String?,
    );
  }
}

enum AiAction {
  none,
  createTask,
  createFinance,
  updateTaskStatus,
  queryData,
}

extension AiActionLabel on AiAction {
  String get label {
    switch (this) {
      case AiAction.createTask:
        return 'Tugas Dibuat';
      case AiAction.createFinance:
        return 'Transaksi Dicatat';
      case AiAction.updateTaskStatus:
        return 'Status Tugas Diperbarui';
      case AiAction.queryData:
        return 'Data Diambil';
      case AiAction.none:
        return '';
    }
  }

  String get icon {
    switch (this) {
      case AiAction.createTask:
        return '✅';
      case AiAction.createFinance:
        return '💰';
      case AiAction.updateTaskStatus:
        return '🔄';
      case AiAction.queryData:
        return '📊';
      case AiAction.none:
        return '';
    }
  }
}

import '../../core/constants/operator_constants.dart';

enum UssdSessionStatus {
  idle,
  sending,
  waitingUserResponse,
  completed,
  failed,
  cancelled,
}

class UssdSessionMessage {
  final String content;
  final bool isFromSim;
  final DateTime timestamp;
  final List<String> detectedOptions;

  UssdSessionMessage({
    required this.content,
    required this.isFromSim,
    DateTime? timestamp,
    this.detectedOptions = const [],
  }) : timestamp = timestamp ?? DateTime.now();
}

class UssdSessionState {
  final String sessionId;
  final OperatorType operator;
  final String initialCommand;
  final UssdSessionStatus status;
  final List<UssdSessionMessage> messages;
  final String? currentPrompt;
  final List<String> currentOptions;
  final String? transactionRef;
  final double? newBalance;
  final String? errorMessage;

  UssdSessionState({
    required this.sessionId,
    required this.operator,
    required this.initialCommand,
    required this.status,
    required this.messages,
    this.currentPrompt,
    this.currentOptions = const [],
    this.transactionRef,
    this.newBalance,
    this.errorMessage,
  });

  bool get isWaitingUser => status == UssdSessionStatus.waitingUserResponse;
  bool get isCompleted => status == UssdSessionStatus.completed;
  bool get isFailed => status == UssdSessionStatus.failed;
  bool get isProcessing => status == UssdSessionStatus.sending;

  UssdSessionState copyWith({
    UssdSessionStatus? status,
    List<UssdSessionMessage>? messages,
    String? currentPrompt,
    List<String>? currentOptions,
    String? transactionRef,
    double? newBalance,
    String? errorMessage,
  }) {
    return UssdSessionState(
      sessionId: sessionId,
      operator: operator,
      initialCommand: initialCommand,
      status: status ?? this.status,
      messages: messages ?? this.messages,
      currentPrompt: currentPrompt ?? this.currentPrompt,
      currentOptions: currentOptions ?? this.currentOptions,
      transactionRef: transactionRef ?? this.transactionRef,
      newBalance: newBalance ?? this.newBalance,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

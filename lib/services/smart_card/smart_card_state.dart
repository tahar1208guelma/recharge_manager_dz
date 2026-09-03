import '../../core/constants/operator_constants.dart';
import 'card_info.dart';
import 'reader_device_info.dart';

enum SmartCardConnectionStatus {
  disconnected,
  readerConnected, // 🟢 Reader Connected
  cardWaiting,     // 🟡 Card Waiting (Reader ready, waiting for SIM insertion)
  cardDetected,    // 🔵 Card Detected (SIM present and read)
  readerError,     // 🔴 Reader Error / Incompatible
}

class SmartCardReaderState {
  final SmartCardConnectionStatus status;
  final ReaderDeviceInfo? deviceInfo;
  final CardInfo? cardInfo;
  final String? errorMessage;
  final DateTime lastEventTime;

  const SmartCardReaderState({
    this.status = SmartCardConnectionStatus.disconnected,
    this.deviceInfo,
    this.cardInfo,
    this.errorMessage,
    required this.lastEventTime,
  });

  bool get isReaderConnected =>
      status == SmartCardConnectionStatus.readerConnected ||
      status == SmartCardConnectionStatus.cardWaiting ||
      status == SmartCardConnectionStatus.cardDetected;

  bool get isWaitingForCard => status == SmartCardConnectionStatus.cardWaiting;

  bool get hasCard => status == SmartCardConnectionStatus.cardDetected && cardInfo != null;

  bool get hasError => status == SmartCardConnectionStatus.readerError || errorMessage != null;

  String? get readerName => deviceInfo?.readerName;

  OperatorType get detectedOperator => cardInfo?.operator ?? OperatorType.unknown;

  SmartCardReaderState copyWith({
    SmartCardConnectionStatus? status,
    ReaderDeviceInfo? deviceInfo,
    CardInfo? cardInfo,
    String? errorMessage,
    DateTime? lastEventTime,
  }) {
    return SmartCardReaderState(
      status: status ?? this.status,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      cardInfo: cardInfo ?? this.cardInfo,
      errorMessage: errorMessage ?? this.errorMessage,
      lastEventTime: lastEventTime ?? this.lastEventTime,
    );
  }
}

import '../../core/constants/operator_constants.dart';
import 'card_info.dart';
import 'reader_device_info.dart';
import 'smart_card_error_code.dart';

export 'smart_card_error_code.dart';

enum SmartCardConnectionStatus {
  disconnected,
  readerConnected, // 🟢 Reader Connected
  cardWaiting,     // 🟡 Card Waiting (Reader ready, waiting for SIM insertion)
  cardDetected,    // 🔵 Card Detected (SIM present and read)
  readerError,     // 🔴 Reader Error / Incompatible
}

class SmartCardReaderState {
  final SmartCardConnectionStatus status;
  final SmartCardErrorCode errorCode;
  final ReaderDeviceInfo? deviceInfo;
  final CardInfo? cardInfo;
  final String? errorMessage;
  final DateTime lastEventTime;

  const SmartCardReaderState({
    this.status = SmartCardConnectionStatus.disconnected,
    this.errorCode = SmartCardErrorCode.none,
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

  bool get hasError =>
      status == SmartCardConnectionStatus.readerError ||
      errorMessage != null ||
      errorCode != SmartCardErrorCode.none;

  bool get isNoReader => errorCode == SmartCardErrorCode.noReader;
  bool get isNoCard => errorCode == SmartCardErrorCode.noCard;
  bool get isCardMuted => errorCode == SmartCardErrorCode.cardMuted;
  bool get isPinLocked => errorCode == SmartCardErrorCode.pinLocked;
  bool get isProtocolError => errorCode == SmartCardErrorCode.protocolError;
  bool get isUnsupportedPlatform => errorCode == SmartCardErrorCode.unsupportedPlatform;

  String? get formattedErrorMessage {
    if (errorMessage != null && errorMessage!.isNotEmpty) {
      return errorMessage;
    }
    switch (errorCode) {
      case SmartCardErrorCode.noReader:
        return 'لم يتم اكتشاف أي قارئ بطاقات ذكية متصل (noReader)';
      case SmartCardErrorCode.noCard:
        return 'القارئ متصل ولكن لا توجد شريحة مدرجة (noCard)';
      case SmartCardErrorCode.cardMuted:
        return 'البطاقة صامتة ولا تستجيب لإشارة التنشيط (cardMuted)';
      case SmartCardErrorCode.pinLocked:
        return 'شريحة الاتصال مقفلة وتتطلب إدخال رمز PIN (pinLocked)';
      case SmartCardErrorCode.protocolError:
        return 'حدث خطأ في بروتوكول الاتصال ونقل البيانات (protocolError)';
      case SmartCardErrorCode.unsupportedPlatform:
        return 'قراءة شرائح SIM عبر USB غير مدعومة على هذه المنصة (unsupportedPlatform)';
      case SmartCardErrorCode.none:
        return null;
    }
  }

  String? get readerName => deviceInfo?.readerName;

  OperatorType get detectedOperator => cardInfo?.operator ?? OperatorType.unknown;

  SmartCardReaderState copyWith({
    SmartCardConnectionStatus? status,
    SmartCardErrorCode? errorCode,
    ReaderDeviceInfo? deviceInfo,
    CardInfo? cardInfo,
    String? errorMessage,
    DateTime? lastEventTime,
  }) {
    return SmartCardReaderState(
      status: status ?? this.status,
      errorCode: errorCode ?? this.errorCode,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      cardInfo: cardInfo ?? this.cardInfo,
      errorMessage: errorMessage ?? this.errorMessage,
      lastEventTime: lastEventTime ?? this.lastEventTime,
    );
  }
}

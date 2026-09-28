import 'dart:async';
import '../../../core/utils/app_logger.dart';
import '../card_connection.dart';
import '../card_info.dart';
import '../reader_device_info.dart';
import '../smart_card_service.dart';
import '../smart_card_state.dart';

/// Android USB Smart Card Service - Option A: Unsupported Platform Implementation
/// Explicitly reports that USB SIM card reading is unsupported on Android without returning any fake data.
class AndroidUsbHostService implements SmartCardService {
  final _stateController = StreamController<SmartCardReaderState>.broadcast();
  SmartCardReaderState _currentState;

  AndroidUsbHostService()
      : _currentState = SmartCardReaderState(
          status: SmartCardConnectionStatus.readerError,
          errorCode: SmartCardErrorCode.unsupportedPlatform,
          errorMessage: 'قراءة شرائح SIM عبر USB غير مدعومة على أندرويد (Not supported on Android)',
          lastEventTime: DateTime.now(),
        );

  @override
  Stream<SmartCardReaderState> get stateStream => _stateController.stream;

  @override
  SmartCardReaderState get currentState => _currentState;

  @override
  CardConnection? get activeConnection => null;

  @override
  Future<void> initialize() async {
    AppLogger.info('AndroidUsbHostService: Smart Card reading is not supported on Android.');
    _currentState = SmartCardReaderState(
      status: SmartCardConnectionStatus.readerError,
      errorCode: SmartCardErrorCode.unsupportedPlatform,
      errorMessage: 'قراءة شرائح SIM عبر USB غير مدعومة على أندرويد (Not supported on Android)',
      lastEventTime: DateTime.now(),
    );
    _stateController.add(_currentState);
  }

  @override
  Future<List<ReaderDeviceInfo>> listReaders() async => [];

  @override
  Future<bool> connect([String? readerName]) async {
    return false;
  }

  @override
  Future<void> disconnect() async {}

  @override
  Future<bool> isCardPresent() async => false;

  @override
  Future<CardInfo?> getCardInfo() async => null;

  @override
  void dispose() {
    _stateController.close();
  }
}

import '../smart_card/card_info.dart';
import '../smart_card/reader_device_info.dart';
import '../smart_card/smart_card_service.dart';
import '../smart_card/smart_card_state.dart';

abstract class UsbReaderService {
  Stream<SmartCardReaderState> get stateStream;
  SmartCardReaderState get currentState;

  Future<void> initialize();
  Future<List<ReaderDeviceInfo>> listReaders();
  Future<bool> connect([String? readerName]);
  Future<void> disconnect();
  Future<bool> isCardPresent();
  Future<CardInfo?> getCardInfo();
  void dispose();
}

class UsbReaderServiceImpl implements UsbReaderService {
  final SmartCardService _smartCardService;

  UsbReaderServiceImpl(this._smartCardService);

  @override
  Stream<SmartCardReaderState> get stateStream => _smartCardService.stateStream;

  @override
  SmartCardReaderState get currentState => _smartCardService.currentState;

  @override
  Future<void> initialize() => _smartCardService.initialize();

  @override
  Future<List<ReaderDeviceInfo>> listReaders() => _smartCardService.listReaders();

  @override
  Future<bool> connect([String? readerName]) => _smartCardService.connect(readerName);

  @override
  Future<void> disconnect() => _smartCardService.disconnect();

  @override
  Future<bool> isCardPresent() => _smartCardService.isCardPresent();

  @override
  Future<CardInfo?> getCardInfo() => _smartCardService.getCardInfo();

  @override
  void dispose() => _smartCardService.dispose();
}

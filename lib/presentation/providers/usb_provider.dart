import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/operator_constants.dart';
import '../../services/smart_card/card_info.dart';
import '../../services/smart_card/platforms/mock_smart_card_service.dart';
import '../../services/smart_card/reader_device_info.dart';
import '../../services/smart_card/smart_card_service.dart';
import '../../services/smart_card/smart_card_service_factory.dart';
import '../../services/smart_card/smart_card_state.dart';

class UsbProvider extends ChangeNotifier {
  final SmartCardService _service;
  StreamSubscription<SmartCardReaderState>? _subscription;
  SmartCardReaderState _state;
  List<ReaderDeviceInfo> _availableReaders = [];

  UsbProvider({SmartCardService? service})
      : _service = service ?? SmartCardServiceFactory.create(forceMock: true),
        _state = (service ?? SmartCardServiceFactory.create(forceMock: true)).currentState {
    _subscription = _service.stateStream.listen((newState) {
      _state = newState;
      notifyListeners();
    });
    refreshReaders();
  }

  SmartCardReaderState get state => _state;
  SmartCardConnectionStatus get status => _state.status;
  bool get isReaderConnected => _state.isReaderConnected;
  bool get isWaitingForCard => _state.isWaitingForCard;
  bool get hasCard => _state.hasCard;
  bool get hasError => _state.hasError;
  CardInfo? get cardInfo => _state.cardInfo;
  ReaderDeviceInfo? get deviceInfo => _state.deviceInfo;
  String? get readerName => _state.readerName ?? deviceInfo?.readerName;
  OperatorType get detectedOperator => _state.detectedOperator;
  String? get errorMessage => _state.errorMessage;
  List<ReaderDeviceInfo> get availableReaders => _availableReaders;

  Future<void> initialize() async {
    await _service.initialize();
    await refreshReaders();
  }

  Future<void> refreshReaders() async {
    try {
      _availableReaders = await _service.listReaders();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> connectReader([String? readerName]) async {
    await _service.connect(readerName);
    await refreshReaders();
  }

  Future<void> disconnectReader() async {
    await _service.disconnect();
  }

  Future<bool> isCardPresent() async {
    return await _service.isCardPresent();
  }

  Future<CardInfo?> readCard() async {
    final info = await _service.getCardInfo();
    notifyListeners();
    return info;
  }

  Future<void> simulateInsertSimCard(OperatorType operator) async {
    final s = _service;
    if (s is MockSmartCardService) {
      await s.insertSimCard(operator);
    }
  }

  Future<void> simulateRemoveSimCard() async {
    final s = _service;
    if (s is MockSmartCardService) {
      await s.removeSimCard();
    }
  }

  void simulateError(String errorMsg) {
    final s = _service;
    if (s is MockSmartCardService) {
      s.simulateError(errorMsg);
    }
  }

  void simulateIncompatibleReader() {
    final s = _service;
    if (s is MockSmartCardService) {
      s.simulateIncompatibleReader();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _service.dispose();
    super.dispose();
  }
}

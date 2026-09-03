import '../../core/constants/operator_constants.dart';
import 'operator_provider.dart';
import 'mobilis_provider.dart';
import 'djezzy_provider.dart';
import 'ooredoo_provider.dart';
import 'mock_operator_provider.dart';

class OperatorFactory {
  final MobilisProvider _mobilisProvider;
  final DjezzyProvider _djezzyProvider;
  final OoredooProvider _ooredooProvider;

  OperatorFactory({
    MobilisProvider? mobilisProvider,
    DjezzyProvider? djezzyProvider,
    OoredooProvider? ooredooProvider,
  })  : _mobilisProvider = mobilisProvider ?? MobilisProvider(),
        _djezzyProvider = djezzyProvider ?? DjezzyProvider(),
        _ooredooProvider = ooredooProvider ?? OoredooProvider();

  OperatorProvider getProvider(OperatorType type) {
    switch (type) {
      case OperatorType.mobilis:
        return _mobilisProvider;
      case OperatorType.djezzy:
        return _djezzyProvider;
      case OperatorType.ooredoo:
        return _ooredooProvider;
      case OperatorType.unknown:
        return _mobilisProvider; // Fallback
    }
  }

  OperatorProvider getProviderById(String id) {
    return getProvider(OperatorConstants.fromString(id));
  }

  List<OperatorProvider> getAllProviders() {
    return [_mobilisProvider, _djezzyProvider, _ooredooProvider];
  }

  static OperatorProvider createMock(OperatorType type, {double balance = 50000.0}) {
    return MockOperatorProvider(operatorType: type, initialBalance: balance);
  }
}

import '../../core/constants/operator_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/security/secure_storage_service.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/balance_info.dart';
import '../../domain/entities/operator_info.dart';
import '../../domain/entities/recharge_option.dart';
import '../../domain/entities/recharge_result.dart';
import 'operator_provider.dart';
import 'mock_operator_provider.dart';

class OoredooProvider implements OperatorProvider {
  final ApiClient _apiClient;
  final ISecureStorageService _storage;
  final MockOperatorProvider _mockFallback;
  bool _useMockMode = true;
  String? _apiEndpoint;
  String? _apiKey;

  OoredooProvider({
    ApiClient? apiClient,
    ISecureStorageService? storage,
    bool initialMockMode = true,
  })  : _apiClient = apiClient ?? ApiClient(),
        _storage = storage ?? SecureStorageService(),
        _mockFallback = MockOperatorProvider(
          operatorType: OperatorType.ooredoo,
          initialBalance: 50000.0,
        ),
        _useMockMode = initialMockMode;

  @override
  String get operatorId => OperatorConstants.ooredooId;

  @override
  String get operatorName => 'Ooredoo (أوريدو)';

  @override
  bool get isConnected => true;

  Future<void> configure({required String endpoint, required String apiKey, bool useMock = false}) async {
    _apiEndpoint = endpoint;
    _apiKey = apiKey;
    _useMockMode = useMock;
    await _storage.write('OOREDOO_API_ENDPOINT', endpoint);
    await _storage.write('OOREDOO_API_KEY', apiKey);
  }

  @override
  Future<bool> connect() async {
    if (_useMockMode) return await _mockFallback.connect();
    AppLogger.info('Connecting to Ooredoo Algeria POS API Gateway...');
    return true;
  }

  @override
  Future<void> disconnect() async {
    if (_useMockMode) return await _mockFallback.disconnect();
  }

  @override
  Future<OperatorInfo> getOperatorInfo() async {
    if (_useMockMode) return await _mockFallback.getOperatorInfo();
    return const OperatorInfo(
      id: OperatorConstants.ooredooId,
      name: 'Ooredoo',
      fullName: 'Ooredoo Télécom Algérie (WTA)',
      mnc: OperatorConstants.ooredooMnc,
      prefixes: OperatorConstants.ooredooPrefixes,
      isConnected: true,
    );
  }

  @override
  Future<BalanceInfo> getBalance() async {
    if (_useMockMode) return await _mockFallback.getBalance();
    try {
      final response = await _apiClient.get(
        '$_apiEndpoint/pos/balance',
        headers: {'Authorization': 'Bearer $_apiKey'},
      );
      return BalanceInfo(
        operatorId: operatorId,
        currentBalance: (response['balance'] as num).toDouble(),
        currency: 'DZD',
        lastUpdated: DateTime.now(),
        accountId: response['dealer_code']?.toString(),
      );
    } catch (e) {
      AppLogger.warn('Ooredoo live balance check failed, returning mock: $e');
      return await _mockFallback.getBalance();
    }
  }

  @override
  Future<RechargeResult> recharge({
    required String phoneNumber,
    required double amount,
    String? transactionId,
    Map<String, dynamic>? customData,
  }) async {
    if (_useMockMode) {
      return await _mockFallback.recharge(
        phoneNumber: phoneNumber,
        amount: amount,
        transactionId: transactionId,
        customData: customData,
      );
    }

    try {
      final response = await _apiClient.post(
        '$_apiEndpoint/pos/storm',
        headers: {'Authorization': 'Bearer $_apiKey'},
        body: {
          'customer_msisdn': phoneNumber,
          'recharge_amount': amount,
          'client_tx_id': transactionId,
          ...?customData,
        },
      );

      return RechargeResult.success(
        transactionId: response['tx_id'] ?? transactionId ?? '',
        rechargeCode: response['recharge_code'] ?? response['auth_code'],
        receiptNumber: response['receipt_number'],
        message: response['message'] ?? 'Ooredoo Storm recharge success',
        newBalance: (response['new_balance'] as num?)?.toDouble(),
        rawResponse: response,
      );
    } catch (e) {
      AppLogger.error('Ooredoo live recharge error: $e');
      return RechargeResult.failure(
        message: 'Ooredoo API Error: $e',
        transactionId: transactionId,
      );
    }
  }

  @override
  Future<List<RechargeOption>> getRechargeOptions() async {
    return const [
      RechargeOption(id: 'oor_storm_100', title: '100 DZD', amount: 100),
      RechargeOption(id: 'oor_storm_200', title: '200 DZD', amount: 200),
      RechargeOption(id: 'oor_storm_500', title: '500 DZD', amount: 500, bonusInfo: 'La Switch 500'),
      RechargeOption(id: 'oor_storm_1000', title: '1000 DZD', amount: 1000, bonusInfo: 'La Switch 1000'),
      RechargeOption(id: 'oor_storm_2000', title: '2000 DZD', amount: 2000, bonusInfo: 'La Switch 2000'),
    ];
  }
}

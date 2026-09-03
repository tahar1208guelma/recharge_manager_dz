import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'core/localization/app_localizations.dart';
import 'core/localization/locale_provider.dart';
import 'core/security/secure_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_logger.dart';

import 'data/datasources/local/customer_local_datasource.dart';
import 'data/datasources/local/database_helper.dart';
import 'data/datasources/local/license_local_datasource.dart';
import 'data/datasources/local/settings_local_datasource.dart';
import 'data/datasources/local/transaction_local_datasource.dart';
import 'data/datasources/local/user_local_datasource.dart';
import 'data/datasources/remote/license_remote_datasource.dart';

import 'data/repositories/customer_repository_impl.dart';
import 'data/repositories/license_repository_impl.dart';
import 'data/repositories/settings_repository_impl.dart';
import 'data/repositories/transaction_repository_impl.dart';
import 'data/repositories/user_repository_impl.dart';

import 'domain/usecases/recharge_usecases.dart';

import 'presentation/providers/app_state_provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/customer_provider.dart';
import 'presentation/providers/history_provider.dart';
import 'presentation/providers/license_provider.dart';
import 'presentation/providers/recharge_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/providers/usb_provider.dart';

import 'presentation/screens/login_screen.dart';
import 'presentation/screens/main_layout_screen.dart';

import 'services/licensing/license_client_service.dart';
import 'services/operators/operator_factory.dart';
import 'services/smart_card/smart_card_service_factory.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite FFI based on platform
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  AppLogger.info('Starting Recharge Manager DZ Application...');

  // Core singletons
  final dbHelper = DatabaseHelper();
  final secureStorage = SecureStorageService();

  // Repositories
  final customerRepo = CustomerRepositoryImpl(
    localDataSource: CustomerLocalDataSourceImpl(dbHelper: dbHelper),
  );
  final transactionRepo = TransactionRepositoryImpl(
    localDataSource: TransactionLocalDataSourceImpl(dbHelper: dbHelper),
  );
  final licenseRepo = LicenseRepositoryImpl(
    localDataSource: LicenseLocalDataSourceImpl(dbHelper: dbHelper),
  );
  final settingsRepo = SettingsRepositoryImpl(
    localDataSource: SettingsLocalDataSourceImpl(dbHelper: dbHelper),
  );
  final userRepo = UserRepositoryImpl(
    localDataSource: UserLocalDataSourceImpl(dbHelper: dbHelper),
  );

  // Services
  final operatorFactory = OperatorFactory();
  final licenseService = LicenseClientService(
    repository: licenseRepo,
    remoteDataSource: LicenseRemoteDataSourceImpl(),
    secureStorage: secureStorage,
  );
  final smartCardService = SmartCardServiceFactory.create();

  // Use cases
  final rechargeUseCase = ExecuteRechargeUseCase(
    transactionRepository: transactionRepo,
    customerRepository: customerRepo,
  );

  // Providers
  final localeProvider = LocaleProvider(storage: secureStorage);
  final settingsProvider = SettingsProvider(repository: settingsRepo);
  final licenseProvider = LicenseProvider(licenseService: licenseService);
  final authProvider = AuthProvider(userRepository: userRepo);

  // Safe async initialization
  try {
    await localeProvider.initialize();
  } catch (e) {
    AppLogger.warn('LocaleProvider init: $e');
  }

  try {
    await settingsProvider.initialize();
  } catch (e) {
    AppLogger.warn('SettingsProvider init: $e');
  }

  try {
    await licenseProvider.initialize();
  } catch (e) {
    AppLogger.warn('LicenseProvider init: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: licenseProvider),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => UsbProvider(service: smartCardService)),
        ChangeNotifierProvider(create: (_) => CustomerProvider(repository: customerRepo)),
        ChangeNotifierProvider(create: (_) => HistoryProvider(repository: transactionRepo)),
        ChangeNotifierProvider(
          create: (_) => RechargeProvider(
            rechargeUseCase: rechargeUseCase,
            operatorFactory: operatorFactory,
          ),
        ),
      ],
      child: const RechargeManagerDzApp(),
    ),
  );
}

class RechargeManagerDzApp extends StatelessWidget {
  const RechargeManagerDzApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return MaterialApp(
      title: 'Recharge Manager DZ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settingsProvider.themeMode,
      locale: localeProvider.locale,
      supportedLocales: const [
        Locale('ar'),
        Locale('fr'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (!auth.isAuthenticated) {
            return LoginScreen(onLoginSuccess: () {});
          }
          return const MainLayoutScreen();
        },
      ),
    );
  }
}

import '../../domain/repositories/settings_repository.dart';
import '../datasources/local/settings_local_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource _localDataSource;

  SettingsRepositoryImpl({SettingsLocalDataSource? localDataSource})
      : _localDataSource = localDataSource ?? SettingsLocalDataSourceImpl();

  @override
  Future<String?> getSetting(String key) async {
    return await _localDataSource.getSetting(key);
  }

  @override
  Future<void> setSetting(String key, String value) async {
    await _localDataSource.setSetting(key, value);
  }

  @override
  Future<Map<String, String>> getAllSettings() async {
    return await _localDataSource.getAllSettings();
  }

  @override
  Future<void> deleteSetting(String key) async {
    await _localDataSource.deleteSetting(key);
  }
}

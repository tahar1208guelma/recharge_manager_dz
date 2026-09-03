abstract class SettingsRepository {
  Future<String?> getSetting(String key);
  Future<void> setSetting(String key, String value);
  Future<Map<String, String>> getAllSettings();
  Future<void> deleteSetting(String key);
}

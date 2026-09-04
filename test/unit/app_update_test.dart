import 'package:flutter_test/flutter_test.dart';
import 'package:recharge_manager_dz/services/updater/app_update_service.dart';

void main() {
  group('AppUpdateService Tests', () {
    test('Should check current version string', () {
      expect(AppUpdateService.currentAppVersion, '1.0.0');
      expect(AppUpdateService.githubRepo, 'tahar1208guelma/recharge_manager_dz');
    });

    test('Check for updates returns valid AppUpdateInfo structure', () async {
      final info = await AppUpdateService.checkForUpdates();
      expect(info.currentVersion, '1.0.0');
      expect(info.latestVersion.isNotEmpty, true);
    });
  });
}

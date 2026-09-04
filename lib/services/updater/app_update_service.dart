import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/utils/app_logger.dart';

class AppUpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final bool hasUpdate;
  final String releaseNotes;
  final String? downloadUrl;
  final String? publishedAt;
  final String tagName;

  AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.hasUpdate,
    required this.releaseNotes,
    this.downloadUrl,
    this.publishedAt,
    required this.tagName,
  });
}

class AppUpdateService {
  static const String currentAppVersion = '1.0.0';
  static const String githubRepo = 'tahar1208guelma/recharge_manager_dz';

  /// Checks GitHub Releases API for new versions tailored to the current platform
  static Future<AppUpdateInfo> checkForUpdates() async {
    AppLogger.info('Checking for software updates from GitHub Releases (Platform: ${kIsWeb ? 'Web' : Platform.operatingSystem})...');

    try {
      final url = Uri.parse('https://api.github.com/repos/$githubRepo/releases/latest');
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'RechargeManagerDZ-App',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tagName = data['tag_name']?.toString() ?? '1.0.0';
        final cleanLatest = tagName.replaceAll(RegExp(r'[^0-9.]'), '');
        final body = data['body']?.toString() ?? 'تحسينات عامة وإصلاحات برمجية.';
        final publishedAt = data['published_at']?.toString();

        String? downloadUrl;
        final assets = data['assets'] as List<dynamic>?;

        if (assets != null && assets.isNotEmpty) {
          // Detect platform-specific file extension
          String targetExt = '.exe';
          if (!kIsWeb) {
            if (Platform.isAndroid) {
              targetExt = '.apk';
            } else if (Platform.isMacOS) {
              targetExt = 'macos';
            } else if (Platform.isWindows) {
              targetExt = '.exe';
            }
          }

          for (final asset in assets) {
            final name = asset['name']?.toString().toLowerCase() ?? '';
            if (name.contains(targetExt) || name.endsWith(targetExt)) {
              downloadUrl = asset['browser_download_url']?.toString();
              break;
            }
          }

          // Fallback to first available asset if specific extension not matched
          if (downloadUrl == null && assets.isNotEmpty) {
            downloadUrl = assets.first['browser_download_url']?.toString();
          }
        }

        downloadUrl ??= data['html_url']?.toString();
        final hasUpdate = _isVersionNewer(cleanLatest, currentAppVersion);

        return AppUpdateInfo(
          currentVersion: currentAppVersion,
          latestVersion: cleanLatest.isNotEmpty ? cleanLatest : currentAppVersion,
          hasUpdate: hasUpdate,
          releaseNotes: body,
          downloadUrl: downloadUrl,
          publishedAt: publishedAt,
          tagName: tagName,
        );
      } else {
        AppLogger.warn('GitHub API returned status ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.warn('Error checking for updates: $e');
    }

    // Fallback response when no network or no release yet
    return AppUpdateInfo(
      currentVersion: currentAppVersion,
      latestVersion: currentAppVersion,
      hasUpdate: false,
      releaseNotes: 'أنت تستخدم أحدث إصدار متوفر حالياً.',
      tagName: 'v$currentAppVersion',
    );
  }

  /// Compares semantic versions (e.g. 1.0.1 > 1.0.0)
  static bool _isVersionNewer(String latest, String current) {
    try {
      final latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (int i = 0; i < latestParts.length && i < currentParts.length; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return latestParts.length > currentParts.length;
    } catch (_) {
      return false;
    }
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

class AppUpdateInfo {
  final bool hasUpdate;
  final bool isForceUpdate;
  final String latestVersion;
  final int latestBuildNumber;
  final String downloadUrl;
  final String releaseTitle;
  final String releaseNotes;

  AppUpdateInfo({
    required this.hasUpdate,
    required this.isForceUpdate,
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.downloadUrl,
    required this.releaseTitle,
    required this.releaseNotes,
  });

  factory AppUpdateInfo.noUpdate() {
    return AppUpdateInfo(
      hasUpdate: false,
      isForceUpdate: false,
      latestVersion: AppConstants.appVersion,
      latestBuildNumber: AppConstants.appBuildNumber,
      downloadUrl: '',
      releaseTitle: '',
      releaseNotes: '',
    );
  }
}

class UpdateService {
  final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 4);

  /// Check server or GitHub for updates
  Future<AppUpdateInfo> checkForUpdate() async {
    try {
      // 1. Check Primary Server API
      final serverInfo = await _checkServerApi();
      if (serverInfo != null) {
        return serverInfo;
      }
    } catch (e) {
      debugPrint('Primary server update check failed: $e');
    }

    try {
      // 2. Fallback: Check GitHub Releases API
      final githubInfo = await _checkGitHubReleases();
      if (githubInfo != null) {
        return githubInfo;
      }
    } catch (e) {
      debugPrint('GitHub release update check failed: $e');
    }

    return AppUpdateInfo.noUpdate();
  }

  Future<AppUpdateInfo?> _checkServerApi() async {
    final uri = Uri.parse(AppConstants.versionCheckUrl);
    final request = await _client.getUrl(uri);
    request.headers.set(HttpHeaders.userAgentHeader, AppConstants.customUserAgent);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');

    final response = await request.close().timeout(const Duration(seconds: 4));
    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      final data = jsonDecode(responseBody) as Map<String, dynamic>;

      final latestBuild = data['latest_build_number'] as int? ?? 0;
      final minRequiredBuild = data['min_required_build_number'] as int? ?? 0;
      final latestVersion = data['latest_version'] as String? ?? '1.0.0';
      final forceUpdate = data['force_update'] as bool? ?? (AppConstants.appBuildNumber < minRequiredBuild);
      final downloadUrl = data['download_url'] as String? ?? AppConstants.fallbackApkDownloadUrl;
      final title = data['release_title'] as String? ?? 'تحديث جديد متوفر للتطبيق';
      final notes = data['release_notes'] as String? ?? 'يتوفر إصدار جديد يحتوي على تحسينات أداء وإصلاحات مهمة.';

      final bool hasUpdate = latestBuild > AppConstants.appBuildNumber ||
          _isVersionGreater(latestVersion, AppConstants.appVersion);

      return AppUpdateInfo(
        hasUpdate: hasUpdate,
        isForceUpdate: forceUpdate && hasUpdate,
        latestVersion: latestVersion,
        latestBuildNumber: latestBuild,
        downloadUrl: downloadUrl,
        releaseTitle: title,
        releaseNotes: notes,
      );
    }
    return null;
  }

  Future<AppUpdateInfo?> _checkGitHubReleases() async {
    final uri = Uri.parse(AppConstants.githubLatestReleaseApi);
    final request = await _client.getUrl(uri);
    request.headers.set(HttpHeaders.userAgentHeader, AppConstants.customUserAgent);
    request.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github.v3+json');

    final response = await request.close().timeout(const Duration(seconds: 4));
    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      final data = jsonDecode(responseBody) as Map<String, dynamic>;

      final tagName = data['tag_name'] as String? ?? '';
      final cleanVersion = tagName.replaceAll('v', '').trim();
      final assets = data['assets'] as List<dynamic>? ?? [];

      String downloadUrl = AppConstants.fallbackApkDownloadUrl;
      for (final asset in assets) {
        final name = asset['name'] as String? ?? '';
        if (name.endsWith('.apk')) {
          downloadUrl = asset['browser_download_url'] as String? ?? downloadUrl;
          break;
        }
      }

      final notes = data['body'] as String? ?? 'تحسينات عامة واستقرار أكبر للنظام الميداني.';
      final hasUpdate = _isVersionGreater(cleanVersion, AppConstants.appVersion);

      return AppUpdateInfo(
        hasUpdate: hasUpdate,
        isForceUpdate: hasUpdate,
        latestVersion: cleanVersion,
        latestBuildNumber: AppConstants.appBuildNumber + (hasUpdate ? 1 : 0),
        downloadUrl: downloadUrl,
        releaseTitle: 'تحديث جديد متوفر: $tagName',
        releaseNotes: notes,
      );
    }
    return null;
  }

  bool _isVersionGreater(String newVersion, String currentVersion) {
    try {
      final newParts = newVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final curParts = currentVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      while (newParts.length < 3) {
        newParts.add(0);
      }
      while (curParts.length < 3) {
        curParts.add(0);
      }

      for (int i = 0; i < 3; i++) {
        if (newParts[i] > curParts[i]) return true;
        if (newParts[i] < curParts[i]) return false;
      }
    } catch (_) {}
    return false;
  }
}

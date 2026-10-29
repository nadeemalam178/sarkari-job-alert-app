import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class OtaUpdateInfo {
  final bool hasUpdate;
  final String latestVersion;
  final String currentVersion;
  final String downloadUrl;
  final String releaseNotes;
  final int downloadSizeBytes;

  const OtaUpdateInfo({
    required this.hasUpdate,
    required this.latestVersion,
    required this.currentVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.downloadSizeBytes,
  });
}

class OtaUpdateService {
  static const String currentVersion = '2.2.0';
  static const String githubRepo = 'nadeemalam178/sarkari-job-alert-app';

  /// Check GitHub Releases API for over-the-air updates
  static Future<OtaUpdateInfo?> checkForUpdate() async {
    try {
      final uri = Uri.parse('https://api.github.com/repos/$githubRepo/releases/latest');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final tagName = (data['tag_name'] as String? ?? '').replaceFirst('v', '');
        final body = data['body'] as String? ?? 'Latest recruitment engine & performance improvements.';
        final assets = data['assets'] as List? ?? [];

        String downloadUrl = data['html_url'] ?? 'https://github.com/$githubRepo/releases/latest';
        int sizeBytes = 0;

        // Find architecture-optimized or named release APK
        for (final asset in assets) {
          final name = (asset['name'] as String? ?? '').toLowerCase();
          if (name.contains('arm64') || name.contains('sarkarijobalert') || name.endsWith('.apk')) {
            downloadUrl = asset['browser_download_url'] ?? downloadUrl;
            sizeBytes = asset['size'] ?? 0;
            break;
          }
        }

        final hasUpdate = _isNewerVersion(currentVersion, tagName);
        return OtaUpdateInfo(
          hasUpdate: hasUpdate,
          latestVersion: tagName,
          currentVersion: currentVersion,
          downloadUrl: downloadUrl,
          releaseNotes: body,
          downloadSizeBytes: sizeBytes,
        );
      }
    } catch (e) {
      debugPrint('OtaUpdateService check error: $e');
    }
    return null;
  }

  static bool _isNewerVersion(String current, String remote) {
    if (remote.isEmpty) return false;
    final currParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final remParts = remote.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      final c = i < currParts.length ? currParts[i] : 0;
      final r = i < remParts.length ? remParts[i] : 0;
      if (r > c) return true;
      if (r < c) return false;
    }
    return false;
  }

  static Future<void> launchDownload(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

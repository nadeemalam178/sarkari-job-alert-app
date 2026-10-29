import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
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

typedef DownloadProgressCallback = void Function(int receivedBytes, int totalBytes, double progress);

class OtaUpdateService {
  static const String currentVersion = '2.3.1';
  static const String githubRepo = 'nadeemalam178/sarkari-job-alert-app';
  static const MethodChannel _otaChannel = MethodChannel('com.sarkari.jobalert/ota');

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

        // Find architecture-optimized or named release APK (prefer arm64-v8a for modern Android)
        for (final asset in assets) {
          final name = (asset['name'] as String? ?? '').toLowerCase();
          if (name.contains('arm64-v8a') || name.contains('arm64')) {
            downloadUrl = asset['browser_download_url'] ?? downloadUrl;
            sizeBytes = asset['size'] ?? 0;
            break;
          }
        }

        // If arm64 was not found, search for any APK asset
        if (sizeBytes == 0) {
          for (final asset in assets) {
            final name = (asset['name'] as String? ?? '').toLowerCase();
            if (name.endsWith('.apk')) {
              downloadUrl = asset['browser_download_url'] ?? downloadUrl;
              sizeBytes = asset['size'] ?? 0;
              break;
            }
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

  /// In-app direct background stream downloader with live progress callbacks
  static Future<File?> downloadApk(
    String url, {
    DownloadProgressCallback? onProgress,
  }) async {
    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      if (response.statusCode != 200 && response.statusCode != 302) {
        debugPrint('Failed to download APK: status ${response.statusCode}');
        return null;
      }

      // Handle redirect if any
      Uri targetUri = Uri.parse(url);
      if (response.isRedirect || response.statusCode == 302) {
        final location = response.headers['location'];
        if (location != null) targetUri = Uri.parse(location);
      }

      final streamRes = response.statusCode == 302
          ? await client.send(http.Request('GET', targetUri))
          : response;

      final totalBytes = streamRes.contentLength ?? 0;
      int receivedBytes = 0;

      final tempDir = await getTemporaryDirectory();
      final apkFile = File('${tempDir.path}/SarkariJobAlert-update.apk');
      if (await apkFile.exists()) {
        await apkFile.delete();
      }

      final sink = apkFile.openWrite();

      await for (final chunk in streamRes.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0 && onProgress != null) {
          final progress = (receivedBytes / totalBytes).clamp(0.0, 1.0);
          onProgress(receivedBytes, totalBytes, progress);
        }
      }

      await sink.flush();
      await sink.close();
      client.close();

      return apkFile;
    } catch (e) {
      debugPrint('Error downloading APK: $e');
      return null;
    }
  }

  /// Launch native Android package installer
  static Future<bool> installApk(String filePath) async {
    try {
      final result = await _otaChannel.invokeMethod<bool>('installApk', {'filePath': filePath});
      return result ?? false;
    } catch (e) {
      debugPrint('Native installApk error: $e');
      return false;
    }
  }

  /// Fallback external browser opener
  static Future<void> launchDownload(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

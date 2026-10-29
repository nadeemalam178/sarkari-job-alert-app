import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NotificationService {
  static const MethodChannel _channel = MethodChannel('com.sarkari.jobalert/notifications');

  /// Request runtime POST_NOTIFICATIONS permission on Android 13+
  static Future<bool> requestPermission() async {
    if (kIsWeb) return true;
    try {
      final bool? granted = await _channel.invokeMethod<bool>('requestNotificationPermission');
      return granted ?? true;
    } catch (e) {
      debugPrint('NotificationService requestPermission error: $e');
      return false;
    }
  }

  /// Check whether notification permission is active
  static Future<bool> checkPermission() async {
    if (kIsWeb) return true;
    try {
      final bool? granted = await _channel.invokeMethod<bool>('checkNotificationPermission');
      return granted ?? true;
    } catch (e) {
      debugPrint('NotificationService checkPermission error: $e');
      return true;
    }
  }
}

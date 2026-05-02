import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  PermissionService._();

  /// Request all essential permissions for the app.
  /// Call this on app startup (after splash) or before features that need them.
  static Future<void> requestEssentialPermissions() async {
    // Only request on mobile platforms
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    final permissions = <Permission>[
      Permission.camera,
      Permission.location,
      Permission.storage,
      Permission.photos,
    ];

    // Request all at once
    final statuses = await permissions.request();

    for (final entry in statuses.entries) {
      debugPrint('Permission ${entry.key}: ${entry.value}');
    }
  }

  /// Check and request camera permission specifically
  static Future<bool> ensureCamera() async {
    var status = await Permission.camera.status;
    if (status.isGranted) return true;
    status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Check and request location permission specifically
  static Future<bool> ensureLocation() async {
    var status = await Permission.location.status;
    if (status.isGranted) return true;
    status = await Permission.location.request();
    return status.isGranted;
  }

  /// Check and request storage permission specifically
  static Future<bool> ensureStorage() async {
    var status = await Permission.storage.status;
    if (status.isGranted) return true;
    status = await Permission.storage.request();
    return status.isGranted;
  }
}

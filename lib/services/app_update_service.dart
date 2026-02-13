import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

class AppUpdateService {
  /// Checks if an update is available on the Play Store.
  /// Returns the [AppUpdateInfo] if an update is available, null otherwise.
  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      if (updateInfo.updateAvailability ==
          UpdateAvailability.updateAvailable) {
        return updateInfo;
      }
      return null;
    } catch (e) {
      debugPrint('AppUpdateService: Error checking for update: $e');
      return null;
    }
  }

  /// Starts an immediate (full-screen) update flow.
  /// The Play Store handles the entire UX.
  Future<void> performImmediateUpdate() async {
    try {
      await InAppUpdate.performImmediateUpdate();
    } catch (e) {
      debugPrint('AppUpdateService: Error performing immediate update: $e');
    }
  }

  /// Starts a flexible (background download) update flow.
  Future<void> startFlexibleUpdate() async {
    try {
      await InAppUpdate.startFlexibleUpdate();
    } catch (e) {
      debugPrint('AppUpdateService: Error starting flexible update: $e');
    }
  }

  /// Completes a flexible update (installs after download).
  Future<void> completeFlexibleUpdate() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } catch (e) {
      debugPrint('AppUpdateService: Error completing flexible update: $e');
    }
  }
}

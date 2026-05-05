import 'package:myrandomlibrary/l10n/app_localizations.dart';

/// Helper class to map database status values to user-friendly display labels
class StatusHelper {
  /// Map database status value to user-friendly display label (English fallback)
  static String getDisplayLabel(String dbValue) {
    final lowerValue = dbValue.toLowerCase();

    switch (lowerValue) {
      case 'yes':
        return 'Read';
      case 'no':
        return 'Not Read';
      case 'tbreleased':
        return 'TBReleased';
      case 'repeated':
        return 'Repeated';
      case 'started':
        return 'Started';
      case 'abandoned':
        return 'Abandoned / DNF';
      case 'standby':
        return 'Standby';
      default:
        // Return original value with first letter capitalized for unknown values
        return dbValue.isEmpty
            ? dbValue
            : dbValue[0].toUpperCase() + dbValue.substring(1);
    }
  }

  /// Map database status value to a localized display label
  static String getLocalizedLabel(String dbValue, AppLocalizations l10n) {
    final lowerValue = dbValue.toLowerCase();

    switch (lowerValue) {
      case 'yes':
        return l10n.status_label_yes;
      case 'no':
        return l10n.status_label_no;
      case 'started':
        return l10n.status_label_started;
      case 'tbreleased':
        return l10n.status_label_tbreleased;
      case 'repeated':
        return l10n.status_label_repeated;
      case 'abandoned':
        return l10n.status_label_abandoned;
      case 'standby':
        return l10n.status_label_standby;
      default:
        return dbValue.isEmpty
            ? dbValue
            : dbValue[0].toUpperCase() + dbValue.substring(1);
    }
  }

  /// Get all common status values with their display labels
  static Map<String, String> getAllStatusMappings() {
    return {
      'yes': 'Read',
      'no': 'Not Read',
      'tbreleased': 'TBReleased',
      'repeated': 'Repeated',
      'started': 'Started',
      'abandoned': 'Abandoned / DNF',
    };
  }
}

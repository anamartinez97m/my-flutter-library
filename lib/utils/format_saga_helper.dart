import 'package:myrandomlibrary/l10n/app_localizations.dart';

/// Helper class to map database format_saga values to localized display labels
class FormatSagaHelper {
  /// Map database format_saga value to a localized display label
  static String getLocalizedLabel(String dbValue, AppLocalizations l10n) {
    final lowerValue = dbValue.toLowerCase();

    switch (lowerValue) {
      case 'standalone':
        return l10n.format_saga_label_standalone;
      case 'bilogy':
        return l10n.format_saga_label_bilogy;
      case 'trilogy':
        return l10n.format_saga_label_trilogy;
      case 'tetralogy':
        return l10n.format_saga_label_tetralogy;
      case 'pentalogy':
        return l10n.format_saga_label_pentalogy;
      case 'hexalogy':
        return l10n.format_saga_label_hexalogy;
      case 'saga':
        return l10n.format_saga_label_saga;
      default:
        return dbValue.isEmpty
            ? dbValue
            : dbValue[0].toUpperCase() + dbValue.substring(1);
    }
  }
}

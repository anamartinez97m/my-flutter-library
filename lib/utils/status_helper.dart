/// Helper class to map database status values to user-friendly display labels
class StatusHelper {
  /// Map database status value to user-friendly display label
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
      default:
        // Return original value with first letter capitalized for unknown values
        return dbValue.isEmpty ? dbValue : dbValue[0].toUpperCase() + dbValue.substring(1);
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

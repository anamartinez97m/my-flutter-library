/// Format date string to dd-mmm-yyyy format for display
/// Input should be in yyyy-mm-dd format
String formatDateForDisplay(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '';
  
  try {
    // Parse the date (handles yyyy-mm-dd format)
    final date = DateTime.parse(dateStr);
    
    // Month abbreviations
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year;
    
    return '$day-$month-$year';
  } catch (e) {
    // If parsing fails, return the original string
    return dateStr;
  }
}

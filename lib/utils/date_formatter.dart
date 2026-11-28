import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum WeekStart { monday, sunday }

/// User preferences for how dates are shown and which day calendars start on.
class DateDisplaySettings extends ChangeNotifier {
  DateDisplaySettings._();

  static final DateDisplaySettings instance = DateDisplaySettings._();

  static const String formatKey = 'date_display_format';
  static const String weekStartKey = 'week_start';

  /// `intl` patterns offered in Settings.
  static const List<String> patterns = [
    'dd/MM/yyyy',
    'MM/dd/yyyy',
    'yyyy/MM/dd',
    'dd/MMM/yyyy',
    'MMM/dd/yyyy',
    'yyyy/MMM/dd',
    'dd/MMMM/yyyy',
    'MMMM/dd/yyyy',
    'yyyy/MMMM/dd',
    'dd-MM-yyyy',
    'MM-dd-yyyy',
    'yyyy-MM-dd',
    'dd-MMM-yyyy',
    'MMM-dd-yyyy',
    'yyyy-MMM-dd',
    'dd-MMMM-yyyy',
    'MMMM-dd-yyyy',
    'yyyy-MMMM-dd',
  ];

  static const String defaultPattern = 'dd/MM/yyyy';
  static const WeekStart defaultWeekStart = WeekStart.monday;

  /// `DD/MMM/YYYY` style label for a pattern.
  static String labelFor(String pattern) => pattern.toUpperCase();

  String _pattern = defaultPattern;
  WeekStart _weekStart = defaultWeekStart;

  /// Language used for month names; kept in sync with the app locale.
  String? locale;

  String get pattern => _pattern;
  WeekStart get weekStart => _weekStart;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final storedPattern = prefs.getString(formatKey);
    _pattern =
        patterns.contains(storedPattern) ? storedPattern! : defaultPattern;
    _weekStart =
        prefs.getString(weekStartKey) == WeekStart.sunday.name
            ? WeekStart.sunday
            : WeekStart.monday;
    notifyListeners();
  }

  Future<void> setPattern(String pattern) async {
    if (!patterns.contains(pattern) || pattern == _pattern) return;
    _pattern = pattern;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(formatKey, pattern);
  }

  Future<void> setWeekStart(WeekStart weekStart) async {
    if (weekStart == _weekStart) return;
    _weekStart = weekStart;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(weekStartKey, weekStart.name);
  }

  String format(DateTime date, {String? pattern}) {
    final p = pattern ?? _pattern;
    try {
      return DateFormat(p, locale).format(date);
    } catch (_) {
      // Locale date data not loaded yet: fall back to the default locale.
      return DateFormat(p).format(date);
    }
  }
}

/// [date] in the user's chosen format.
String formatDate(DateTime date) => DateDisplaySettings.instance.format(date);

/// [date] in the user's chosen format followed by `HH:mm`.
String formatDateTime(DateTime date) =>
    '${formatDate(date)} ${DateFormat.Hm().format(date)}';

/// Formats a stored date string (`yyyy-mm-dd`, full ISO, `yyyy-mm` or `yyyy`)
/// with the user's chosen format. Unparseable values are returned unchanged.
String formatDateForDisplay(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '';
  final trimmed = dateStr.trim();
  if (RegExp(r'^\d{4}$').hasMatch(trimmed)) return trimmed;
  final yearMonth = RegExp(r'^(\d{4})-(\d{1,2})$').firstMatch(trimmed);
  if (yearMonth != null) {
    final date = DateTime(
      int.parse(yearMonth.group(1)!),
      int.parse(yearMonth.group(2)!),
    );
    try {
      return DateFormat.yMMMM(DateDisplaySettings.instance.locale).format(date);
    } catch (_) {
      return trimmed;
    }
  }
  final date = DateTime.tryParse(trimmed);
  return date == null ? dateStr : formatDate(date);
}

/// Like [formatDateForDisplay] but keeps the time of full timestamps.
String formatDateTimeForDisplay(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '';
  final date = DateTime.tryParse(dateStr.trim());
  return date == null ? dateStr : formatDateTime(date);
}

/// Material localizations that start calendars on the user's chosen day.
///
/// `GlobalMaterialLocalizations.firstDayOfWeekIndex` reads the locale's intl
/// date symbols, so the chosen day is written there after the base load.
/// Reloads whenever the week start or date format changes, which also
/// rebuilds every widget that reads localizations (and shows dates).
class DateSettingsMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const DateSettingsMaterialLocalizationsDelegate({
    required this.weekStart,
    required this.pattern,
  });

  final WeekStart weekStart;
  final String pattern;

  @override
  bool isSupported(Locale locale) =>
      GlobalMaterialLocalizations.delegate.isSupported(locale);

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    return GlobalMaterialLocalizations.delegate.load(locale).then((
      localizations,
    ) {
      applyWeekStart(locale, weekStart);
      return localizations;
    });
  }

  @override
  bool shouldReload(DateSettingsMaterialLocalizationsDelegate old) =>
      old.weekStart != weekStart || old.pattern != pattern;
}

/// Sets the first day of the week used by intl (and Material calendars) for
/// [locale]. Must run after the locale's date data is loaded.
@visibleForTesting
void applyWeekStart(Locale locale, WeekStart weekStart) {
  // intl counts from Monday = 0, so Sunday = 6.
  final firstDay = weekStart == WeekStart.monday ? 0 : 6;
  for (final name in {
    Intl.canonicalizedLocale(locale.toString()),
    locale.languageCode,
  }) {
    if (DateFormat.localeExists(name)) {
      DateFormat.yMMMMEEEEd(name).dateSymbols.FIRSTDAYOFWEEK = firstDay;
    }
  }
}

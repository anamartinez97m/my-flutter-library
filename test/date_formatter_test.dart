import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myrandomlibrary/utils/date_formatter.dart';
import 'package:myrandomlibrary/utils/publication_date.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<MaterialLocalizations> pumpWith(
  WidgetTester tester, {
  required Locale locale,
  required WeekStart weekStart,
  String pattern = DateDisplaySettings.defaultPattern,
}) async {
  late MaterialLocalizations result;
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('es')],
      localizationsDelegates: [
        DateSettingsMaterialLocalizationsDelegate(
          weekStart: weekStart,
          pattern: pattern,
        ),
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(
        builder: (context) {
          result = MaterialLocalizations.of(context);
          return const SizedBox();
        },
      ),
    ),
  );
  return result;
}

void main() {
  final settings = DateDisplaySettings.instance;
  final date = DateTime(2026, 3, 7, 9, 5);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await settings.load();
    settings.locale = 'en';
  });

  testWidgets('week start applies to Material calendars', (tester) async {
    for (final locale in const [Locale('en'), Locale('es')]) {
      var l10n = await pumpWith(
        tester,
        locale: locale,
        weekStart: WeekStart.monday,
      );
      expect(l10n.firstDayOfWeekIndex, 1, reason: '$locale monday');
      l10n = await pumpWith(
        tester,
        locale: locale,
        weekStart: WeekStart.sunday,
      );
      expect(l10n.firstDayOfWeekIndex, 0, reason: '$locale sunday');
    }
  });

  testWidgets('every pattern formats with localized months', (tester) async {
    await pumpWith(
      tester,
      locale: const Locale('es'),
      weekStart: WeekStart.monday,
    );
    expect(DateDisplaySettings.patterns, hasLength(18));
    final expectedEn = {
      'dd/MM/yyyy': '07/03/2026',
      'MM/dd/yyyy': '03/07/2026',
      'yyyy/MM/dd': '2026/03/07',
      'dd/MMM/yyyy': '07/Mar/2026',
      'MMM/dd/yyyy': 'Mar/07/2026',
      'yyyy/MMM/dd': '2026/Mar/07',
      'dd/MMMM/yyyy': '07/March/2026',
      'MMMM/dd/yyyy': 'March/07/2026',
      'yyyy/MMMM/dd': '2026/March/07',
      'dd-MM-yyyy': '07-03-2026',
      'MM-dd-yyyy': '03-07-2026',
      'yyyy-MM-dd': '2026-03-07',
      'dd-MMM-yyyy': '07-Mar-2026',
      'MMM-dd-yyyy': 'Mar-07-2026',
      'yyyy-MMM-dd': '2026-Mar-07',
      'dd-MMMM-yyyy': '07-March-2026',
      'MMMM-dd-yyyy': 'March-07-2026',
      'yyyy-MMMM-dd': '2026-March-07',
    };
    for (final entry in expectedEn.entries) {
      expect(settings.format(date, pattern: entry.key), entry.value);
    }
    settings.locale = 'es';
    expect(settings.format(date, pattern: 'dd/MMMM/yyyy'), '07/marzo/2026');
    expect(DateDisplaySettings.labelFor('MMM-dd-yyyy'), 'MMM-DD-YYYY');
  });

  testWidgets('stored dates use the chosen format', (tester) async {
    await pumpWith(
      tester,
      locale: const Locale('en'),
      weekStart: WeekStart.monday,
    );
    await settings.setPattern('yyyy-MMM-dd');
    expect(formatDateForDisplay('2026-03-07'), '2026-Mar-07');
    expect(formatDateForDisplay('2026-03-07T00:00:00.000'), '2026-Mar-07');
    expect(formatDateForDisplay('2026'), '2026');
    expect(formatDateForDisplay('2026-03'), 'March 2026');
    expect(formatDateForDisplay('not a date'), 'not a date');
    expect(formatDateTime(date), '2026-Mar-07 09:05');
    expect(PublicationDate(2026, month: 3, day: 7).format('en'), '2026-Mar-07');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(DateDisplaySettings.formatKey), 'yyyy-MMM-dd');
    await settings.setWeekStart(WeekStart.sunday);
    expect(prefs.getString(DateDisplaySettings.weekStartKey), 'sunday');
    await settings.load();
    expect(settings.pattern, 'yyyy-MMM-dd');
    expect(settings.weekStart, WeekStart.sunday);
  });
}

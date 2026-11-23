import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/widgets/publication_date_fields.dart';

class _Harness {
  final year = TextEditingController();
  int? month;
  int? day;

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: StatefulBuilder(
          builder:
              (context, setState) => PublicationDateFields(
                yearController: year,
                month: month,
                day: day,
                decoration:
                    (label, icon) => InputDecoration(
                      labelText: label,
                      prefixIcon: Icon(icon),
                    ),
                onChanged:
                    (m, d) => setState(() {
                      month = m;
                      day = d;
                    }),
              ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('starts in Year mode and shows the year hint', (tester) async {
    final h = _Harness();
    await h.pump(tester);

    expect(find.byType(TextFormField), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '2026');
    await tester.pump();
    expect(find.text('Shown as "2026". Type the year.'), findsOneWidget);
  });

  testWidgets('opens in Day mode when the exact day is known', (tester) async {
    final h =
        _Harness()
          ..year.text = '2026'
          ..month = 11
          ..day = 24;
    await h.pump(tester);

    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('24/11/2026'), findsOneWidget);
  });

  testWidgets('switching to Year drops the month and day', (tester) async {
    final h =
        _Harness()
          ..year.text = '2026'
          ..month = 11
          ..day = 24;
    await h.pump(tester);

    await tester.tap(find.text('Year'));
    await tester.pumpAndSettle();

    expect(h.month, isNull);
    expect(h.day, isNull);
    expect(h.year.text, '2026');
  });

  testWidgets('Month mode picks a month and year', (tester) async {
    final h = _Harness()..year.text = '2026';
    await h.pump(tester);

    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select month'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.tap(find.text('Mar'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(h.year.text, '2027');
    expect(h.month, 3);
    expect(h.day, isNull);
    expect(find.text('March 2027'), findsWidgets);
  });
}

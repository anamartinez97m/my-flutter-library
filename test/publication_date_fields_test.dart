import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/widgets/publication_date_fields.dart';

void main() {
  testWidgets('month and day stay disabled until a year is entered', (
    tester,
  ) async {
    final year = TextEditingController();
    int? month;
    int? day;
    late StateSetter rebuild;

    await tester.pumpWidget(
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
            builder: (context, setState) {
              rebuild = setState;
              return PublicationDateFields(
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
              );
            },
          ),
        ),
      ),
    );

    DropdownButton<int?> dropdown(int index) => tester
        .widgetList<DropdownButton<int?>>(find.byType(DropdownButton<int?>))
        .elementAt(index);

    expect(dropdown(0).onChanged, isNull);
    expect(dropdown(1).onChanged, isNull);

    await tester.enterText(find.byType(TextFormField).first, '2024');
    await tester.pump();
    expect(dropdown(0).onChanged, isNotNull);
    expect(dropdown(1).onChanged, isNull);

    await tester.tap(find.byType(DropdownButton<int?>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('February').last);
    await tester.pumpAndSettle();
    expect(month, 2);
    expect(dropdown(1).onChanged, isNotNull);
    expect(dropdown(1).items!.length, 30); // "—" + 29 days in Feb 2024

    rebuild(() => day = 29);
    await tester.pump();
    expect(dropdown(1).value, 29);

    await tester.enterText(find.byType(TextFormField).first, '2023');
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(dropdown(1).value, isNull);
  });
}

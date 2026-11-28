import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/utils/home_widget_snapshot.dart';

Book _book({
  int? progress,
  String? type,
  int? pages,
  String? saga,
  String? nSaga,
}) => Book.fromMap({
  'book_id': 1,
  'name': 'The Name of the Wind',
  'author': 'Patrick Rothfuss',
  'saga': saga,
  'n_saga': nSaga,
  'pages': pages,
  'reading_progress': progress,
  'progress_type': type,
});

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  test('pages progress with saga and time left', () {
    final s = HomeWidgetSnapshot.fromBook(
      _book(
        progress: 290,
        type: 'pages',
        pages: 662,
        saga: 'Kingkiller',
        nSaga: '1',
      ),
      timedSeconds: 4 * 3600,
      l10n: l10n,
    );
    expect(s.subtitle, 'Patrick Rothfuss · Kingkiller #1');
    expect(s.progressText, 'p. 290 / 662');
    expect(s.percent, 44);
    expect(s.remaining, '~5 h 10 min left');
  });

  test('percentage progress shows only the percent', () {
    final s = HomeWidgetSnapshot.fromBook(
      _book(progress: 75, type: 'percentage'),
      timedSeconds: 1800,
      l10n: l10n,
    );
    expect(s.subtitle, 'Patrick Rothfuss');
    expect(s.progressText, '');
    expect(s.percent, 75);
    expect(s.remaining, '~10 min left');
  });

  test('pages without a total has no bar and no time left', () {
    final s = HomeWidgetSnapshot.fromBook(
      _book(progress: 40, type: 'pages'),
      timedSeconds: 3600,
      l10n: l10n,
    );
    expect(s.progressText, 'p. 40');
    expect(s.percent, -1);
    expect(s.remaining, '');
  });

  test('no time left without timed sessions or progress', () {
    expect(HomeWidgetSnapshot.timeLeftLabel(0.5, 0, l10n), '');
    expect(HomeWidgetSnapshot.timeLeftLabel(0, 3600, l10n), '');
    expect(HomeWidgetSnapshot.timeLeftLabel(0.05, 3600, l10n), '~19 h left');
  });
}

import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/model/user_list.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/repositories/reading_club_repository.dart';
import 'package:myrandomlibrary/repositories/user_list_repository.dart';
import 'package:sqflite/sqflite.dart';

/// Fields the Library Tools (Assign Books to Value, Fill Empty Fields, Smart
/// Suggestions) know how to read and write.
class LibraryToolFields {
  const LibraryToolFields._();

  static const assignFields = [
    'genre',
    'author',
    'format',
    'language',
    'place',
    'editorial',
    'saga',
    'saga_universe',
    'format_saga',
    'reading_club',
    'user_list',
    'tbr',
    'loaned',
    'acquired_date',
  ];

  static const fillGroupFields = [
    'genre',
    'author',
    'format',
    'language',
    'place',
    'editorial',
    'saga_universe',
    'format_saga',
    'reading_club',
  ];

  /// Fields whose value differs for every book: filled by typing per book.
  static const fillPerBookFields = [
    'pages',
    'original_publication_year',
    'price',
    'acquired_date',
    'isbn',
    'asin',
  ];

  /// Fields picked with a search box that also accepts new values.
  static const freeTextFields = {
    'author',
    'saga',
    'saga_universe',
    'reading_club',
  };

  static const yesNoFields = {'tbr', 'loaned'};

  static String label(AppLocalizations l10n, String key) {
    switch (key) {
      case 'genre':
        return l10n.genre;
      case 'author':
        return l10n.author;
      case 'format':
        return l10n.format;
      case 'language':
        return l10n.language;
      case 'place':
        return l10n.place;
      case 'editorial':
        return l10n.editorial;
      case 'saga':
        return l10n.saga;
      case 'saga_universe':
        return l10n.saga_universe;
      case 'format_saga':
        return l10n.format_saga;
      case 'reading_club':
        return l10n.reading_club;
      case 'user_list':
        return l10n.book_list_field;
      case 'tbr':
        return l10n.tbr_label;
      case 'loaned':
        return l10n.loaned;
      case 'acquired_date':
        return l10n.acquired_date;
      case 'pages':
        return l10n.pages;
      case 'original_publication_year':
        return l10n.publication_year;
      case 'price':
        return l10n.price;
      case 'isbn':
        return l10n.isbn;
      case 'asin':
        return l10n.asin;
      default:
        return key;
    }
  }

  static IconData icon(String key) {
    switch (key) {
      case 'genre':
        return Icons.category;
      case 'author':
        return Icons.person_outline;
      case 'format':
        return Icons.book;
      case 'language':
        return Icons.language;
      case 'place':
        return Icons.place;
      case 'editorial':
        return Icons.business;
      case 'saga':
        return Icons.auto_stories_outlined;
      case 'saga_universe':
        return Icons.public;
      case 'format_saga':
        return Icons.collections_bookmark;
      case 'reading_club':
        return Icons.groups_outlined;
      case 'user_list':
        return Icons.format_list_bulleted;
      case 'tbr':
        return Icons.bookmark_add_outlined;
      case 'loaned':
        return Icons.swap_horiz;
      case 'acquired_date':
        return Icons.event_outlined;
      case 'pages':
        return Icons.description_outlined;
      case 'original_publication_year':
        return Icons.calendar_today_outlined;
      case 'price':
        return Icons.payments_outlined;
      case 'isbn':
      case 'asin':
        return Icons.qr_code_2;
      default:
        return Icons.label;
    }
  }

  /// The book's current value as shown to the user ('' when empty). Reading
  /// clubs and lists aren't part of [Book], so they return ''.
  static String bookValue(Book book, String key, {AppLocalizations? l10n}) {
    switch (key) {
      case 'genre':
        return book.genre ?? '';
      case 'author':
        return book.author ?? '';
      case 'format':
        return book.formatValue ?? '';
      case 'language':
        return book.languageValue ?? '';
      case 'place':
        return book.placeValue ?? '';
      case 'editorial':
        return book.editorialValue ?? '';
      case 'saga':
        return book.saga ?? '';
      case 'saga_universe':
        return book.sagaUniverse ?? '';
      case 'format_saga':
        return book.formatSagaValue ?? '';
      case 'tbr':
        if (l10n == null) return book.tbr == true ? 'yes' : 'no';
        return book.tbr == true ? l10n.yes : l10n.no;
      case 'loaned':
        final yes = book.loaned?.toLowerCase() == 'yes';
        if (l10n == null) return yes ? 'yes' : 'no';
        return yes ? l10n.yes : l10n.no;
      case 'acquired_date':
        return book.acquiredDate ?? '';
      default:
        return '';
    }
  }

  /// Values to choose from for [key]. Lists use the list id as value.
  static Future<List<FieldOption>> loadOptions(
    Database db,
    String key,
    AppLocalizations l10n,
  ) async {
    switch (key) {
      case 'reading_club':
        final names =
            <String>{
                ...await ReadingClubRepository(db).getAllClubNames(),
                for (final r in await db.rawQuery(
                  'SELECT DISTINCT club_name FROM reading_clubs',
                ))
                  r['club_name'] as String,
              }.toList()
              ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        return names.map((n) => FieldOption(n, n)).toList();
      case 'user_list':
        final lists = await UserListRepository(db).getLists();
        return lists
            .where((l) => l.type == UserListType.book && l.listId != null)
            .map((l) => FieldOption('${l.listId}', l.name))
            .toList();
      case 'tbr':
      case 'loaned':
        return [FieldOption('yes', l10n.yes), FieldOption('no', l10n.no)];
      case 'acquired_date':
        return [];
      default:
        final rows = await BookRepository(db).getLookupValues(key);
        final valueColumn =
            (key == 'format' || key == 'format_saga') ? 'value' : 'name';
        return rows
            .map((r) => r[valueColumn] as String?)
            .whereType<String>()
            .where((v) => v.trim().isNotEmpty)
            .map((v) => FieldOption(v, v))
            .toList();
    }
  }

  static final _acquiredDatePattern = RegExp(
    r'^\d{4}(-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01]))?$',
  );

  static bool isValidAcquiredDate(String value) =>
      _acquiredDatePattern.hasMatch(value.trim());

  /// Parses a per-book value typed by the user. Returns null when [text] is
  /// not a valid value for [key].
  static Object? parsePerBookValue(String key, String text) {
    final value = text.trim();
    if (value.isEmpty) return null;
    switch (key) {
      case 'pages':
        final pages = int.tryParse(value);
        return (pages != null && pages > 0) ? pages : null;
      case 'original_publication_year':
        if (!RegExp(r'^(\d{1,4}|\d{8})$').hasMatch(value)) return null;
        final year = int.parse(value);
        return year > 0 ? year : null;
      case 'price':
        final price = double.tryParse(value.replaceAll(',', '.'));
        return (price != null && price >= 0) ? price : null;
      case 'acquired_date':
        return isValidAcquiredDate(value) ? value : null;
      case 'isbn':
      case 'asin':
        return value;
      default:
        return null;
    }
  }
}

class FieldOption {
  final String value;
  final String label;

  const FieldOption(this.value, this.label);
}

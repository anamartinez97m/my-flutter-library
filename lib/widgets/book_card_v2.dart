import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/screens/new_ui/new_book_detail.dart';
import 'package:myrandomlibrary/utils/format_saga_helper.dart';
import 'package:myrandomlibrary/utils/status_helper.dart';

// ── v2 design tokens ─────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF43102B);
const _kText = Color(0xFF5F5E5C);
const _kBorder = Color(0xFFCEC5BE);
const _kDivider = Color(0xFFE6E2DF);

class _MetaItem {
  final IconData icon;
  final String text;
  final bool fullWidth;
  const _MetaItem({
    required this.icon,
    required this.text,
    this.fullWidth = false,
  });
}

/// Reusable v2 book card used across the redesigned screens.
class BookCardV2 extends StatelessWidget {
  final Book book;
  final Set<String> enabledCardFields;

  const BookCardV2({
    super.key,
    required this.book,
    required this.enabledCardFields,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRead =
        book.statusValue?.toLowerCase() == 'yes' ||
        book.statusValue?.toLowerCase() == 'repeated';

    final meta = <_MetaItem>[];
    if (enabledCardFields.contains('saga') &&
        book.saga != null &&
        book.saga!.isNotEmpty) {
      final label =
          '${book.saga}${book.nSaga != null && book.nSaga!.isNotEmpty ? " #${book.nSaga}" : ""}';
      meta.add(
        _MetaItem(
          icon: Icons.auto_stories_outlined,
          text: l10n.saga_with_colon(label),
          fullWidth: true,
        ),
      );
    }
    if (enabledCardFields.contains('saga_universe') &&
        book.sagaUniverse != null &&
        book.sagaUniverse!.isNotEmpty) {
      meta.add(
        _MetaItem(
          icon: Icons.public_outlined,
          text: '${l10n.saga_universe}: ${book.sagaUniverse}',
          fullWidth: true,
        ),
      );
    }
    if (enabledCardFields.contains('format') &&
        book.formatValue != null &&
        book.formatValue!.isNotEmpty) {
      meta.add(
        _MetaItem(
          icon: Icons.import_contacts_outlined,
          text: l10n.format_with_colon(book.formatValue!.toUpperCase()),
        ),
      );
    }
    if (enabledCardFields.contains('language') &&
        book.languageValue != null &&
        book.languageValue!.isNotEmpty) {
      meta.add(
        _MetaItem(
          icon: Icons.translate_outlined,
          text: l10n.language_with_colon(book.languageValue!.toUpperCase()),
        ),
      );
    }
    if (enabledCardFields.contains('pages') && book.pages != null) {
      meta.add(
        _MetaItem(
          icon: Icons.menu_book_outlined,
          text: l10n.pages_field_label('${book.pages}'),
        ),
      );
    }
    if (enabledCardFields.contains('genre') &&
        book.genre != null &&
        book.genre!.isNotEmpty) {
      meta.add(
        _MetaItem(
          icon: Icons.category_outlined,
          text: l10n.genre_field_label(book.genre!),
        ),
      );
    }
    if (enabledCardFields.contains('editorial') &&
        book.editorialValue != null &&
        book.editorialValue!.isNotEmpty) {
      meta.add(
        _MetaItem(
          icon: Icons.apartment_outlined,
          text: l10n.editorial_field_label(book.editorialValue!),
        ),
      );
    }
    if (enabledCardFields.contains('isbn') &&
        (book.isbn != null || book.asin != null)) {
      meta.add(
        _MetaItem(
          icon: Icons.tag,
          text: l10n.isbn_with_colon((book.isbn ?? book.asin)!),
        ),
      );
    }
    if (enabledCardFields.contains('publication_year') &&
        book.originalPublicationYear != null) {
      meta.add(
        _MetaItem(
          icon: Icons.calendar_today_outlined,
          text: l10n.published_field_label('${book.originalPublicationYear}'),
        ),
      );
    }
    if (enabledCardFields.contains('publication_date') &&
        book.notificationDatetime != null &&
        book.notificationDatetime!.isNotEmpty) {
      meta.add(
        _MetaItem(
          icon: Icons.notifications_none_outlined,
          text: l10n.publication_date_field_label(
            book.notificationDatetime!.split('T')[0],
          ),
        ),
      );
    }
    if (enabledCardFields.contains('rating') && book.myRating != null) {
      meta.add(
        _MetaItem(
          icon: Icons.star_outline,
          text: '${l10n.my_rating_label}: ${book.myRating}/5',
        ),
      );
    }
    if (enabledCardFields.contains('read_count') &&
        book.readCount != null &&
        book.readCount! > 0) {
      meta.add(
        _MetaItem(
          icon: Icons.repeat_outlined,
          text: l10n.read_count_field_label('${book.readCount}'),
        ),
      );
    }
    if (enabledCardFields.contains('status') &&
        book.statusValue != null &&
        book.statusValue!.isNotEmpty) {
      meta.add(
        _MetaItem(
          icon: Icons.info_outline,
          text: l10n.status_field_label(
            StatusHelper.getLocalizedLabel(book.statusValue!, l10n),
          ),
        ),
      );
    }
    if (enabledCardFields.contains('progress') &&
        book.readingProgress != null &&
        book.readingProgress! > 0 &&
        (book.statusValue?.toLowerCase() == 'started' ||
            book.statusValue?.toLowerCase() == 'standby')) {
      final pct =
          book.progressType == 'pages' &&
                  book.pages != null &&
                  book.pages! > 0
              ? '${(book.readingProgress! * 100 / book.pages!).round()}%'
              : '${book.readingProgress}%';
      meta.add(
        _MetaItem(
          icon: Icons.trending_up,
          text: '${l10n.progress_percentage}: $pct',
        ),
      );
    }
    if (enabledCardFields.contains('price') && book.price != null) {
      meta.add(
        _MetaItem(
          icon: Icons.attach_money_outlined,
          text: '${l10n.price_label}: ${book.price!.toStringAsFixed(2)}',
        ),
      );
    }
    if (enabledCardFields.contains('acquired_date') &&
        book.acquiredDate != null &&
        book.acquiredDate!.isNotEmpty) {
      meta.add(
        _MetaItem(
          icon: Icons.calendar_today_outlined,
          text:
              '${l10n.acquired_date}: ${book.acquiredDate!.split('-').reversed.join('/')}',
        ),
      );
    }
    if (enabledCardFields.contains('original_book') &&
        book.originalBookId != null) {
      meta.add(
        _MetaItem(
          icon: Icons.repeat_outlined,
          text: l10n.original_book.toUpperCase(),
        ),
      );
    }
    if (enabledCardFields.contains('format_saga') &&
        book.formatSagaValue != null &&
        book.formatSagaValue!.isNotEmpty) {
      meta.add(
        _MetaItem(
          icon: Icons.format_shapes,
          text:
              '${l10n.format_saga}: ${FormatSagaHelper.getLocalizedLabel(book.formatSagaValue!, l10n)}',
        ),
      );
    }

    final bool hasProgress =
        (book.statusValue?.toLowerCase() == 'started' ||
            book.statusValue?.toLowerCase() == 'standby') &&
        book.readingProgress != null &&
        book.readingProgress! > 0;

    double progressFraction = 0;
    if (hasProgress) {
      progressFraction =
          book.progressType == 'pages' &&
                  book.pages != null &&
                  book.pages! > 0
              ? (book.readingProgress! / book.pages!).clamp(0.0, 1.0)
              : (book.readingProgress! / 100.0).clamp(0.0, 1.0);
    }

    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NewBookDetailScreen(book: book)),
          ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isRead ? const Color(0xFFF5F3F2) : Colors.white,
          border: Border.all(color: _kBorder),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(17, 15, 17, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + icons row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          book.name ?? '',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary,
                            height: 1.25,
                          ),
                        ),
                      ),
                      if (book.tbr == true)
                        const Icon(
                          Icons.bookmark_add,
                          size: 16,
                          color: _kPrimary,
                        ),
                      if (book.isBundle == true)
                        const Icon(
                          Icons.library_books,
                          size: 16,
                          color: _kPrimary,
                        ),
                      if (book.isTandem == true)
                        const Icon(
                          Icons.swap_horiz,
                          size: 16,
                          color: _kPrimary,
                        ),
                    ],
                  ),

                  // Author
                  if (enabledCardFields.contains('author') &&
                      book.author != null &&
                      book.author!.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      book.author!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _kText,
                        height: 1.43,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1, thickness: 1, color: _kDivider),
                  ],

                  // Metadata grid
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children:
                          meta
                              .map(
                                (m) => SizedBox(
                                  width:
                                      m.fullWidth
                                          ? MediaQuery.of(context).size.width -
                                              40 -
                                              34
                                          : (MediaQuery.of(context).size.width -
                                                  40 -
                                                  34 -
                                                  8) /
                                              2,
                                  child: Row(
                                    children: [
                                      Icon(m.icon, size: 12, color: _kText),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          m.text,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: _kText,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ],
                ],
              ),
            ),

            // Progress bar
            if (hasProgress) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(7),
                  bottomRight: Radius.circular(7),
                ),
                child: LinearProgressIndicator(
                  value: progressFraction,
                  backgroundColor: _kDivider,
                  valueColor: const AlwaysStoppedAnimation(_kPrimary),
                  minHeight: 4,
                ),
              ),
            ] else
              const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }
}

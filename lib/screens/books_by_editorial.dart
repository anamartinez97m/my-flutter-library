import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/screens/new_ui/new_book_detail.dart';
import 'package:provider/provider.dart';

// ── v2 design tokens ─────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF43102B);
const _kBg = Color(0xFFFDF8F6);
const _kBorder = Color(0xFFCEC5BE);
const _kDivider = Color(0xFFE6E2DF);
const _kText = Color(0xFF5F5E5C);
const _kSub = Color(0xFF514348);

class BooksByEditorialScreen extends StatelessWidget {
  final String editorialName;

  const BooksByEditorialScreen({super.key, required this.editorialName});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookProvider?>(context);

    if (provider == null || provider.isLoading) {
      return Scaffold(
        backgroundColor: _kBg,
        body: CustomScrollView(
          slivers: [
            _buildAppBar(context),
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: _kPrimary)),
            ),
          ],
        ),
      );
    }

    // Filter books by editorial (single-valued, case-insensitive)
    final filteredBooks =
        provider.allBooks.where((book) {
          return book.editorialValue?.toLowerCase() ==
              editorialName.toLowerCase();
        }).toList();

    // Compute stats
    final readBooksWithRating =
        filteredBooks.where((book) {
          return book.statusValue?.toLowerCase() == 'yes' &&
              book.myRating != null &&
              book.myRating! > 0;
        }).toList();

    double? averageRating;
    if (readBooksWithRating.isNotEmpty) {
      final totalRating = readBooksWithRating.fold<double>(
        0.0,
        (sum, book) => sum + (book.myRating ?? 0),
      );
      averageRating = totalRating / readBooksWithRating.length;
    }

    // Sort by publication year, fallback to name
    filteredBooks.sort((a, b) {
      final aYear = a.originalPublicationYear;
      final bYear = b.originalPublicationYear;
      if (aYear != null && bYear != null) return aYear.compareTo(bYear);
      if (aYear != null) return -1;
      if (bYear != null) return 1;
      return (a.name ?? '').compareTo(b.name ?? '');
    });

    if (filteredBooks.isEmpty) {
      return Scaffold(
        backgroundColor: _kBg,
        body: CustomScrollView(
          slivers: [
            _buildAppBar(context),
            SliverFillRemaining(
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.no_books_for_editorial,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 16,
                    color: _kSub,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          // Stats row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  _statChip(
                    icon: Icons.menu_book_outlined,
                    value: '${filteredBooks.length}',
                    label: l10n.total_books,
                  ),
                  if (averageRating != null) ...[
                    const SizedBox(width: 10),
                    _statChip(
                      icon: Icons.star_outline,
                      value: averageRating.toStringAsFixed(1),
                      label: l10n.average_rating,
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Book list
          SliverPadding(
            padding: EdgeInsets.only(
              top: 16,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final book = filteredBooks[index];
                final isRead =
                    book.statusValue?.toLowerCase() == 'yes' ||
                    book.statusValue?.toLowerCase() == 'repeated';
                final authorText =
                    (book.author != null && book.author!.isNotEmpty)
                        ? book.author!
                        : null;

                return _bookCard(
                  context: context,
                  book: book,
                  isRead: isRead,
                  subtitle: authorText,
                  year: book.originalPublicationYear,
                );
              }, childCount: filteredBooks.length),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: _kBg,
      foregroundColor: _kPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: _kPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        editorialName,
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _kPrimary,
          letterSpacing: -0.5,
        ),
      ),
      centerTitle: true,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: Color(0xFFD5C2C7)),
      ),
    );
  }
}

// ── Shared helpers ───────────────────────────────────────────────────────────

Widget _statChip({
  required IconData icon,
  required String value,
  required String label,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: _kBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: _kText),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _kText,
            letterSpacing: 0.3,
          ),
        ),
      ],
    ),
  );
}

Widget _bookCard({
  required BuildContext context,
  required dynamic book,
  required bool isRead,
  String? subtitle,
  int? year,
}) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NewBookDetailScreen(book: book),
        ),
      );
    },
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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(17, 15, 17, 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              book.name ?? AppLocalizations.of(context)!.unknown,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
                height: 1.25,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: _kText,
                  height: 1.43,
                ),
              ),
            ],
            if (year != null || isRead) ...[
              if (subtitle != null)
                const Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 10),
                  child: Divider(height: 1, thickness: 1, color: _kDivider),
                )
              else
                const SizedBox(height: 10),
              Row(
                children: [
                  if (year != null) ...[
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: _kText,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$year',
                      style: const TextStyle(
                        fontSize: 11,
                        color: _kText,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                  if (isRead) ...[
                    if (year != null) const SizedBox(width: 16),
                    Icon(Icons.check_circle_outline, size: 12, color: _kText),
                    const SizedBox(width: 5),
                    Text(
                      AppLocalizations.of(context)!.read_label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _kText,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

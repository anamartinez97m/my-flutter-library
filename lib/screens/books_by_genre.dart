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

class BooksByGenreScreen extends StatelessWidget {
  final List<String> genres;

  const BooksByGenreScreen({super.key, required this.genres});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookProvider?>(context);

    if (provider == null || provider.isLoading) {
      return Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: _kBg,
          foregroundColor: _kPrimary,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: _kPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            AppLocalizations.of(context)!.genre,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _kPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator(color: _kPrimary)),
      );
    }

    if (genres.length == 1) {
      return Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: _kBg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: _kPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            genres.first,
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
            child: Divider(height: 1, thickness: 1, color: Color(0xFFD5C2C7)),
          ),
        ),
        body: _GenreContent(genreName: genres.first),
      );
    }

    return _MultiGenreScreen(genres: genres);
  }
}

class _MultiGenreScreen extends StatefulWidget {
  final List<String> genres;

  const _MultiGenreScreen({required this.genres});

  @override
  State<_MultiGenreScreen> createState() => _MultiGenreScreenState();
}

class _MultiGenreScreenState extends State<_MultiGenreScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          AppBar(
            backgroundColor: _kBg,
            foregroundColor: _kPrimary,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: _kPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              AppLocalizations.of(context)!.genres,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
                letterSpacing: -0.5,
              ),
            ),
            centerTitle: true,
          ),
          const Divider(height: 1, color: Color(0xFFD5C2C7)),
          const SizedBox(height: 8),
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: widget.genres.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final sel = i == _selectedIndex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIndex = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 17,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: sel ? _kPrimary : Colors.white,
                      border: Border.all(color: sel ? _kPrimary : _kBorder),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      widget.genres[i],
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : _kSub,
                        letterSpacing: 0.26,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _GenreContent(
              key: ValueKey(widget.genres[_selectedIndex]),
              genreName: widget.genres[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }
}

class _GenreContent extends StatelessWidget {
  final String genreName;

  const _GenreContent({super.key, required this.genreName});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookProvider?>(context);

    if (provider == null || provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: _kPrimary));
    }

    // Filter books that contain this genre (comma-separated, case-insensitive)
    final filteredBooks =
        provider.allBooks.where((book) {
          if (book.genre == null || book.genre!.isEmpty) return false;
          final bookGenres =
              book.genre!
                  .split(',')
                  .map((g) => g.trim().toLowerCase())
                  .toList();
          return bookGenres.contains(genreName.toLowerCase());
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
      return Center(
        child: Text(
          AppLocalizations.of(context)!.no_books_for_genre,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 16,
            color: _kSub,
          ),
        ),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    return CustomScrollView(
      slivers: [
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
            // Title
            Text(
              book.name ?? AppLocalizations.of(context)!.unknown,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
                height: 1.25,
              ),
            ),
            // Subtitle (author or saga)
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
            // Metadata row
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

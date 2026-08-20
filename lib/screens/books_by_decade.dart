import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/screens/new_ui/new_book_detail.dart';
import 'package:provider/provider.dart';

class BooksByDecadeScreen extends StatefulWidget {
  final String initialDecade;
  final bool showReadOnly;

  static const kBg = Color(0xFFFDF8F6);
  static const kPrimary = Color(0xFF43102B);
  static const kSecondary = Color(0xFF894B67);
  static const kTertiary = Color(0xFFBC92A6);
  static const kText = Color(0xFF1C1B1A);
  static const kSub = Color(0xFF514348);
  static const kBorder = Color(0x4DD5C2C7);
  static const kDivider = Color(0xFFE6E2DF);

  const BooksByDecadeScreen({
    super.key,
    required this.initialDecade,
    this.showReadOnly = true,
  });

  @override
  State<BooksByDecadeScreen> createState() => _BooksByDecadeScreenState();
}

class _BooksByDecadeScreenState extends State<BooksByDecadeScreen> {
  static const _kBg = BooksByDecadeScreen.kBg;
  static const _kPrimary = BooksByDecadeScreen.kPrimary;
  static const _kSecondary = BooksByDecadeScreen.kSecondary;
  static const _kText = BooksByDecadeScreen.kText;
  static const _kSub = BooksByDecadeScreen.kSub;
  static const _kBorder = BooksByDecadeScreen.kBorder;
  static const _kDivider = BooksByDecadeScreen.kDivider;

  late String _selectedDecade;
  List<String> _availableDecades = [];

  @override
  void initState() {
    super.initState();
    _selectedDecade = widget.initialDecade;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
          l10n.books_by_decade,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: _kPrimary,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFD5C2C7)),
        ),
      ),
      body: Consumer<BookProvider>(
        builder: (context, provider, child) {
          final books = provider.allBooks; // Use all books, not filtered

          // Calculate available decades from books
          final decadesSet = <String>{};
          for (var book in books) {
            // Filter based on showReadOnly parameter
            final isRead = book.readCount != null && book.readCount! > 0;
            final shouldInclude = widget.showReadOnly ? isRead : true;

            if (shouldInclude && book.originalPublicationYear != null) {
              int pubYear = book.originalPublicationYear!;

              // Handle full date format (YYYYMMDD)
              if (pubYear > 9999) {
                pubYear = pubYear ~/ 10000;
              }

              // Calculate decade
              final decade = (pubYear ~/ 10) * 10;
              decadesSet.add('${decade}s');
            }
          }
          _availableDecades =
              decadesSet.toList()..sort((a, b) {
                final aDecade = int.parse(a.replaceAll('s', ''));
                final bDecade = int.parse(b.replaceAll('s', ''));
                return bDecade.compareTo(aDecade);
              });

          // Ensure selected decade is in available decades
          if (_availableDecades.isNotEmpty &&
              !_availableDecades.contains(_selectedDecade)) {
            _selectedDecade = _availableDecades.first;
          }

          // Filter books for selected decade
          final booksForDecade =
              books.where((book) {
                // Filter based on showReadOnly parameter
                final isRead = book.readCount != null && book.readCount! > 0;
                final shouldInclude = widget.showReadOnly ? isRead : true;

                if (!shouldInclude || book.originalPublicationYear == null) {
                  return false;
                }

                int pubYear = book.originalPublicationYear!;

                // Handle full date format (YYYYMMDD)
                if (pubYear > 9999) {
                  pubYear = pubYear ~/ 10000;
                }

                // Calculate decade
                final decade = (pubYear ~/ 10) * 10;
                final decadeLabel = '${decade}s';

                return decadeLabel == _selectedDecade;
              }).toList();

          // Sort by publication year (most recent first)
          booksForDecade.sort((a, b) {
            if (a.originalPublicationYear != null &&
                b.originalPublicationYear != null) {
              int yearA = a.originalPublicationYear!;
              int yearB = b.originalPublicationYear!;

              // Handle full date format (YYYYMMDD)
              if (yearA > 9999) yearA = yearA ~/ 10000;
              if (yearB > 9999) yearB = yearB ~/ 10000;

              return yearB.compareTo(yearA);
            }
            return 0;
          });

          return Column(
            children: [
              // Decade selector
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: _kDivider, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      '${l10n.decade}: ',
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: _kBorder),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedDecade,
                          isExpanded: true,
                          underline: const SizedBox.shrink(),
                          dropdownColor: Colors.white,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 14,
                            color: _kText,
                          ),
                          items:
                              _availableDecades.map((decade) {
                                // Calculate total book count (including bundles)
                                int totalCount = 0;
                                for (var book in books) {
                                  // Filter based on showReadOnly parameter
                                  final isRead =
                                      book.readCount != null &&
                                      book.readCount! > 0;
                                  final shouldInclude =
                                      widget.showReadOnly ? isRead : true;

                                  if (!shouldInclude ||
                                      book.originalPublicationYear == null) {
                                    continue;
                                  }

                                  int pubYear = book.originalPublicationYear!;
                                  if (pubYear > 9999) {
                                    pubYear = pubYear ~/ 10000;
                                  }

                                  final decadeNum = (pubYear ~/ 10) * 10;
                                  final decadeLabel = '${decadeNum}s';

                                  if (decadeLabel == decade) {
                                    final multiplier =
                                        (book.isBundle == true &&
                                                book.bundleCount != null &&
                                                book.bundleCount! > 0)
                                            ? book.bundleCount!
                                            : 1;
                                    totalCount += multiplier;
                                  }
                                }

                                return DropdownMenuItem<String>(
                                  value: decade,
                                  child: Text(
                                    '$decade ($totalCount ${l10n.books})',
                                  ),
                                );
                              }).toList(),
                          onChanged: (decade) {
                            if (decade != null) {
                              setState(() {
                                _selectedDecade = decade;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Books list
              Expanded(
                child:
                    booksForDecade.isEmpty
                        ? Center(
                          child: Text(
                            l10n.no_books_from_decade,
                            style: const TextStyle(fontSize: 14, color: _kSub),
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: booksForDecade.length,
                          itemBuilder: (context, index) {
                            final book = booksForDecade[index];
                            return _buildBookCard(context, book);
                          },
                        ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookCard(BuildContext context, Book book) {
    final l10n = AppLocalizations.of(context)!;
    // Get original publication year
    String pubYearStr = '';
    if (book.originalPublicationYear != null) {
      int pubYear = book.originalPublicationYear!;

      // Handle full date format (YYYYMMDD)
      if (pubYear > 9999) {
        pubYear = pubYear ~/ 10000;
      }

      pubYearStr = '$pubYear';
    }

    // Build subtitle info list - only author
    final List<String> subtitleParts = [];
    if (book.author != null && book.author!.isNotEmpty) {
      subtitleParts.add(book.author!);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewBookDetailScreen(book: book),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.name ?? l10n.unknown,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kText,
                      ),
                    ),
                    if (subtitleParts.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitleParts.join(' \u2022 '),
                        style: const TextStyle(fontSize: 12, color: _kSub),
                      ),
                    ],
                  ],
                ),
              ),
              if (pubYearStr.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  pubYearStr,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _kSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

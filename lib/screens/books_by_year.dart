import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/screens/new_ui/new_book_detail.dart';

class BooksByYearScreen extends StatefulWidget {
  final int initialYear;

  static const kBg = Color(0xFFFDF8F6);
  static const kPrimary = Color(0xFF43102B);
  static const kSecondary = Color(0xFF894B67);
  static const kTertiary = Color(0xFFBC92A6);
  static const kText = Color(0xFF1C1B1A);
  static const kSub = Color(0xFF514348);
  static const kBorder = Color(0x4DD5C2C7);
  static const kDivider = Color(0xFFE6E2DF);

  const BooksByYearScreen({super.key, required this.initialYear});

  @override
  State<BooksByYearScreen> createState() => _BooksByYearScreenState();
}

class _BooksByYearScreenState extends State<BooksByYearScreen> {
  static const _kBg = BooksByYearScreen.kBg;
  static const _kPrimary = BooksByYearScreen.kPrimary;
  static const _kSecondary = BooksByYearScreen.kSecondary;
  static const _kText = BooksByYearScreen.kText;
  static const _kSub = BooksByYearScreen.kSub;
  static const _kBorder = BooksByYearScreen.kBorder;
  static const _kDivider = BooksByYearScreen.kDivider;

  late int _selectedYear;
  List<int> _availableYears = [];
  final Map<int, int> _yearBookCounts = {};

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
  }

  Future<List<int>> _loadYears() async {
    final db = await DatabaseHelper.instance.database;
    final repository = BookRepository(db);
    final years = await repository.getYearsWithReadBooks();

    // Load book counts for all years
    for (var year in years) {
      final booksData = await repository.getBooksReadInYear(year);
      _yearBookCounts[year] = booksData.length;
    }

    return years;
  }

  Future<List<Map<String, dynamic>>> _loadBooksForYear(int year) async {
    final db = await DatabaseHelper.instance.database;
    final repository = BookRepository(db);
    final booksData = await repository.getBooksReadInYear(year);

    // Return the raw data with bundle_book_index for proper display
    return booksData.map((data) {
      final mappedData = Map<String, dynamic>.from(data);
      if (mappedData.containsKey('latest_read_date')) {
        mappedData['date_read_final'] = mappedData['latest_read_date'];
      }
      return mappedData;
    }).toList();
  }

  String _getDisplayName(Map<String, dynamic> bookData) {
    final book = Book.fromMap(bookData);
    final bundleIndex = bookData['bundle_book_index'] as int?;

    if (book.isBundle == true && bundleIndex != null) {
      // Extract title from bundle_titles if available
      String? bundleBookTitle;
      if (book.bundleTitles != null) {
        try {
          final List<dynamic> titles = jsonDecode(book.bundleTitles!);
          if (bundleIndex < titles.length && titles[bundleIndex] != null) {
            bundleBookTitle = titles[bundleIndex] as String?;
          }
        } catch (e) {
          // Ignore JSON parsing errors
        }
      }

      if (bundleBookTitle != null && bundleBookTitle.isNotEmpty) {
        return '${book.name} - Book ${bundleIndex + 1}: $bundleBookTitle';
      } else {
        return '${book.name} - Book ${bundleIndex + 1}';
      }
    }

    return book.name ?? 'unknown';
  }

  /// Try to parse date with multiple formats
  DateTime? _tryParseDate(String dateStr) {
    if (dateStr.trim().isEmpty) return null;

    final trimmed = dateStr.trim();

    // Try ISO8601 format first (handles YYYY-MM-DD and full timestamps)
    try {
      return DateTime.parse(trimmed);
    } catch (e) {
      // Check if it contains slashes - likely YYYY/MM/DD format
      if (trimmed.contains('/')) {
        try {
          final parts = trimmed.split('/');
          if (parts.length == 3) {
            final year = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final day = int.parse(parts[2]);

            // Validate it's YYYY/MM/DD (year should be > 1900)
            if (year > 1900) {
              return DateTime(year, month, day);
            }
          }
        } catch (e) {
          // Failed to parse
        }
      }
    }

    return null;
  }

  String _getMonthName(int month) {
    const monthNames = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return month >= 1 && month <= 12 ? monthNames[month] : '';
  }

  int _getItemCount(List<Map<String, dynamic>> booksData) {
    if (booksData.isEmpty) return 0;

    int count = 0;
    int? lastMonth;

    for (var bookData in booksData) {
      final dateReadFinal = bookData['date_read_final'] as String?;
      if (dateReadFinal != null) {
        final date = _tryParseDate(dateReadFinal);
        if (date != null) {
          if (lastMonth != date.month) {
            count++; // Add month header
            lastMonth = date.month;
          }
        }
      }
      count++; // Add book card
    }

    return count;
  }

  Widget _buildItem(
    BuildContext context,
    List<Map<String, dynamic>> booksData,
    int index,
  ) {
    int currentIndex = 0;
    int? lastMonth;

    for (var i = 0; i < booksData.length; i++) {
      final bookData = booksData[i];
      final dateReadFinal = bookData['date_read_final'] as String?;

      // Check if we need a month header
      if (dateReadFinal != null) {
        final date = _tryParseDate(dateReadFinal);
        if (date != null && lastMonth != date.month) {
          if (currentIndex == index) {
            // Return month header
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.06),
                border: Border(bottom: BorderSide(color: _kDivider, width: 1)),
              ),
              child: Text(
                _getMonthName(date.month),
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
            );
          }
          currentIndex++;
          lastMonth = date.month;
        }
      }

      // Check if this is the book card we're looking for
      if (currentIndex == index) {
        return _buildBookCard(context, bookData);
      }
      currentIndex++;
    }

    return const SizedBox.shrink();
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
          l10n.books_by_year,
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
      body: FutureBuilder<List<int>>(
        future: _loadYears(),
        builder: (context, yearsSnapshot) {
          if (!yearsSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _kPrimary),
            );
          }

          _availableYears = yearsSnapshot.data!;

          // Ensure selected year is valid
          if (_availableYears.isNotEmpty &&
              !_availableYears.contains(_selectedYear)) {
            _selectedYear = _availableYears.first;
          }

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _loadBooksForYear(_selectedYear),
            builder: (context, booksSnapshot) {
              if (!booksSnapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: _kPrimary),
                );
              }

              final booksDataForYear = booksSnapshot.data!;

              return Column(
                children: [
                  // Year selector
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
                          '${l10n.year}: ',
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
                            child: DropdownButton<int>(
                              value: _selectedYear,
                              isExpanded: true,
                              underline: const SizedBox.shrink(),
                              dropdownColor: Colors.white,
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 14,
                                color: _kText,
                              ),
                              items:
                                  _availableYears.map((year) {
                                    final count = _yearBookCounts[year] ?? 0;
                                    return DropdownMenuItem<int>(
                                      value: year,
                                      child: Text(
                                        '$year ($count ${l10n.books})',
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (year) {
                                if (year != null) {
                                  setState(() {
                                    _selectedYear = year;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Books list with month separators
                  Expanded(
                    child:
                        booksDataForYear.isEmpty
                            ? Center(
                              child: Text(
                                l10n.no_books_in_year,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: _kSub,
                                ),
                              ),
                            )
                            : ListView.builder(
                              itemCount: _getItemCount(booksDataForYear),
                              itemBuilder: (context, index) {
                                return _buildItem(
                                  context,
                                  booksDataForYear,
                                  index,
                                );
                              },
                            ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBookCard(BuildContext context, Map<String, dynamic> bookData) {
    final book = Book.fromMap(bookData);
    final l10n = AppLocalizations.of(context)!;
    // Parse date for display
    String dateStr = '';
    if (book.dateReadFinal != null) {
      final date = _tryParseDate(book.dateReadFinal!);
      if (date != null) {
        dateStr = '${date.day}/${date.month}/${date.year}';
      } else {
        dateStr = book.dateReadFinal!;
      }
    }

    // Build subtitle info list - only author, finished date, and pages
    final List<String> subtitleParts = [];
    if (book.author != null && book.author!.isNotEmpty) {
      subtitleParts.add(book.author!);
    }
    if (dateStr.isNotEmpty) {
      subtitleParts.add('${l10n.finished}: $dateStr');
    }
    if (book.pages != null && book.pages! > 0) {
      subtitleParts.add('${book.pages} ${l10n.pages}');
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
                      _getDisplayName(bookData),
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
              if (book.myRating != null && book.myRating! > 0) ...[
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite, color: _kSecondary, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      book.myRating!.toStringAsFixed(1),
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _kSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

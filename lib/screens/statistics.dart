import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/screens/books_by_year.dart';
import 'package:myrandomlibrary/screens/books_by_decade.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _showStatusAsPercentage = false;
  bool _showFormatAsPercentage = true;
  Map<int, int>? _booksReadPerYear;
  Map<int, int>? _pagesReadPerYear;

  @override
  void initState() {
    super.initState();
    _loadYearData();
  }

  Future<void> _loadYearData() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);
      final yearData = await repository.getBooksAndPagesPerYear();
      if (mounted) {
        setState(() {
          _booksReadPerYear = yearData['books'] as Map<int, int>;
          _pagesReadPerYear = yearData['pages'] as Map<int, int>;
        });
      }
    } catch (e) {
      debugPrint('Error loading year statistics: $e');
    }
  }

  /// Try to parse date with multiple formats
  DateTime? _tryParseDate(String dateStr) {
    if (dateStr.trim().isEmpty) return null;

    final trimmed = dateStr.trim();

    // Try ISO8601 format first (handles YYYY-MM-DD and full timestamps like 2025-11-06T00:00:00.000)
    try {
      return DateTime.parse(trimmed);
    } catch (e) {
      // If ISO8601 fails, try other formats

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
            } else {
              // Try DD/MM/YYYY format
              return DateTime(
                int.parse(parts[2]),
                int.parse(parts[1]),
                int.parse(parts[0]),
              );
            }
          }
        } catch (e) {
          debugPrint('Could not parse date with slashes: $dateStr - Error: $e');
        }
      }
    }

    debugPrint('Could not parse date with any format: $dateStr');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookProvider?>(context);

    if (provider == null || provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final books = provider.allBooks; // Use all books, not filtered
    final totalCount = books.length;
    final latestBookName = provider.latestBookAdded;

    // Calculate statistics
    final statusCounts = <String, int>{};
    final languageCounts = <String, int>{};
    final formatCounts = <String, int>{};
    final genreCounts = <String, int>{};
    final editorialCounts = <String, int>{};
    final authorCounts = <String, int>{};

    for (var book in books) {
      // Get multiplier for bundle books
      final multiplier =
          (book.isBundle == true &&
                  book.bundleCount != null &&
                  book.bundleCount! > 0)
              ? book.bundleCount!
              : 1;

      // Status
      final status = book.statusValue ?? 'Unknown';
      statusCounts[status] = (statusCounts[status] ?? 0) + multiplier;

      // Language
      final language = book.languageValue;
      if (language != null && language.isNotEmpty && language != 'Unknown') {
        languageCounts[language] = (languageCounts[language] ?? 0) + multiplier;
      }

      // Format
      final format = book.formatValue;
      if (format != null && format.isNotEmpty) {
        formatCounts[format] = (formatCounts[format] ?? 0) + multiplier;
      }

      // Genre
      final genre = book.genre;
      if (genre != null && genre.isNotEmpty) {
        genreCounts[genre] = (genreCounts[genre] ?? 0) + multiplier;
      }

      // Editorial
      final editorial = book.editorialValue;
      if (editorial != null && editorial.isNotEmpty) {
        editorialCounts[editorial] =
            (editorialCounts[editorial] ?? 0) + multiplier;
      }

      // Author
      final author = book.author;
      if (author != null && author.isNotEmpty) {
        authorCounts[author] = (authorCounts[author] ?? 0) + multiplier;
      }
    }

    // Calculate reading velocity (average pages per day)
    double readingVelocity = 0.0;
    int totalDaysRead = 0;
    int totalPagesRead = 0;
    int booksWithDates = 0;
    
    for (var book in books) {
      // Skip books without dates or pages
      if (book.dateReadInitial == null || 
          book.dateReadInitial!.isEmpty ||
          book.dateReadFinal == null || 
          book.dateReadFinal!.isEmpty ||
          book.pages == null ||
          book.pages! <= 0) {
        continue;
      }
      
      final startDate = _tryParseDate(book.dateReadInitial!);
      final endDate = _tryParseDate(book.dateReadFinal!);
      
      if (startDate != null && endDate != null && endDate.isAfter(startDate)) {
        final daysToRead = endDate.difference(startDate).inDays + 1; // +1 to include both start and end day
        if (daysToRead > 0) {
          totalDaysRead += daysToRead;
          totalPagesRead += book.pages!;
          booksWithDates++;
        }
      }
    }
    
    if (totalDaysRead > 0 && totalPagesRead > 0) {
      readingVelocity = totalPagesRead / totalDaysRead;
    }

    // Calculate average days to finish a book
    double averageDaysToFinish = 0.0;
    int booksCountedForDays = 0;
    
    for (var book in books) {
      // Skip books without dates
      if (book.dateReadInitial == null || 
          book.dateReadInitial!.isEmpty ||
          book.dateReadFinal == null || 
          book.dateReadFinal!.isEmpty) {
        continue;
      }
      
      final startDate = _tryParseDate(book.dateReadInitial!);
      final endDate = _tryParseDate(book.dateReadFinal!);
      
      if (startDate != null && endDate != null && endDate.isAfter(startDate)) {
        final daysToRead = endDate.difference(startDate).inDays + 1;
        if (daysToRead > 0) {
          averageDaysToFinish += daysToRead;
          booksCountedForDays++;
        }
      }
    }
    
    if (booksCountedForDays > 0) {
      averageDaysToFinish = averageDaysToFinish / booksCountedForDays;
    }

    // Calculate average books read per year
    double averageBooksPerYear = 0.0;
    int yearsWithBooks = 0;
    
    if (_booksReadPerYear != null && _booksReadPerYear!.isNotEmpty) {
      final totalBooks = _booksReadPerYear!.values.reduce((a, b) => a + b);
      yearsWithBooks = _booksReadPerYear!.length;
      if (yearsWithBooks > 0) {
        averageBooksPerYear = totalBooks / yearsWithBooks;
      }
    }

    // Sort and get top entries
    final top5Genres =
        (genreCounts.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .take(5)
            .toList();

    final top10Editorials =
        (editorialCounts.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .take(10)
            .toList();

    final top10Authors =
        (authorCounts.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .take(10)
            .toList();

    // Use cached year data or empty maps
    final booksReadPerYear = _booksReadPerYear ?? {};
    final pagesReadPerYear = _pagesReadPerYear ?? {};

    // Sort years in descending order
    final sortedBooksReadYears =
        booksReadPerYear.entries.toList()
          ..sort((a, b) => b.key.compareTo(a.key));
    final sortedPagesReadYears =
        pagesReadPerYear.entries.toList()
          ..sort((a, b) => b.key.compareTo(a.key));

    // Calculate books read by decade (from original publication year)
    final Map<String, int> booksReadByDecade = {};

    for (var book in books) {
      // Only count books that have been read (read_count > 0)
      if (book.readCount != null &&
          book.readCount! > 0 &&
          book.originalPublicationYear != null) {
        int pubYear = book.originalPublicationYear!;

        // Handle full date format (YYYYMMDD)
        if (pubYear > 9999) {
          pubYear = pubYear ~/ 10000; // Extract year from YYYYMMDD
        }

        // Calculate decade (e.g., 1990 -> "1990s")
        final decade = (pubYear ~/ 10) * 10;
        final decadeLabel = '${decade}s';

        // Count books (handle bundles)
        final multiplier =
            (book.isBundle == true &&
                    book.bundleCount != null &&
                    book.bundleCount! > 0)
                ? book.bundleCount!
                : 1;

        booksReadByDecade[decadeLabel] =
            (booksReadByDecade[decadeLabel] ?? 0) + multiplier;
      }
    }

    // Sort decades in descending order
    final sortedBooksReadByDecade =
        booksReadByDecade.entries.toList()..sort((a, b) {
          // Extract decade number from label (e.g., "1990s" -> 1990)
          final aDecade = int.parse(a.key.replaceAll('s', ''));
          final bDecade = int.parse(b.key.replaceAll('s', ''));
          return bDecade.compareTo(aDecade);
        });

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      height: 180,
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.library_books,
                            size: 32,
                            color: Colors.deepPurple,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.total_books,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$totalCount',
                            style: Theme.of(
                              context,
                            ).textTheme.headlineMedium?.copyWith(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      height: 180,
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.new_releases,
                            size: 32,
                            color: Colors.deepPurple,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.latest_book_added,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            latestBookName != null && latestBookName.isNotEmpty
                                ? latestBookName
                                : AppLocalizations.of(
                                  context,
                                )!.no_books_in_database,
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Books Read Per Year
            InkWell(
              onTap: () {
                // Navigate to the first year in the list
                if (sortedBooksReadYears.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => BooksByYearScreen(
                            initialYear: sortedBooksReadYears.first.key,
                          ),
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Books Read Per Year',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right,
                            color: Theme.of(context).colorScheme.primary,
                            size: 28,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (sortedBooksReadYears.isEmpty)
                        Center(
                          child: Text(AppLocalizations.of(context)!.no_data),
                        )
                      else
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.4,
                          ),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children:
                                  sortedBooksReadYears.map((entry) {
                                    final maxValue = sortedBooksReadYears
                                        .map((e) => e.value)
                                        .reduce((a, b) => a > b ? a : b);
                                    final percentage = (entry.value / maxValue)
                                        .clamp(0.0, 1.0);
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                      BooksByYearScreen(
                                                        initialYear: entry.key,
                                                      ),
                                            ),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(4),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                            horizontal: 4,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 60,
                                                child: Text(
                                                  '${entry.key}',
                                                  style:
                                                      Theme.of(
                                                        context,
                                                      ).textTheme.bodySmall,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: LayoutBuilder(
                                                  builder: (
                                                    context,
                                                    constraints,
                                                  ) {
                                                    return Stack(
                                                      children: [
                                                        Container(
                                                          height: 24,
                                                          decoration: BoxDecoration(
                                                            color:
                                                                Colors
                                                                    .grey[200],
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  4,
                                                                ),
                                                          ),
                                                        ),
                                                        Container(
                                                          width:
                                                              constraints
                                                                  .maxWidth *
                                                              percentage,
                                                          height: 24,
                                                          decoration: BoxDecoration(
                                                            color: Colors.blue,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  4,
                                                                ),
                                                          ),
                                                          child: Center(
                                                            child: Text(
                                                              '${entry.value}',
                                                              style: const TextStyle(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Pages Read Per Year
            Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      'Pages Read Per Year',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (sortedPagesReadYears.isEmpty)
                      Center(child: Text(AppLocalizations.of(context)!.no_data))
                    else
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.4,
                        ),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children:
                                sortedPagesReadYears.map((entry) {
                                  final maxValue = sortedPagesReadYears
                                      .map((e) => e.value)
                                      .reduce((a, b) => a > b ? a : b);
                                  final percentage = (entry.value / maxValue)
                                      .clamp(0.0, 1.0);
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 60,
                                          child: Text(
                                            '${entry.key}',
                                            style:
                                                Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: LayoutBuilder(
                                            builder: (context, constraints) {
                                              return Stack(
                                                children: [
                                                  Container(
                                                    height: 24,
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[200],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                  ),
                                                  Container(
                                                    width:
                                                        constraints.maxWidth *
                                                        percentage,
                                                    height: 24,
                                                    decoration: BoxDecoration(
                                                      color: Colors.amber,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        '${entry.value}',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Books Read by Decade
            InkWell(
              onTap: () {
                // Navigate to the first decade in the list
                if (sortedBooksReadByDecade.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => BooksByDecadeScreen(
                            initialDecade: sortedBooksReadByDecade.first.key,
                          ),
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Books Read by Decade',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right,
                            color: Theme.of(context).colorScheme.primary,
                            size: 28,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '(Based on original publication year)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (sortedBooksReadByDecade.isEmpty)
                        Center(
                          child: Text(AppLocalizations.of(context)!.no_data),
                        )
                      else
                        ...sortedBooksReadByDecade.map((entry) {
                          final maxValue = sortedBooksReadByDecade
                              .map((e) => e.value)
                              .reduce((a, b) => a > b ? a : b);
                          final percentage = (entry.value / maxValue).clamp(
                            0.0,
                            1.0,
                          );
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => BooksByDecadeScreen(
                                          initialDecade: entry.key,
                                        ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 4,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 70,
                                      child: Text(
                                        entry.key,
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          Container(
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                          FractionallySizedBox(
                                            widthFactor: percentage,
                                            child: Container(
                                              height: 24,
                                              decoration: BoxDecoration(
                                                color: Colors.green,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '${entry.value}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Status Donut Chart
            Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.books_by_status,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Row(
                          children: [
                            Text(
                              _showStatusAsPercentage ? '%' : '#',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Switch(
                              value: _showStatusAsPercentage,
                              onChanged: (value) {
                                setState(() {
                                  _showStatusAsPercentage = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 230,
                      child:
                          statusCounts.isEmpty
                              ? Center(
                                child: Text(
                                  AppLocalizations.of(context)!.no_data,
                                ),
                              )
                              : PieChart(
                                PieChartData(
                                  sections:
                                      statusCounts.entries.map((entry) {
                                        final colors = [
                                          Colors.deepPurple,
                                          Colors.purple,
                                          Colors.purpleAccent,
                                          Colors.deepPurpleAccent,
                                        ];
                                        final index = statusCounts.keys
                                            .toList()
                                            .indexOf(entry.key);
                                        return PieChartSectionData(
                                          value: entry.value.toDouble(),
                                          title: '',
                                          radius: 50,
                                          color: colors[index % colors.length],
                                          badgeWidget: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color:
                                                    colors[index %
                                                        colors.length],
                                                width: 2,
                                              ),
                                            ),
                                            child: Text(
                                              _showStatusAsPercentage
                                                  ? '${((entry.value / totalCount) * 100).toStringAsFixed(1)}%'
                                                  : '${entry.value}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    colors[index %
                                                        colors.length],
                                              ),
                                            ),
                                          ),
                                          badgePositionPercentageOffset: 1.4,
                                        );
                                      }).toList(),
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 45,
                                ),
                              ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 20,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children:
                          statusCounts.entries.map((entry) {
                            final colors = [
                              Colors.deepPurple,
                              Colors.purple,
                              Colors.purpleAccent,
                              Colors.deepPurpleAccent,
                            ];
                            final index = statusCounts.keys.toList().indexOf(
                              entry.key,
                            );
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: colors[index % colors.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  entry.key,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Language Horizontal Bar Chart
            Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.books_by_language,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (languageCounts.isEmpty)
                      Center(child: Text(AppLocalizations.of(context)!.no_data))
                    else
                      ...(languageCounts.entries.toList()
                            ..sort((a, b) => b.value.compareTo(a.value)))
                          .map((entry) {
                            final maxValue = languageCounts.values.reduce(
                              (a, b) => a > b ? a : b,
                            );
                            final percentage = (entry.value / maxValue);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      entry.key,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        Container(
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                        FractionallySizedBox(
                                          widthFactor: percentage,
                                          child: Container(
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: Colors.deepPurple,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${entry.value}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          })
                          .toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Format Pie Chart
            Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.books_by_format,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Row(
                          children: [
                            Text(
                              _showFormatAsPercentage ? '%' : '#',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Switch(
                              value: _showFormatAsPercentage,
                              onChanged: (value) {
                                setState(() {
                                  _showFormatAsPercentage = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 230,
                      child:
                          formatCounts.isEmpty
                              ? Center(
                                child: Text(
                                  AppLocalizations.of(context)!.no_data,
                                ),
                              )
                              : PieChart(
                                PieChartData(
                                  sections:
                                      formatCounts.entries.map((entry) {
                                        final colors = [
                                          Colors.blue,
                                          Colors.cyan,
                                          Colors.teal,
                                          Colors.lightBlue,
                                        ];
                                        final index = formatCounts.keys
                                            .toList()
                                            .indexOf(entry.key);
                                        final percentage =
                                            (entry.value / totalCount) * 100;
                                        return PieChartSectionData(
                                          value: entry.value.toDouble(),
                                          title: '',
                                          radius: 50,
                                          color: colors[index % colors.length],
                                          badgeWidget: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color:
                                                    colors[index %
                                                        colors.length],
                                                width: 2,
                                              ),
                                            ),
                                            child: Text(
                                              _showFormatAsPercentage
                                                  ? '${percentage.toStringAsFixed(1)}%'
                                                  : '${entry.value}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    colors[index %
                                                        colors.length],
                                              ),
                                            ),
                                          ),
                                          badgePositionPercentageOffset: 1.4,
                                        );
                                      }).toList(),
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 45,
                                ),
                              ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 20,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children:
                          formatCounts.entries.map((entry) {
                            final colors = [
                              Colors.blue,
                              Colors.cyan,
                              Colors.teal,
                              Colors.lightBlue,
                            ];
                            final index = formatCounts.keys.toList().indexOf(
                              entry.key,
                            );
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: colors[index % colors.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  entry.key,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Reading Velocity Card
            if (readingVelocity > 0)
              Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        'Reading Velocity',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            readingVelocity.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'pages/day',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Based on $booksWithDates books with read dates',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (readingVelocity > 0)
              const SizedBox(height: 16),
            // Average Days to Finish a Book Card
            if (averageDaysToFinish > 0)
              Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        'Average Time to Finish a Book',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            averageDaysToFinish.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'days',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Based on $booksCountedForDays books with read dates',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (averageDaysToFinish > 0)
              const SizedBox(height: 16),
            // Average Books Per Year Card
            if (averageBooksPerYear > 0)
              Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        'Average Books Per Year',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            averageBooksPerYear.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'books/year',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Based on $yearsWithBooks years of reading data',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (averageBooksPerYear > 0)
              const SizedBox(height: 16),
            // Top 5 Genres Horizontal Bar Chart
            Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.top_5_genres,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (top5Genres.isEmpty)
                      Center(child: Text(AppLocalizations.of(context)!.no_data))
                    else
                      ...top5Genres.map((entry) {
                        final maxValue = top5Genres.first.value;
                        final percentage = (entry.value / maxValue);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 100,
                                child: Text(
                                  entry.key,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Stack(
                                  children: [
                                    Container(
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: percentage,
                                      child: Container(
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${entry.value}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Top 10 Editorials Horizontal Bar Chart
            Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.top_10_editorials,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...top10Editorials.map((entry) {
                      final maxValue = top10Editorials.first.value;
                      final percentage = (entry.value / maxValue);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text(
                                entry.key,
                                style: Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Stack(
                                children: [
                                  Container(
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: percentage,
                                    child: Container(
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${entry.value}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Top 10 Authors Horizontal Bar Chart
            Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.top_10_authors,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...top10Authors.map((entry) {
                      final maxValue = top10Authors.first.value;
                      final percentage = (entry.value / maxValue);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text(
                                entry.key,
                                style: Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Stack(
                                children: [
                                  Container(
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: percentage,
                                    child: Container(
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${entry.value}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

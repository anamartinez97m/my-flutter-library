import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
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
      // Status
      final status = book.statusValue ?? 'Unknown';
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;

      // Language
      final language = book.languageValue;
      if (language != null && language.isNotEmpty && language != 'Unknown') {
        languageCounts[language] = (languageCounts[language] ?? 0) + 1;
      }

      // Format
      final format = book.formatValue;
      if (format != null && format.isNotEmpty) {
        formatCounts[format] = (formatCounts[format] ?? 0) + 1;
      }

      // Genre
      final genre = book.genre;
      if (genre != null && genre.isNotEmpty) {
        genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
      }

      // Editorial
      final editorial = book.editorialValue;
      if (editorial != null && editorial.isNotEmpty) {
        editorialCounts[editorial] = (editorialCounts[editorial] ?? 0) + 1;
      }

      // Author
      final author = book.author;
      if (author != null && author.isNotEmpty) {
        authorCounts[author] = (authorCounts[author] ?? 0) + 1;
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

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.library_books,
                      size: 48,
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.total_books,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$totalCount',
                      style: Theme.of(
                        context,
                      ).textTheme.displayMedium?.copyWith(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.new_releases,
                      size: 48,
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.latest_book_added,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      latestBookName != null && latestBookName.isNotEmpty
                          ? latestBookName
                          : AppLocalizations.of(context)!.no_books_in_database,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
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

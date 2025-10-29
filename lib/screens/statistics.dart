import 'package:flutter/material.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

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

    for (var book in books) {
      final status = book.statusValue ?? 'Unknown';
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;

      final language = book.languageValue;
      if (language != null && language.isNotEmpty && language != 'Unknown') {
        languageCounts[language] = (languageCounts[language] ?? 0) + 1;
      }
    }

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
                      'Total Books in Library',
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
                      'Latest Book Added',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      latestBookName != null && latestBookName.isNotEmpty
                          ? latestBookName
                          : 'No books in the database',
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
                    Text(
                      'Books by Status',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 230,
                      child:
                          statusCounts.isEmpty
                              ? const Center(child: Text('No data'))
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
                                              '${entry.value}',
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
            // Language Bar Chart
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
                      'Books by Language',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 240,
                      child:
                          languageCounts.isEmpty
                              ? const Center(child: Text('No data'))
                              : BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY:
                                      languageCounts.values
                                          .reduce((a, b) => a > b ? a : b)
                                          .toDouble() +
                                      4,
                                  barGroups:
                                      languageCounts.entries
                                          .toList()
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                            return BarChartGroupData(
                                              x: entry.key,
                                              barRods: [
                                                BarChartRodData(
                                                  toY:
                                                      entry.value.value
                                                          .toDouble(),
                                                  color: Colors.deepPurple,
                                                  width: 20,
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(6),
                                                        topRight:
                                                            Radius.circular(6),
                                                      ),
                                                ),
                                              ],
                                              showingTooltipIndicators: [0],
                                            );
                                          })
                                          .toList(),
                                  barTouchData: BarTouchData(
                                    enabled: false,
                                    touchTooltipData: BarTouchTooltipData(
                                      getTooltipColor: (group) => Colors.white,
                                      tooltipBorder: const BorderSide(
                                        color: Colors.deepPurple,
                                        width: 1,
                                      ),
                                      tooltipRoundedRadius: 4,
                                      tooltipPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                      getTooltipItem: (
                                        group,
                                        groupIndex,
                                        rod,
                                        rodIndex,
                                      ) {
                                        return BarTooltipItem(
                                          '${rod.toY.toInt()}',
                                          const TextStyle(
                                            color: Colors.deepPurple,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    leftTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 60,
                                        getTitlesWidget: (value, meta) {
                                          final index = value.toInt();
                                          if (index >= 0 &&
                                              index < languageCounts.length) {
                                            final key =
                                                languageCounts.keys
                                                    .toList()[index];
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8.0,
                                              ),
                                              child: Transform.rotate(
                                                angle: -0.5,
                                                child: Text(
                                                  key,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                  ),
                                                  maxLines: 1,
                                                  textAlign: TextAlign.center,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            );
                                          }
                                          return const Text('');
                                        },
                                      ),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  gridData: const FlGridData(show: false),
                                  borderData: FlBorderData(show: false),
                                ),
                              ),
                    ),
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

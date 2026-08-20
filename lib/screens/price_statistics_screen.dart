import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:myrandomlibrary/helpers/statistics_calculator.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';

/// New "Price Statistics" screen matching the redesigned UI.
///
/// Preserves the original content (average price by format, spending by
/// year, spending by month, price extremes and price range evolution)
/// while adopting the v2 visual language used across the redesigned
/// statistics screens. Each section is collapsible.
class PriceStatisticsScreen extends StatefulWidget {
  final PriceStatsData? priceStats;
  final String currencySymbol;

  static const kBg = Color(0xFFFDF8F6);
  static const kPrimary = Color(0xFF43102B);
  static const kSecondary = Color(0xFF894B67);
  static const kTertiary = Color(0xFFBC92A6);
  static const kMuted = Color(0xFFD5C2C7);
  static const kText = Color(0xFF1C1B1A);
  static const kSub = Color(0xFF514348);
  static const kBorder = Color(0x4DD5C2C7);
  static const kDivider = Color(0xFFE6E2DF);
  static const kBarBg = Color(0xFFE6E2DF);

  const PriceStatisticsScreen({
    super.key,
    this.priceStats,
    required this.currencySymbol,
  });

  @override
  State<PriceStatisticsScreen> createState() => _PriceStatisticsScreenState();
}

class _PriceStatisticsScreenState extends State<PriceStatisticsScreen> {
  static const _kBg = PriceStatisticsScreen.kBg;
  static const _kPrimary = PriceStatisticsScreen.kPrimary;
  static const _kSecondary = PriceStatisticsScreen.kSecondary;
  static const _kTertiary = PriceStatisticsScreen.kTertiary;
  static const _kText = PriceStatisticsScreen.kText;
  static const _kSub = PriceStatisticsScreen.kSub;
  static const _kBorder = PriceStatisticsScreen.kBorder;
  static const _kDivider = PriceStatisticsScreen.kDivider;
  static const _kBarBg = PriceStatisticsScreen.kBarBg;

  final Set<String> _collapsedSections = {};
  int _selectedYear = DateTime.now().year;
  bool _totalVisible = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().year;
    final data = widget.priceStats?.totalSpentByMonth ?? {};
    if (data.isNotEmpty) {
      if (data.containsKey(now)) {
        _selectedYear = now;
      } else {
        final years = data.keys.toList()..sort((a, b) => b.compareTo(a));
        final pastYears = years.where((y) => y <= now).toList();
        _selectedYear = pastYears.isNotEmpty ? pastYears.first : years.first;
      }
    }
  }

  void _toggleSection(String key) {
    setState(() {
      if (_collapsedSections.contains(key)) {
        _collapsedSections.remove(key);
      } else {
        _collapsedSections.add(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final priceStats = widget.priceStats;

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
          l10n.section_price_statistics,
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
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(context).viewPadding.bottom,
        ),
        child: _buildBody(context, l10n, priceStats),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    PriceStatsData? priceStats,
  ) {
    if (priceStats == null) {
      return _buildCollapsibleCard(
        sectionKey: 'no_data',
        title: l10n.section_price_statistics,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.no_price_data,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: _kSub),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCollapsibleCard(
          sectionKey: 'price_by_format',
          title: l10n.price_by_format,
          child: _buildPriceByFormatContent(priceStats),
        ),
        const SizedBox(height: 16),
        _buildCollapsibleCard(
          sectionKey: 'price_by_year',
          title: l10n.price_by_year,
          child: _buildPriceByYearContent(priceStats),
        ),
        const SizedBox(height: 16),
        _buildCollapsibleCard(
          sectionKey: 'price_by_month',
          title: l10n.price_by_month,
          child: _buildPriceByMonthContent(priceStats),
        ),
        const SizedBox(height: 16),
        _buildCollapsibleCard(
          sectionKey: 'price_extremes',
          title: l10n.price_extremes,
          child: _buildPriceExtremesContent(priceStats, l10n),
        ),
        const SizedBox(height: 16),
        _buildCollapsibleCard(
          sectionKey: 'price_range_evolution',
          title: l10n.price_range_evolution,
          child: _buildPriceRangeEvolutionContent(priceStats),
        ),
      ],
    );
  }

  Widget _buildCollapsibleCard({
    required String sectionKey,
    required String title,
    required Widget child,
  }) {
    final isCollapsed = _collapsedSections.contains(sectionKey);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _toggleSection(sectionKey),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: isCollapsed ? -0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.expand_more, color: _kPrimary),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child:
                isCollapsed
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: child,
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceByFormatContent(PriceStatsData stats) {
    if (stats.avgPriceByFormat.isEmpty) {
      return _buildNoData();
    }
    final sorted =
        stats.avgPriceByFormat.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final maxPrice = sorted.first.value;

    return Column(
      children:
          sorted.map((entry) {
            final percentage = maxPrice > 0 ? entry.value / maxPrice : 0.0;
            final count = stats.countByFormat[entry.key] ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _kSub,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$count books',
                          style: const TextStyle(fontSize: 10, color: _kSub),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildBar(
                      percentage: percentage,
                      value:
                          '${widget.currencySymbol}${entry.value.toStringAsFixed(2)}',
                      barColor: _kSecondary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildPriceByYearContent(PriceStatsData stats) {
    if (stats.totalSpentByYear.isEmpty) {
      return _buildNoData();
    }
    final sortedYears = stats.totalSpentByYear.keys.toList()..sort();
    final maxVal = stats.totalSpentByYear.values.reduce(
      (a, b) => a > b ? a : b,
    );

    return Column(
      children:
          sortedYears.map((year) {
            final total = stats.totalSpentByYear[year] ?? 0;
            final percentage = maxVal > 0 ? total / maxVal : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      '$year',
                      style: const TextStyle(fontSize: 12, color: _kSub),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildBar(
                      percentage: percentage,
                      value:
                          '${widget.currencySymbol}${total.toStringAsFixed(0)}',
                      barColor: _kTertiary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildPriceByMonthContent(PriceStatsData stats) {
    if (stats.totalSpentByMonth.isEmpty) {
      return _buildNoData();
    }
    final sortedYears =
        stats.totalSpentByMonth.keys.toList()..sort((a, b) => b.compareTo(a));
    final monthData = stats.totalSpentByMonth[_selectedYear] ?? {};
    final maxVal =
        monthData.values.isEmpty
            ? 1.0
            : monthData.values.reduce((a, b) => a > b ? a : b);
    final monthAbbrs = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: _kBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<int>(
                value: _selectedYear,
                underline: const SizedBox.shrink(),
                isDense: true,
                style: const TextStyle(fontSize: 13, color: _kText),
                items:
                    sortedYears.map((year) {
                      return DropdownMenuItem<int>(
                        value: year,
                        child: Text(
                          '$year',
                          style: const TextStyle(fontSize: 13, color: _kText),
                        ),
                      );
                    }).toList(),
                onChanged: (year) {
                  if (year != null) setState(() => _selectedYear = year);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...List.generate(12, (index) {
          final month = index + 1;
          final total = monthData[month] ?? 0.0;
          final percentage = maxVal > 0 ? total / maxVal : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    monthAbbrs[index],
                    style: const TextStyle(fontSize: 12, color: _kSub),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildBar(
                    percentage: percentage,
                    value:
                        total > 0
                            ? '${widget.currencySymbol}${total.toStringAsFixed(0)}'
                            : '',
                    barColor: _kSecondary,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPriceExtremesContent(
    PriceStatsData stats,
    AppLocalizations l10n,
  ) {
    return Column(
      children: [
        // Total spent
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kSecondary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.account_balance_wallet,
                color: _kSecondary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.total_spent,
                      style: const TextStyle(fontSize: 12, color: _kSub),
                    ),
                    ClipRect(
                      child: Stack(
                        children: [
                          Text(
                            '${widget.currencySymbol}${stats.totalSpent.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: _kSecondary,
                            ),
                          ),
                          if (!_totalVisible)
                            Positioned.fill(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                                child: Container(color: Colors.transparent),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _totalVisible ? Icons.visibility_off : Icons.visibility,
                  color: _kSecondary,
                ),
                onPressed: () => setState(() => _totalVisible = !_totalVisible),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Most expensive
        if (stats.mostExpensiveName != null)
          _buildExtremeTile(
            icon: Icons.arrow_upward,
            color: _kSecondary,
            label: l10n.most_expensive,
            name: stats.mostExpensiveName!,
            price:
                '${widget.currencySymbol}${stats.mostExpensivePrice?.toStringAsFixed(2) ?? ''}',
          ),
        if (stats.mostExpensiveName != null && stats.leastExpensiveName != null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 1, color: _kDivider),
          ),
        // Least expensive
        if (stats.leastExpensiveName != null)
          _buildExtremeTile(
            icon: Icons.arrow_downward,
            color: _kTertiary,
            label: l10n.least_expensive,
            name: stats.leastExpensiveName!,
            price:
                '${widget.currencySymbol}${stats.leastExpensivePrice?.toStringAsFixed(2) ?? ''}',
          ),
      ],
    );
  }

  Widget _buildExtremeTile({
    required IconData icon,
    required Color color,
    required String label,
    required String name,
    required String price,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: _kSub)),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Text(
          price,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRangeEvolutionContent(PriceStatsData stats) {
    if (stats.avgPriceByYear.isEmpty) {
      return _buildNoData();
    }
    final sortedYears = stats.avgPriceByYear.keys.toList()..sort();

    double globalMax = 0;
    for (var year in sortedYears) {
      final maxP = stats.maxPriceByYear[year] ?? 0;
      if (maxP > globalMax) globalMax = maxP;
    }
    globalMax = globalMax * 1.15;
    if (globalMax == 0) globalMax = 10;

    final avgSpots = <FlSpot>[];
    final minSpots = <FlSpot>[];
    final maxSpots = <FlSpot>[];
    for (int i = 0; i < sortedYears.length; i++) {
      final year = sortedYears[i];
      avgSpots.add(FlSpot(i.toDouble(), stats.avgPriceByYear[year] ?? 0));
      minSpots.add(FlSpot(i.toDouble(), stats.minPriceByYear[year] ?? 0));
      maxSpots.add(FlSpot(i.toDouble(), stats.maxPriceByYear[year] ?? 0));
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendDot(_kSecondary, 'Max'),
            const SizedBox(width: 12),
            _buildLegendDot(_kTertiary, 'Avg'),
            const SizedBox(width: 12),
            _buildLegendDot(_kSub, 'Min'),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: globalMax,
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < sortedYears.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${sortedYears[index]}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${widget.currencySymbol}${value.toInt()}',
                        style: const TextStyle(fontSize: 9),
                      );
                    },
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: globalMax / 4,
                getDrawingHorizontalLine:
                    (value) => FlLine(color: _kDivider, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      String label;
                      if (spot.barIndex == 0) {
                        label = 'Max';
                      } else if (spot.barIndex == 1) {
                        label = 'Avg';
                      } else {
                        label = 'Min';
                      }
                      return LineTooltipItem(
                        '$label: ${widget.currencySymbol}${spot.y.toStringAsFixed(1)}',
                        TextStyle(
                          color: spot.bar.color ?? _kText,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: maxSpots,
                  isCurved: true,
                  color: _kSecondary,
                  barWidth: 2,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(show: false),
                ),
                LineChartBarData(
                  spots: avgSpots,
                  isCurved: true,
                  color: _kTertiary,
                  barWidth: 3,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: _kTertiary.withValues(alpha: 0.1),
                  ),
                ),
                LineChartBarData(
                  spots: minSpots,
                  isCurved: true,
                  color: _kSub,
                  barWidth: 2,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: _kSub)),
      ],
    );
  }

  Widget _buildBar({
    required double percentage,
    required String value,
    required Color barColor,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final barPixelWidth = constraints.maxWidth * percentage;
        final textColor = barPixelWidth >= 8 ? Colors.white : _kText;
        return Stack(
          children: [
            Container(
              height: 24,
              decoration: BoxDecoration(
                color: _kBarBg,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage,
              child: Container(
                height: 24,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            Container(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  color: textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNoData() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          AppLocalizations.of(context)!.no_data,
          style: const TextStyle(fontSize: 14, color: _kSub),
        ),
      ),
    );
  }
}

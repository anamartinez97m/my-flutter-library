import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book.dart';

/// New "Library Breakdown" statistics screen matching the redesigned UI.
///
/// Preserves the original content (unified breakdown with donut chart,
/// format by language heatmap, avg days by format & language heatmap)
/// while adopting the v2 visual language. Each section is collapsible.
class LibraryBreakdownScreen extends StatefulWidget {
  final Map<String, int> statusCounts;
  final Map<String, int> formatCounts;
  final Map<String, int> placeCounts;
  final Map<String, int> languageCounts;
  final int totalCount;
  final List<Book> books;
  final Map<String, Map<String, int>> formatByLanguageCounts;
  final Map<String, Map<String, double>> avgDaysByFormatLanguage;

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

  const LibraryBreakdownScreen({
    super.key,
    required this.statusCounts,
    required this.formatCounts,
    required this.placeCounts,
    required this.languageCounts,
    required this.totalCount,
    required this.books,
    required this.formatByLanguageCounts,
    required this.avgDaysByFormatLanguage,
  });

  @override
  State<LibraryBreakdownScreen> createState() => _LibraryBreakdownScreenState();
}

class _LibraryBreakdownScreenState extends State<LibraryBreakdownScreen> {
  static const _kBg = LibraryBreakdownScreen.kBg;
  static const _kPrimary = LibraryBreakdownScreen.kPrimary;
  static const _kSecondary = LibraryBreakdownScreen.kSecondary;
  static const _kTertiary = LibraryBreakdownScreen.kTertiary;
  static const _kMuted = LibraryBreakdownScreen.kMuted;
  static const _kText = LibraryBreakdownScreen.kText;
  static const _kSub = LibraryBreakdownScreen.kSub;
  static const _kBorder = LibraryBreakdownScreen.kBorder;
  static const _kBarBg = LibraryBreakdownScreen.kBarBg;

  final Set<String> _collapsedSections = {};

  // Unified breakdown field selector
  String _selectedField = 'status';

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
          l10n.section_library_breakdown,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Library Overview (unified breakdown with donut chart)
            _buildCollapsibleCard(
              sectionKey: 'library_overview',
              title: l10n.library_overview,
              child: _buildUnifiedBreakdownContent(context, l10n),
            ),
            const SizedBox(height: 16),
            // Format by Language heatmap
            if (widget.formatByLanguageCounts.isNotEmpty)
              _buildCollapsibleCard(
                sectionKey: 'format_by_language',
                title: l10n.format_by_language,
                child: _buildFormatByLanguageContent(context, l10n),
              ),
            if (widget.formatByLanguageCounts.isNotEmpty)
              const SizedBox(height: 16),
            // Avg Days by Format & Language heatmap
            if (widget.avgDaysByFormatLanguage.isNotEmpty)
              _buildCollapsibleCard(
                sectionKey: 'avg_days_by_format_language',
                title: l10n.avg_days_by_format_language,
                child: _buildAvgDaysByFormatLanguageContent(context, l10n),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Collapsible card shell ───────────────────────────────────────

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

  // ─── Unified Breakdown (donut chart + legend) ─────────────────────

  List<Color> _getPaletteColors(String field) {
    switch (field) {
      case 'format':
        return [_kTertiary, _kSecondary, _kPrimary, _kMuted];
      case 'place':
        return [_kPrimary, _kSecondary, _kTertiary, _kMuted];
      case 'language':
        return [_kSecondary, _kPrimary, _kTertiary, _kMuted];
      case 'genre':
        return [_kPrimary, _kSecondary, _kTertiary, _kMuted];
      default: // status
        return [_kPrimary, _kSecondary, _kTertiary, _kMuted];
    }
  }

  Map<String, int> _getDataForField() {
    switch (_selectedField) {
      case 'status':
        return widget.statusCounts;
      case 'format':
        return widget.formatCounts;
      case 'place':
        return widget.placeCounts;
      case 'language':
        return widget.languageCounts;
      case 'genre':
        return _computeGenreCounts();
      default:
        return widget.statusCounts;
    }
  }

  Map<String, int> _computeGenreCounts() {
    final Map<String, int> counts = {};
    for (var book in widget.books) {
      final raw = book.genre ?? '';
      if (raw.isEmpty) continue;
      final multiplier =
          (book.isBundle == true &&
                  book.bundleCount != null &&
                  book.bundleCount! > 0)
              ? book.bundleCount!
              : 1;
      final genres = raw
          .split(',')
          .map((g) => g.trim())
          .where((g) => g.isNotEmpty);
      for (final genre in genres) {
        counts[genre] = (counts[genre] ?? 0) + multiplier;
      }
    }
    final sorted =
        counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }

  String _fieldLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'status':
        return l10n.books_by_status;
      case 'format':
        return l10n.books_by_format;
      case 'place':
        return l10n.books_by_place;
      case 'language':
        return l10n.books_by_language;
      case 'genre':
        return l10n.books_by_genre;
      default:
        return key;
    }
  }

  Widget _buildUnifiedBreakdownContent(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final data = _getDataForField();
    final total = data.values.fold<int>(0, (sum, v) => sum + v);
    final colors = _getPaletteColors(_selectedField);
    final fieldOptions = ['status', 'format', 'place', 'language', 'genre'];

    return Column(
      children: [
        // Field selector dropdown
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: _kBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: _selectedField,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            dropdownColor: Colors.white,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              color: _kText,
            ),
            items:
                fieldOptions.map((key) {
                  return DropdownMenuItem<String>(
                    value: key,
                    child: Text(_fieldLabel(key, l10n)),
                  );
                }).toList(),
            onChanged: (value) {
              if (value != null) setState(() => _selectedField = value);
            },
          ),
        ),
        const SizedBox(height: 20),
        // Donut chart
        SizedBox(
          height: 200,
          child:
              data.isEmpty
                  ? Center(
                    child: Text(
                      l10n.no_data,
                      style: const TextStyle(fontSize: 14, color: _kSub),
                    ),
                  )
                  : PieChart(
                    PieChartData(
                      sections:
                          data.entries.map((entry) {
                            final index = data.keys.toList().indexOf(entry.key);
                            final pct =
                                total > 0 ? (entry.value / total) * 100 : 0.0;
                            final showBadge = pct >= 2.5;
                            return PieChartSectionData(
                              value: entry.value.toDouble(),
                              title: '',
                              radius: 45,
                              color: colors[index % colors.length],
                              badgeWidget:
                                  showBadge
                                      ? Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: Border.all(
                                            color:
                                                colors[index % colors.length],
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Text(
                                          '${pct.toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                colors[index % colors.length],
                                          ),
                                        ),
                                      )
                                      : const SizedBox.shrink(),
                              badgePositionPercentageOffset: 1.4,
                            );
                          }).toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
        ),
        const SizedBox(height: 16),
        // Legend with counts
        if (data.isNotEmpty)
          Column(
            children:
                data.entries.map((entry) {
                  final index = data.keys.toList().indexOf(entry.key);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: colors[index % colors.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 13,
                              color: _kText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${entry.value}',
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _kText,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
      ],
    );
  }

  // ─── Format by Language Heatmap ───────────────────────────────────

  Widget _buildFormatByLanguageContent(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final Set<String> allLanguages = {};
    for (var formatEntry in widget.formatByLanguageCounts.entries) {
      allLanguages.addAll(formatEntry.value.keys);
    }
    final sortedLanguages = allLanguages.toList()..sort();
    final sortedFormats = widget.formatByLanguageCounts.keys.toList()..sort();

    int maxCount = 0;
    for (var formatMap in widget.formatByLanguageCounts.values) {
      for (var count in formatMap.values) {
        if (count > maxCount) maxCount = count;
      }
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 80;
    final labelWidth = 80.0;
    final cellWidth =
        (availableWidth - labelWidth) / (sortedLanguages.length + 1);
    final cellHeight = 50.0;

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  SizedBox(width: labelWidth),
                  ...sortedLanguages.map(
                    (language) => Container(
                      width: cellWidth,
                      height: cellHeight,
                      alignment: Alignment.center,
                      child: Text(
                        language,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              // Data rows
              ...sortedFormats.map(
                (format) => Row(
                  children: [
                    Container(
                      width: labelWidth,
                      height: cellHeight,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        format,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _kSub,
                        ),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ...sortedLanguages.map((language) {
                      final count =
                          widget.formatByLanguageCounts[format]?[language] ?? 0;
                      final intensity = maxCount > 0 ? count / maxCount : 0.0;
                      final cellColor =
                          count == 0
                              ? _kBarBg
                              : Color.lerp(
                                _kSecondary.withValues(alpha: 0.2),
                                _kSecondary,
                                intensity,
                              )!;
                      return Container(
                        width: cellWidth,
                        height: cellHeight,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: cellColor,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _kBorder, width: 0.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          count > 0 ? '$count' : '',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: intensity > 0.5 ? Colors.white : _kText,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Low', style: TextStyle(fontSize: 11, color: _kSub)),
            const SizedBox(width: 8),
            ...List.generate(5, (index) {
              final intensity = (index + 1) / 5;
              return Container(
                width: 30,
                height: 20,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: Color.lerp(
                    _kSecondary.withValues(alpha: 0.2),
                    _kSecondary,
                    intensity,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
            const SizedBox(width: 8),
            const Text('High', style: TextStyle(fontSize: 11, color: _kSub)),
          ],
        ),
      ],
    );
  }

  // ─── Avg Days by Format & Language Heatmap ────────────────────────

  Widget _buildAvgDaysByFormatLanguageContent(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final Set<String> allLanguages = {};
    for (var formatEntry in widget.avgDaysByFormatLanguage.entries) {
      allLanguages.addAll(formatEntry.value.keys);
    }
    final sortedLanguages = allLanguages.toList()..sort();
    final sortedFormats = widget.avgDaysByFormatLanguage.keys.toList()..sort();

    double maxDays = 0;
    for (var formatMap in widget.avgDaysByFormatLanguage.values) {
      for (var days in formatMap.values) {
        if (days > maxDays) maxDays = days;
      }
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 80;
    final labelWidth = 80.0;
    final cellWidth =
        (availableWidth - labelWidth) / (sortedLanguages.length + 1);
    final cellHeight = 50.0;

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  SizedBox(width: labelWidth),
                  ...sortedLanguages.map(
                    (language) => Container(
                      width: cellWidth,
                      height: cellHeight,
                      alignment: Alignment.center,
                      child: Text(
                        language,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _kTertiary,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              // Data rows
              ...sortedFormats.map(
                (format) => Row(
                  children: [
                    Container(
                      width: labelWidth,
                      height: cellHeight,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        format,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _kSub,
                        ),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ...sortedLanguages.map((language) {
                      final days =
                          widget.avgDaysByFormatLanguage[format]?[language] ??
                          0.0;
                      final intensity = maxDays > 0 ? days / maxDays : 0.0;
                      final cellColor =
                          days == 0.0
                              ? _kBarBg
                              : Color.lerp(
                                _kTertiary.withValues(alpha: 0.2),
                                _kTertiary,
                                intensity,
                              )!;
                      return Container(
                        width: cellWidth,
                        height: cellHeight,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: cellColor,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _kBorder, width: 0.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          days > 0 ? '${days.toStringAsFixed(0)}d' : '',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: intensity > 0.5 ? Colors.white : _kText,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Fast', style: TextStyle(fontSize: 11, color: _kSub)),
            const SizedBox(width: 8),
            ...List.generate(5, (index) {
              final intensity = (index + 1) / 5;
              return Container(
                width: 30,
                height: 20,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: Color.lerp(
                    _kTertiary.withValues(alpha: 0.2),
                    _kTertiary,
                    intensity,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
            const SizedBox(width: 8),
            const Text('Slow', style: TextStyle(fontSize: 11, color: _kSub)),
          ],
        ),
      ],
    );
  }
}

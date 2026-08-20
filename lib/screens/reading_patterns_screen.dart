import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/screens/rereads_detail.dart';

/// New "Reading Patterns & Insights" screen matching the redesigned UI.
///
/// Preserves the original content (reading streaks, DNF rate, re-reads,
/// series vs standalone, personal bests, milestones, binge reading,
/// seasonal reading patterns and reading time of day) while adopting the
/// v2 visual language used across the redesigned statistics screens. Each
/// section is collapsible.
class ReadingPatternsScreen extends StatefulWidget {
  final int currentStreak;
  final int longestStreak;
  final int dnfCount;
  final double dnfRate;
  final int rereadCount;
  final Map<String, dynamic>? mostRereadBook;
  final int seriesBooks;
  final int standaloneBooks;
  final int seriesBooksRead;
  final int standaloneBooksRead;
  final double seriesPercentage;
  final int seriesCount;
  final int mostBooksInMonth;
  final String? bestMonth;
  final int? fastestDays;
  final String? fastestBookName;
  final int nextMilestoneOwned;
  final int booksToMilestoneOwned;
  final int nextMilestoneRead;
  final int booksToMilestoneRead;
  final double bingePercentage;
  final Map<String, int> seasonalReading;
  final Map<int, Map<String, int>> seasonalReadingPerYear;
  final int yearsCount;
  final Map<String, String> topGenreBySeason;
  final Map<String, Map<String, dynamic>> readingTimeOfDay;

  static const kBg = Color(0xFFFDF8F6);
  static const kPrimary = Color(0xFF43102B);
  static const kSecondary = Color(0xFF894B67);
  static const kMuted = Color(0xFFD5C2C7);
  static const kText = Color(0xFF1C1B1A);
  static const kSub = Color(0xFF514348);
  static const kBorder = Color(0x4DD5C2C7);
  static const kDivider = Color(0xFFE6E2DF);
  static const kBarBg = Color(0xFFE6E2DF);

  const ReadingPatternsScreen({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
    required this.dnfCount,
    required this.dnfRate,
    required this.rereadCount,
    this.mostRereadBook,
    required this.seriesBooks,
    required this.standaloneBooks,
    required this.seriesBooksRead,
    required this.standaloneBooksRead,
    required this.seriesPercentage,
    required this.seriesCount,
    required this.mostBooksInMonth,
    this.bestMonth,
    this.fastestDays,
    this.fastestBookName,
    required this.nextMilestoneOwned,
    required this.booksToMilestoneOwned,
    required this.nextMilestoneRead,
    required this.booksToMilestoneRead,
    required this.bingePercentage,
    required this.seasonalReading,
    required this.seasonalReadingPerYear,
    required this.yearsCount,
    required this.topGenreBySeason,
    required this.readingTimeOfDay,
  });

  @override
  State<ReadingPatternsScreen> createState() => _ReadingPatternsScreenState();
}

class _ReadingPatternsScreenState extends State<ReadingPatternsScreen> {
  static const _kBg = ReadingPatternsScreen.kBg;
  static const _kPrimary = ReadingPatternsScreen.kPrimary;
  static const _kSecondary = ReadingPatternsScreen.kSecondary;
  static const _kMuted = ReadingPatternsScreen.kMuted;
  static const _kText = ReadingPatternsScreen.kText;
  static const _kSub = ReadingPatternsScreen.kSub;
  static const _kBorder = ReadingPatternsScreen.kBorder;
  static const _kDivider = ReadingPatternsScreen.kDivider;
  static const _kBarBg = ReadingPatternsScreen.kBarBg;

  final Set<String> _collapsedSections = {};

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
          l10n.section_reading_patterns,
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
            _buildCollapsibleCard(
              sectionKey: 'reading_insights',
              title: l10n.reading_insights,
              child: _buildReadingInsightsContent(l10n),
            ),
            const SizedBox(height: 16),
            _buildCollapsibleCard(
              sectionKey: 'seasonal_patterns',
              title: l10n.seasonal_reading_patterns,
              child: _buildSeasonalContent(l10n),
            ),
            const SizedBox(height: 16),
            _buildCollapsibleCard(
              sectionKey: 'time_of_day',
              title: l10n.reading_time_of_day,
              child: _buildTimeOfDayContent(l10n),
            ),
          ],
        ),
      ),
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

  Widget _buildReadingInsightsContent(AppLocalizations l10n) {
    return Column(
      children: [
        _buildInsightRow(
          icon: Icons.local_fire_department,
          color: _kSecondary,
          title: l10n.reading_streaks,
          value:
              '${l10n.current_label}: ${widget.currentStreak} ${l10n.days} | ${l10n.best}: ${widget.longestStreak} ${l10n.days}',
        ),
        const Divider(height: 24, thickness: 1, color: _kDivider),
        _buildInsightRow(
          icon: Icons.close,
          color: _kPrimary,
          title: l10n.dnf_rate,
          value:
              '${widget.dnfCount} ${l10n.books} (${widget.dnfRate.toStringAsFixed(1)}%)',
        ),
        if (widget.rereadCount > 0) ...[
          const Divider(height: 24, thickness: 1, color: _kDivider),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RereadsDetailScreen(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: _buildInsightRow(
              icon: Icons.replay,
              color: _kSecondary,
              title: l10n.re_reads,
              value: '${widget.rereadCount} ${l10n.books}',
              subtitle:
                  widget.mostRereadBook != null
                      ? '${l10n.most}: ${widget.mostRereadBook!['name']} (${widget.mostRereadBook!['count']}x)'
                      : null,
              showNavigationIcon: true,
            ),
          ),
        ],
        const Divider(height: 24, thickness: 1, color: _kDivider),
        _buildInsightRow(
          icon: Icons.collections_bookmark,
          color: _kPrimary,
          title: l10n.series_vs_standalone,
          value:
              '${widget.seriesBooks} ${l10n.series} (${widget.seriesPercentage.toStringAsFixed(1)}%) | ${widget.standaloneBooks} ${l10n.standalone}',
          subtitle:
              '${l10n.read_label}: ${widget.seriesBooksRead} ${l10n.series} + ${widget.standaloneBooksRead} ${l10n.standalone}',
        ),
        const Divider(height: 24, thickness: 1, color: _kDivider),
        _buildInsightRow(
          icon: Icons.emoji_events,
          color: _kSecondary,
          title: l10n.personal_bests,
          value:
              '${l10n.most_in_month}: ${widget.mostBooksInMonth}${widget.bestMonth != null ? ' (${widget.bestMonth})' : ''}',
          subtitle:
              widget.fastestDays != null && widget.fastestBookName != null
                  ? '${l10n.fastest}: ${widget.fastestDays} ${l10n.days} (${widget.fastestBookName})'
                  : null,
        ),
        const Divider(height: 24, thickness: 1, color: _kDivider),
        _buildInsightRow(
          icon: Icons.flag,
          color: _kPrimary,
          title: l10n.next_milestone_owned,
          value:
              '${widget.nextMilestoneOwned} ${l10n.books} (${widget.booksToMilestoneOwned} ${l10n.to_go})',
        ),
        const Divider(height: 24, thickness: 1, color: _kDivider),
        _buildInsightRow(
          icon: Icons.menu_book,
          color: _kPrimary,
          title: l10n.next_milestone_read,
          value:
              '${widget.nextMilestoneRead} ${l10n.books} (${widget.booksToMilestoneRead} ${l10n.to_go})',
        ),
        const Divider(height: 24, thickness: 1, color: _kDivider),
        _buildInsightRow(
          icon: Icons.fast_forward,
          color: _kSecondary,
          title: l10n.binge_reading_series,
          value:
              '${widget.bingePercentage.toStringAsFixed(1)}% ${l10n.binge_reading_description}',
        ),
      ],
    );
  }

  Widget _buildInsightRow({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    String? subtitle,
    bool showNavigationIcon = false,
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kText,
                ),
              ),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 14, color: _kSub)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _kSub,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (showNavigationIcon)
          const Icon(Icons.chevron_right, color: _kPrimary, size: 24),
      ],
    );
  }

  Widget _buildSeasonalContent(AppLocalizations l10n) {
    final sortedSeasons =
        widget.seasonalReading.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final mostProductive =
        sortedSeasons.isNotEmpty ? sortedSeasons.first : null;
    final leastProductive =
        sortedSeasons.isNotEmpty ? sortedSeasons.last : null;
    final totalBooks = widget.seasonalReading.values.fold<int>(
      0,
      (a, b) => a + b,
    );

    if (totalBooks == 0) {
      return _buildNoData();
    }

    final mostAvgPerYear =
        mostProductive != null && widget.yearsCount > 0
            ? (mostProductive.value / widget.yearsCount).toStringAsFixed(1)
            : '0.0';
    final leastAvgPerYear =
        leastProductive != null && widget.yearsCount > 0
            ? (leastProductive.value / widget.yearsCount).toStringAsFixed(1)
            : '0.0';

    final preferredSeason = mostProductive?.key ?? 'None';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getSeasonColor(preferredSeason).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getSeasonColor(preferredSeason).withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _getSeasonEmoji(preferredSeason),
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.you_read_most_in,
                    style: const TextStyle(fontSize: 12, color: _kSub),
                  ),
                  Text(
                    _getSeasonName(l10n, preferredSeason),
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getSeasonColor(preferredSeason),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ...widget.seasonalReading.entries.map((entry) {
          final percentage = (entry.value / totalBooks).clamp(0.0, 1.0);
          final pctString = (entry.value / totalBooks * 100).toStringAsFixed(1);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          _getSeasonEmoji(entry.key),
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getSeasonName(l10n, entry.key),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      l10n.n_books_percentage(entry.value, pctString),
                      style: const TextStyle(fontSize: 12, color: _kSub),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: _kBarBg,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getSeasonColor(entry.key),
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        const Divider(height: 1, thickness: 1, color: _kDivider),
        const SizedBox(height: 16),
        if (mostProductive != null &&
            leastProductive != null &&
            mostProductive.key != leastProductive.key)
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      l10n.most,
                      style: const TextStyle(fontSize: 11, color: _kSub),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_getSeasonEmoji(mostProductive.key)} ${_getSeasonName(l10n, mostProductive.key)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      mostAvgPerYear,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: _kPrimary,
                      ),
                    ),
                    Text(
                      l10n.per_year,
                      style: const TextStyle(fontSize: 10, color: _kSub),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 60, color: _kDivider),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      l10n.least,
                      style: const TextStyle(fontSize: 11, color: _kSub),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_getSeasonEmoji(leastProductive.key)} ${_getSeasonName(l10n, leastProductive.key)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      leastAvgPerYear,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: _kSecondary,
                      ),
                    ),
                    Text(
                      l10n.per_year,
                      style: const TextStyle(fontSize: 10, color: _kSub),
                    ),
                  ],
                ),
              ),
            ],
          ),
        if (widget.topGenreBySeason.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: _kDivider),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.auto_stories, color: _kSecondary, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.seasonal_reading_preferences,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  widget.topGenreBySeason.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '${_getSeasonEmoji(entry.key)} ${_getSeasonName(l10n, entry.key)}: ${entry.value}',
                        style: const TextStyle(fontSize: 12, color: _kSub),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimeOfDayContent(AppLocalizations l10n) {
    const slotOrder = ['late_night', 'morning', 'afternoon', 'night'];
    const slotIcons = {
      'late_night': Icons.dark_mode,
      'morning': Icons.wb_sunny,
      'afternoon': Icons.light_mode,
      'night': Icons.nights_stay,
    };
    const slotRanges = {
      'late_night': '00:00 - 06:00',
      'morning': '06:00 - 12:00',
      'afternoon': '12:00 - 18:00',
      'night': '18:00 - 00:00',
    };

    final totalSessions = slotOrder.fold<int>(
      0,
      (sum, slot) =>
          sum + ((widget.readingTimeOfDay[slot]?['count'] as int?) ?? 0),
    );

    if (totalSessions == 0) {
      return Column(
        children: [
          const Icon(Icons.access_time, size: 48, color: _kMuted),
          const SizedBox(height: 12),
          Text(
            l10n.no_session_data,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: _kSub),
          ),
        ],
      );
    }

    final maxCount = slotOrder.fold<int>(0, (max, slot) {
      final count = (widget.readingTimeOfDay[slot]?['count'] as int?) ?? 0;
      return count > max ? count : max;
    });

    String favoriteSlot = slotOrder.first;
    int favoriteCount = 0;
    for (var slot in slotOrder) {
      final count = (widget.readingTimeOfDay[slot]?['count'] as int?) ?? 0;
      if (count > favoriteCount) {
        favoriteCount = count;
        favoriteSlot = slot;
      }
    }
    final favColor = _getSlotColor(favoriteSlot);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: favColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: favColor.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(slotIcons[favoriteSlot], size: 18, color: favColor),
              const SizedBox(width: 8),
              Text(
                l10n.favorite_reading_time(_getSlotLabel(l10n, favoriteSlot)),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _kText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ...slotOrder.map((slot) {
          final count = (widget.readingTimeOfDay[slot]?['count'] as int?) ?? 0;
          final totalMinutes =
              (widget.readingTimeOfDay[slot]?['totalMinutes'] as int?) ?? 0;
          final percentage = maxCount > 0 ? count / maxCount : 0.0;
          final isFavorite = slot == favoriteSlot;
          final color = _getSlotColor(slot);

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(slotIcons[slot], size: 20, color: color),
                        const SizedBox(width: 8),
                        Text(
                          _getSlotLabel(l10n, slot),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isFavorite ? FontWeight.bold : FontWeight.w500,
                            color: _kText,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          slotRanges[slot] ?? '',
                          style: const TextStyle(fontSize: 10, color: _kSub),
                        ),
                      ],
                    ),
                    Text(
                      count > 0
                          ? '$count${totalMinutes > 0 ? ' (${_formatMinutes(totalMinutes)})' : ''}'
                          : '0',
                      style: const TextStyle(fontSize: 12, color: _kSub),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: _kBarBg,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _formatMinutes(int totalMinutes) {
    if (totalMinutes < 60) return '${totalMinutes}m';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  Widget _buildNoData() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          AppLocalizations.of(context)!.no_data,
          style: const TextStyle(fontSize: 14, color: _kSub),
        ),
      ),
    );
  }

  String _getSeasonName(AppLocalizations l10n, String season) {
    switch (season) {
      case 'Winter':
        return l10n.season_winter;
      case 'Spring':
        return l10n.season_spring;
      case 'Summer':
        return l10n.season_summer;
      case 'Fall':
        return l10n.season_fall;
      default:
        return season;
    }
  }

  String _getSeasonEmoji(String season) {
    switch (season) {
      case 'Winter':
        return '❄️';
      case 'Spring':
        return '🌸';
      case 'Summer':
        return '☀️';
      case 'Fall':
        return '🍂';
      default:
        return '📚';
    }
  }

  Color _getSeasonColor(String season) {
    switch (season) {
      case 'Winter':
        return _kSecondary;
      case 'Spring':
        return _kPrimary;
      case 'Summer':
        return const Color(0xFFBC92A6);
      case 'Fall':
        return _kPrimary.withValues(alpha: 0.8);
      default:
        return _kSub;
    }
  }

  String _getSlotLabel(AppLocalizations l10n, String slot) {
    switch (slot) {
      case 'late_night':
        return l10n.time_slot_late_night;
      case 'morning':
        return l10n.time_slot_morning;
      case 'afternoon':
        return l10n.time_slot_afternoon;
      case 'night':
        return l10n.time_slot_night;
      default:
        return slot;
    }
  }

  Color _getSlotColor(String slot) {
    switch (slot) {
      case 'late_night':
        return _kSecondary;
      case 'morning':
        return _kPrimary;
      case 'afternoon':
        return const Color(0xFFBC92A6);
      case 'night':
        return _kPrimary.withValues(alpha: 0.8);
      default:
        return _kSub;
    }
  }
}

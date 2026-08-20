import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book.dart';

/// New "Top Rankings" statistics screen matching the redesigned UI.
///
/// Shows the top genres, editorials and authors as horizontal fill-bar
/// charts. A toggle lets the user switch between all owned books and only
/// books already read. Each bar also shows the average rating of the
/// matching books when available.
class TopRankingsScreen extends StatefulWidget {
  final List<Book> books;

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

  const TopRankingsScreen({super.key, required this.books});

  @override
  State<TopRankingsScreen> createState() => _TopRankingsScreenState();
}

class _TopRankingsScreenState extends State<TopRankingsScreen> {
  static const _kBg = TopRankingsScreen.kBg;
  static const _kPrimary = TopRankingsScreen.kPrimary;
  static const _kSecondary = TopRankingsScreen.kSecondary;
  static const _kTertiary = TopRankingsScreen.kTertiary;
  static const _kText = TopRankingsScreen.kText;
  static const _kSub = TopRankingsScreen.kSub;
  static const _kBorder = TopRankingsScreen.kBorder;
  static const _kBarBg = TopRankingsScreen.kBarBg;

  bool _showReadBooks = false;
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

  List<_RankingEntry> _computeEntries(
    String Function(Book) extractor,
    int topN,
  ) {
    final counts = <String, int>{};
    final ratingTotals = <String, double>{};
    final ratingCounts = <String, int>{};

    for (var book in widget.books) {
      final isRead = book.readCount != null && book.readCount! > 0;
      if (_showReadBooks && !isRead) continue;

      final value = extractor(book);
      if (value.isEmpty) continue;

      final multiplier =
          (book.isBundle == true &&
                  book.bundleCount != null &&
                  book.bundleCount! > 0)
              ? book.bundleCount!
              : 1;

      counts[value] = (counts[value] ?? 0) + multiplier;
      if (book.myRating != null && book.myRating! > 0) {
        ratingTotals[value] = (ratingTotals[value] ?? 0) + book.myRating!;
        ratingCounts[value] = (ratingCounts[value] ?? 0) + 1;
      }
    }

    final sorted =
        counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(topN).map((entry) {
      final avgRating =
          ratingCounts.containsKey(entry.key)
              ? ratingTotals[entry.key]! / ratingCounts[entry.key]!
              : 0.0;
      return _RankingEntry(
        name: entry.key,
        count: entry.value,
        avgRating: avgRating,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final sections = [
      _RankingSection(
        key: 'genres',
        title: l10n.top_5_genres,
        color: _kSecondary,
        extractor: (book) => book.genre ?? '',
        topN: 5,
      ),
      _RankingSection(
        key: 'editorials',
        title: l10n.top_10_editorials,
        color: _kTertiary,
        extractor: (book) => book.editorialValue ?? '',
        topN: 10,
      ),
      _RankingSection(
        key: 'authors',
        title: l10n.top_10_authors,
        color: _kSecondary,
        extractor: (book) => book.author ?? '',
        topN: 10,
      ),
    ];

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
          l10n.section_top_rankings,
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
            _buildToggle(l10n),
            const SizedBox(height: 20),
            ...sections.asMap().entries.map((entry) {
              final index = entry.key;
              final section = entry.value;
              return Column(
                children: [
                  _buildRankingCard(section),
                  if (index < sections.length - 1) const SizedBox(height: 16),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.all_label,
            style: TextStyle(
              fontSize: 13,
              color: _showReadBooks ? _kSub : _kPrimary,
              fontWeight: _showReadBooks ? FontWeight.normal : FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: _showReadBooks,
            activeThumbColor: _kPrimary,
            activeTrackColor: _kSecondary,
            inactiveThumbColor: _kSecondary,
            inactiveTrackColor: _kBarBg,
            onChanged: (val) => setState(() => _showReadBooks = val),
          ),
          const SizedBox(width: 8),
          Text(
            l10n.read_label,
            style: TextStyle(
              fontSize: 13,
              color: _showReadBooks ? _kPrimary : _kSub,
              fontWeight: _showReadBooks ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingCard(_RankingSection section) {
    final entries = _computeEntries(section.extractor, section.topN);
    final isCollapsed = _collapsedSections.contains(section.key);
    final maxValue = entries.isNotEmpty ? entries.first.count : 1;

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
            onTap: () => _toggleSection(section.key),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    section.title,
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
                      child:
                          entries.isEmpty
                              ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    AppLocalizations.of(context)!.no_data,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: _kSub,
                                    ),
                                  ),
                                ),
                              )
                              : Column(
                                children:
                                    entries.map((entry) {
                                      final percentage = entry.count / maxValue;
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 5,
                                        ),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 100,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    entry.name,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: _kSub,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  if (entry.avgRating > 0)
                                                    Text(
                                                      '★ ${entry.avgRating.toStringAsFixed(1)}',
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        color: _kSecondary,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: _buildBar(
                                                percentage: percentage,
                                                value: '${entry.count}',
                                                barColor: section.color,
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
}

class _RankingEntry {
  final String name;
  final int count;
  final double avgRating;

  _RankingEntry({
    required this.name,
    required this.count,
    required this.avgRating,
  });
}

class _RankingSection {
  final String key;
  final String title;
  final Color color;
  final String Function(Book) extractor;
  final int topN;

  _RankingSection({
    required this.key,
    required this.title,
    required this.color,
    required this.extractor,
    required this.topN,
  });
}

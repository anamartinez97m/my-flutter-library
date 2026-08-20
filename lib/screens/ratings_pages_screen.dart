import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';

/// New "Ratings & Pages" statistics screen matching the redesigned UI.
///
/// Preserves the original content of the section (average rating, page
/// count distribution, rating distribution and book extremes) while
/// adopting the v2 visual language used across the redesigned statistics
/// screens. Each section is collapsible.
class RatingsPagesScreen extends StatefulWidget {
  final double averageRating;
  final int ratedBooksCount;
  final Map<String, int> ratingDistribution;
  final Map<String, int> pageDistribution;
  final int? oldestYear;
  final String? oldestBookName;
  final int? newestYear;
  final String? newestBookName;
  final int? shortestPages;
  final String? shortestBookName;
  final int? longestPages;
  final String? longestBookName;

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

  const RatingsPagesScreen({
    super.key,
    required this.averageRating,
    required this.ratedBooksCount,
    required this.ratingDistribution,
    required this.pageDistribution,
    this.oldestYear,
    this.oldestBookName,
    this.newestYear,
    this.newestBookName,
    this.shortestPages,
    this.shortestBookName,
    this.longestPages,
    this.longestBookName,
  });

  @override
  State<RatingsPagesScreen> createState() => _RatingsPagesScreenState();
}

class _RatingsPagesScreenState extends State<RatingsPagesScreen> {
  static const _kBg = RatingsPagesScreen.kBg;
  static const _kPrimary = RatingsPagesScreen.kPrimary;
  static const _kSecondary = RatingsPagesScreen.kSecondary;
  static const _kTertiary = RatingsPagesScreen.kTertiary;
  static const _kText = RatingsPagesScreen.kText;
  static const _kSub = RatingsPagesScreen.kSub;
  static const _kBorder = RatingsPagesScreen.kBorder;
  static const _kDivider = RatingsPagesScreen.kDivider;
  static const _kBarBg = RatingsPagesScreen.kBarBg;

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
          l10n.section_ratings_pages,
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
              sectionKey: 'average_rating',
              title: l10n.average_rating,
              child: _buildAverageRatingContent(context, l10n),
            ),
            const SizedBox(height: 16),
            _buildCollapsibleCard(
              sectionKey: 'page_distribution',
              title: l10n.page_count_distribution,
              child: _buildDistributionContent(
                distribution: widget.pageDistribution,
                barColor: _kTertiary,
                labelBuilder:
                    (key) => Text(
                      key,
                      style: const TextStyle(fontSize: 12, color: _kSub),
                    ),
              ),
            ),
            const SizedBox(height: 16),
            _buildCollapsibleCard(
              sectionKey: 'rating_distribution',
              title: l10n.books_by_rating_distribution,
              child: _buildDistributionContent(
                distribution: widget.ratingDistribution,
                barColor: _kSecondary,
                labelBuilder: _buildRatingLabel,
              ),
            ),
            const SizedBox(height: 16),
            _buildCollapsibleCard(
              sectionKey: 'book_extremes',
              title: l10n.book_extremes,
              child: _buildExtremesContent(l10n),
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

  Widget _buildAverageRatingContent(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              widget.averageRating.toStringAsFixed(2),
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: _kSecondary,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.star, color: _kSecondary, size: 34),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l10n.based_on_rated_books(widget.ratedBooksCount.toString()),
          style: const TextStyle(fontSize: 13, color: _kSub),
        ),
      ],
    );
  }

  /// Renders a rating distribution bucket key (e.g. "5.0", "4.0-4.9",
  /// "Unrated") as its leading star count plus a sparkle icon, keeping the
  /// "Unrated" bucket as plain text since it has no numeric rating.
  Widget _buildRatingLabel(String key) {
    if (key == 'Unrated') {
      return const Text(
        'Unrated',
        style: TextStyle(fontSize: 12, color: _kSub),
      );
    }
    final stars = key.split('.').first;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          stars,
          style: const TextStyle(
            fontSize: 12,
            color: _kSub,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 2),
        const Icon(Icons.auto_awesome, size: 12, color: _kSub),
      ],
    );
  }

  Widget _buildDistributionContent({
    required Map<String, int> distribution,
    required Color barColor,
    required Widget Function(String) labelBuilder,
  }) {
    final maxValue =
        distribution.values.isEmpty
            ? 0
            : distribution.values.reduce((a, b) => a > b ? a : b);

    return Column(
      children:
          distribution.entries.map((entry) {
            final percentage = maxValue > 0 ? (entry.value / maxValue) : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(width: 72, child: labelBuilder(entry.key)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // The number label starts right after the 8px
                        // horizontal padding of the overlay container. Once
                        // the bar's leading edge reaches that point, the
                        // number sits on top of the colored bar and should
                        // switch to white for better contrast.
                        final barPixelWidth = constraints.maxWidth * percentage;
                        final textColor =
                            barPixelWidth >= 8 ? Colors.white : _kText;
                        return Stack(
                          children: [
                            Container(
                              height: 22,
                              decoration: BoxDecoration(
                                color: _kBarBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: percentage,
                              child: Container(
                                height: 22,
                                decoration: BoxDecoration(
                                  color: barColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                            Container(
                              height: 22,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${entry.value}',
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
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildExtremesContent(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildExtremeRow(
          icon: Icons.calendar_today,
          color: _kSecondary,
          label1: l10n.oldest,
          value1: widget.oldestYear != null ? '${widget.oldestYear}' : 'N/A',
          book1: widget.oldestBookName,
          label2: l10n.newest,
          value2: widget.newestYear != null ? '${widget.newestYear}' : 'N/A',
          book2: widget.newestBookName,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Divider(height: 1, thickness: 1, color: _kDivider),
        ),
        _buildExtremeRow(
          icon: Icons.menu_book,
          color: _kTertiary,
          label1: l10n.shortest,
          value1:
              widget.shortestPages != null
                  ? '${widget.shortestPages} pg'
                  : 'N/A',
          book1: widget.shortestBookName,
          label2: l10n.longest,
          value2:
              widget.longestPages != null ? '${widget.longestPages} pg' : 'N/A',
          book2: widget.longestBookName,
        ),
      ],
    );
  }

  Widget _buildExtremeRow({
    required IconData icon,
    required Color color,
    required String label1,
    required String value1,
    String? book1,
    required String label2,
    required String value2,
    String? book2,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildExtremeColumn(
                  label: label1,
                  value: value1,
                  book: book1,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildExtremeColumn(
                  label: label2,
                  value: value2,
                  book: book2,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExtremeColumn({
    required String label,
    required String value,
    String? book,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: _kSub)),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        if (book != null)
          Text(
            book,
            style: const TextStyle(fontSize: 12, color: _kSub),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}

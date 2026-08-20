import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/widgets/book_card_v2.dart';
import 'package:myrandomlibrary/widgets/quick_add_book_dialog.dart';
import 'package:provider/provider.dart';

// ── v2 design tokens ─────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF43102B);
const _kBg = Color(0xFFFDF8F6);
const _kBorder = Color(0xFFCEC5BE);
const _kDivider = Color(0xFFE6E2DF);
const _kText = Color(0xFF5F5E5C);
const _kSub = Color(0xFF514348);
const _kCardShadow = [
  BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
];

class BooksBySagaScreen extends StatelessWidget {
  final String sagaName;
  final String? sagaUniverse;
  final bool isSagaUniverse;

  const BooksBySagaScreen({
    super.key,
    required this.sagaName,
    this.sagaUniverse,
    this.isSagaUniverse = false,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookProvider?>(context);

    if (provider == null || provider.isLoading) {
      return Scaffold(
        backgroundColor: _kBg,
        appBar: _buildAppBar(context),
        body: const Center(child: CircularProgressIndicator(color: _kPrimary)),
      );
    }

    // Filter books by saga or saga universe
    final filteredBooks =
        provider.allBooks.where((book) {
          if (isSagaUniverse) {
            return book.sagaUniverse?.toLowerCase() == sagaName.toLowerCase();
          } else {
            return book.saga?.toLowerCase() == sagaName.toLowerCase();
          }
        }).toList();

    // Sort by saga number if available
    filteredBooks.sort((a, b) {
      final aSagaNum = int.tryParse(a.nSaga ?? '');
      final bSagaNum = int.tryParse(b.nSaga ?? '');

      if (aSagaNum != null && bSagaNum != null) {
        return aSagaNum.compareTo(bSagaNum);
      } else if (aSagaNum != null) {
        return -1;
      } else if (bSagaNum != null) {
        return 1;
      }

      // Fallback to name sorting
      return (a.name ?? '').compareTo(b.name ?? '');
    });

    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(context),
      floatingActionButton: FloatingActionButton(
        heroTag: 'saga_quick_add',
        onPressed: () => _showQuickAdd(context, provider),
        backgroundColor: _kPrimary,
        elevation: 6,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body:
          filteredBooks.isEmpty
              ? _buildEmptyState(context)
              : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildSummaryCard(context, filteredBooks.length),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => BookCardV2(
                          book: filteredBooks[index],
                          enabledCardFields: const {
                            'title',
                            'author',
                            'saga',
                            'saga_universe',
                            'format',
                          },
                        ),
                        childCount: filteredBooks.length,
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _kBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: _kPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        isSagaUniverse
            ? '${AppLocalizations.of(context)!.saga_universe}: $sagaName'
            : '${AppLocalizations.of(context)!.saga}: $sagaName',
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _kPrimary,
          letterSpacing: -0.5,
        ),
      ),
      centerTitle: true,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: _kBorder),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, int totalBooks) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
        boxShadow: _kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.collections_bookmark_outlined,
                size: 18,
                color: _kPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.total_books,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                  letterSpacing: 0.26,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$totalBooks',
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: _kPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.books_word,
                style: const TextStyle(fontSize: 14, color: _kSub),
              ),
            ],
          ),
          if (!isSagaUniverse && sagaUniverse != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 1, color: _kDivider),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.public_outlined, size: 16, color: _kText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${AppLocalizations.of(context)!.saga_universe}: $sagaUniverse',
                    style: const TextStyle(
                      fontSize: 13,
                      color: _kText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.collections_bookmark_outlined,
              size: 64,
              color: _kPrimary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.no_books_in_saga(
                isSagaUniverse
                    ? AppLocalizations.of(context)!.saga_universe
                    : AppLocalizations.of(context)!.saga,
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showQuickAdd(
    BuildContext context,
    BookProvider provider,
  ) async {
    final result = await showDialog<int>(
      context: context,
      builder:
          (context) => QuickAddBookDialog(
            sagaName: isSagaUniverse ? null : sagaName,
            sagaUniverse: isSagaUniverse ? sagaName : sagaUniverse,
          ),
    );

    if (result != null && result > 0) {
      provider.loadBooks();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.added_books_to_saga(
                result.toString(),
                isSagaUniverse
                    ? AppLocalizations.of(context)!.saga_universe
                    : AppLocalizations.of(context)!.saga,
              ),
            ),
          ),
        );
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/screens/new_ui/new_book_detail.dart';
import 'package:myrandomlibrary/widgets/random_shimmer.dart';
import 'package:myrandomlibrary/widgets/shimmer_loading.dart';

const _kBg = Color(0xFFFDF8F6);
const _kPrimary = Color(0xFF43102B);
const _kSub = Color(0xFF514348);
const _kCardShadow = [
  BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
];

/// Wraps a new-UI sub-screen pushed from the random tab so it keeps the
/// Manrope font used inside the navigation shell.
Widget withManrope(BuildContext context, Widget child) {
  final base = Theme.of(context);
  return Theme(
    data: base.copyWith(textTheme: base.textTheme.apply(fontFamily: 'Manrope')),
    child: child,
  );
}

/// App bar shared by the random sub-screens.
PreferredSizeWidget randomAppBar(BuildContext context, String title) {
  return AppBar(
    backgroundColor: _kBg,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: _kPrimary),
      onPressed: () => Navigator.pop(context),
    ),
    title: Text(
      title,
      style: const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: _kPrimary,
      ),
    ),
  );
}

/// Scrolls [controller] to the end once the freshly picked result is laid out.
void scrollToRandomResult(ScrollController controller) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!controller.hasClients) return;
    controller.animateTo(
      controller.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  });
}

/// Layout for a random sub-screen: scrollable [children], the picked
/// [randomBook] below them and the pick / clear buttons pinned at the bottom.
class RandomPickScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Book? randomBook;
  final VoidCallback? onPick;
  final String pickLabel;
  final VoidCallback onClear;
  final String? clearLabel;
  final ScrollController? scrollController;
  final bool isLoading;

  const RandomPickScaffold({
    super.key,
    required this.title,
    required this.children,
    required this.randomBook,
    required this.onPick,
    required this.pickLabel,
    required this.onClear,
    this.clearLabel,
    this.scrollController,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return withManrope(
      context,
      Scaffold(
        backgroundColor: _kBg,
        appBar: randomAppBar(context, title),
        body:
            isLoading
                ? const ShimmerLoading(child: RandomShimmer())
                : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ...children,
                            if (randomBook != null) ...[
                              const SizedBox(height: 24),
                              RandomResultCard(
                                book: randomBook!,
                                onTryAnother: onPick,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    _buildActionButtons(l10n),
                  ],
                ),
      ),
    );
  }

  Widget _buildActionButtons(AppLocalizations l10n) {
    return Container(
      decoration: const BoxDecoration(
        color: _kBg,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: onPick == null ? 0.5 : 1,
              child: GestureDetector(
                onTap: onPick,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _kPrimary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33430E29),
                        blurRadius: 8,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.casino, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          pickLabel,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.26,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: onClear,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: Center(
                  child: Text(
                    clearLabel ?? l10n.clear_filters,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                      letterSpacing: 0.26,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The randomly picked book; tapping it opens its detail screen.
class RandomResultCard extends StatelessWidget {
  final Book book;
  final VoidCallback? onTryAnother;

  const RandomResultCard({super.key, required this.book, this.onTryAnother});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NewBookDetailScreen(book: book)),
          ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x4DCEC5BE)),
          boxShadow: _kCardShadow,
        ),
        child: Column(
          children: [
            const Icon(Icons.auto_stories, size: 48, color: _kPrimary),
            const SizedBox(height: 16),
            Text(
              book.name ?? l10n.unknown,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _kPrimary,
              ),
            ),
            if (book.author != null) ...[
              const SizedBox(height: 6),
              Text(
                'by ${book.author}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: _kSub),
              ),
            ],
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onTryAnother,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _kPrimary,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  l10n.try_another,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tap_to_view_details,
              style: const TextStyle(
                fontSize: 12,
                color: _kSub,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

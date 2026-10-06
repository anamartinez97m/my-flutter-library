import 'package:flutter/material.dart';
import 'package:myrandomlibrary/config/v2_design_system.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/screens/new_ui/new_book_detail.dart';
import 'package:provider/provider.dart';

/// Re-reads detail screen matching the redesigned (v2) UI.
///
/// Lists all books that have been read more than once, sorted by re-read
/// count. Tapping a book opens the v2 book detail.
class RereadsDetailScreen extends StatelessWidget {
  static const kBg = V2Colors.background;
  static const kPrimary = V2Colors.primary;
  static const kSecondary = V2Colors.secondary;
  static const kMuted = V2Colors.border;
  static const kText = V2Colors.textPrimary;
  static const kSub = V2Colors.textSecondary;
  static const kBorder = Color(0x4DD5C2C7); // Exact alpha variant.

  const RereadsDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.re_read_books,
          style: const TextStyle(
            fontFamily: V2Typography.family,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: kPrimary,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: V2Colors.border),
        ),
      ),
      body: Consumer<BookProvider>(
        builder: (context, provider, child) {
          final books = provider.allBooks;

          // Filter books that have been read more than once
          final rereadBooks =
              books.where((book) {
                return book.readCount != null && book.readCount! > 1;
              }).toList();

          // Sort by read count (most re-read first)
          rereadBooks.sort((a, b) {
            final countA = a.readCount ?? 0;
            final countB = b.readCount ?? 0;
            return countB.compareTo(countA);
          });

          if (rereadBooks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.replay, size: 64, color: kMuted),
                  const SizedBox(height: 16),
                  Text(
                    l10n.no_re_read_books_yet,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: kSub,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: 20,
            ),
            itemCount: rereadBooks.length + 1,
            itemBuilder: (context, index) {
              // Add SizedBox at the end
              if (index == rereadBooks.length) {
                return const SizedBox(height: 50);
              }

              final book = rereadBooks[index];
              final readCount = book.readCount ?? 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NewBookDetailScreen(book: book),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kBorder),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 6,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: kSecondary,
                          child: Text(
                            '${readCount}x',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book.name ?? l10n.unknown,
                                style: const TextStyle(
                                  fontFamily: V2Typography.family,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: kText,
                                ),
                              ),
                              if (book.author != null &&
                                  book.author!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  book.author!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: kSub,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Text(
                                l10n.read_n_times(readCount.toString()),
                                style: const TextStyle(
                                  color: kSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: kPrimary),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

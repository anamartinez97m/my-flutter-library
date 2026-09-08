import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/repositories/book_competition_repository.dart';

// ── v2 design tokens ─────────────────────────────────────────────────────────
const _kBg = Color(0xFFFDF8F6);
const _kPrimary = Color(0xFF43102B);
const _kSub = Color(0xFF514348);
const _kText = Color(0xFF1C1B1A);
const _kBorder = Color(0xFFD5C2C7);

class NewMonthlyWinnerSelectionScreen extends StatefulWidget {
  final int year;
  final int month;

  const NewMonthlyWinnerSelectionScreen({
    super.key,
    required this.year,
    required this.month,
  });

  @override
  State<NewMonthlyWinnerSelectionScreen> createState() =>
      _NewMonthlyWinnerSelectionScreenState();
}

class _NewMonthlyWinnerSelectionScreenState
    extends State<NewMonthlyWinnerSelectionScreen> {
  List<Book> books = [];
  bool isLoading = true;
  int? selectedBookId;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() => isLoading = true);

    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookCompetitionRepository(db);
      final monthBooks = await repository.getBooksReadInMonth(
        widget.year,
        widget.month,
      );

      if (mounted) {
        setState(() {
          books = monthBooks;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading books: $e')));
      }
    }
  }

  Future<void> _saveWinner() async {
    if (selectedBookId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.please_select_book),
        ),
      );
      return;
    }

    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookCompetitionRepository(db);

      final selectedBook = books.firstWhere(
        (book) => book.bookId == selectedBookId,
      );

      await repository.saveMonthlyWinner(
        widget.year,
        widget.month,
        selectedBook.bookId!,
        selectedBook.name!,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.selected_as_winner(selectedBook.name!),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving winner: $e')));
      }
    }
  }

  String _getMonthName(int month) {
    const monthNames = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return month >= 1 && month <= 12 ? monthNames[month] : '';
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
          l10n.select_winner_title(
            '${_getMonthName(widget.month)} ${widget.year}',
          ),
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _kPrimary,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator(color: _kPrimary))
              : books.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.menu_book_outlined,
                      size: 64,
                      color: _kBorder,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.no_books_this_month,
                      style: const TextStyle(fontSize: 16, color: _kSub),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      itemCount: books.length,
                      itemBuilder: (context, index) {
                        final book = books[index];
                        final isSelected = selectedBookId == book.bookId;

                        return _buildBookCard(book, isSelected, l10n);
                      },
                    ),
                  ),
                  if (selectedBookId != null) _buildConfirmButton(l10n),
                  SizedBox(
                    height: 40 + MediaQuery.of(context).viewPadding.bottom,
                  ),
                ],
              ),
    );
  }

  Widget _buildBookCard(Book book, bool isSelected, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedBookId = isSelected ? null : book.bookId;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                isSelected ? _kPrimary.withValues(alpha: 0.06) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isSelected
                      ? _kPrimary.withValues(alpha: 0.3)
                      : const Color(0x1A27231E),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: _kPrimary.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                    : [
                      const BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 6,
                        offset: Offset(0, 4),
                      ),
                    ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.name ?? l10n.unknown,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? _kPrimary : _kText,
                      ),
                    ),
                    if (book.author != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${l10n.author}: ${book.author}',
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          color: _kSub,
                        ),
                      ),
                    ],
                    if (book.myRating != null && book.myRating! > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${l10n.rating}: ${book.myRating!.toStringAsFixed(2)}/5',
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          color: _kSub,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isSelected ? _kPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? _kPrimary : _kBorder,
                    width: isSelected ? 2 : 1.5,
                  ),
                ),
                child:
                    isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmButton(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _saveWinner,
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Text(
            l10n.select,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

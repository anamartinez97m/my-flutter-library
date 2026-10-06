import 'package:flutter/material.dart';
import 'package:myrandomlibrary/config/v2_design_system.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/repositories/book_competition_repository.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';

class NewSemifinalWinnerSelectionScreen extends StatefulWidget {
  final int year;
  final int roundNumber;

  const NewSemifinalWinnerSelectionScreen({
    super.key,
    required this.year,
    required this.roundNumber,
  });

  @override
  State<NewSemifinalWinnerSelectionScreen> createState() =>
      _NewSemifinalWinnerSelectionScreenState();
}

class _NewSemifinalWinnerSelectionScreenState
    extends State<NewSemifinalWinnerSelectionScreen> {
  List<Book> quarterlyWinnerBooks = [];
  bool isLoading = true;
  int? selectedBookId;

  @override
  void initState() {
    super.initState();
    _loadQuarterlyWinners();
  }

  Future<void> _loadQuarterlyWinners() async {
    setState(() => isLoading = true);

    try {
      final db = await DatabaseHelper.instance.database;
      final competitionRepository = BookCompetitionRepository(db);
      final bookRepository = BookRepository(db);

      final competitionResult = await competitionRepository
          .getCompetitionResults(widget.year);

      if (competitionResult != null) {
        final requiredQuarters = widget.roundNumber == 1 ? [1, 3] : [2, 4];

        final availableQuarterlyWinners =
            competitionResult.quarterlyWinners
                .where((q) => requiredQuarters.contains(q.quarter))
                .toList();

        List<Book> books = [];
        for (final quarterlyWinner in availableQuarterlyWinners) {
          final book = await bookRepository.getBookById(
            quarterlyWinner.winner.bookId,
          );
          if (book != null) {
            books.add(book);
          }
        }

        if (mounted) {
          setState(() {
            quarterlyWinnerBooks = books;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading quarterly winners: $e')),
        );
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

      final selectedBook = quarterlyWinnerBooks.firstWhere(
        (book) => book.bookId == selectedBookId,
      );

      await repository.saveSemifinalWinner(
        widget.year,
        widget.roundNumber,
        selectedBook.bookId!,
        selectedBook.name!,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving winner: $e')));
      }
    }
  }

  String _getSemifinalName(int roundNumber) {
    return '${AppLocalizations.of(context)!.semifinal} ${roundNumber.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: V2Colors.background,
      appBar: AppBar(
        backgroundColor: V2Colors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: V2Colors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.select_winner_title(
            '${_getSemifinalName(widget.roundNumber)} ${widget.year}',
          ),
          style: const TextStyle(
            fontFamily: V2Typography.family,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: V2Colors.primary,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: V2Colors.border),
        ),
      ),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: V2Colors.primary),
              )
              : quarterlyWinnerBooks.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.menu_book_outlined,
                      size: 64,
                      color: V2Colors.border,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.no_quarterly_winners,
                      style: const TextStyle(
                        fontSize: 16,
                        color: V2Colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  Expanded(
                    child: Center(
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                        itemCount: quarterlyWinnerBooks.length,
                        itemBuilder: (context, index) {
                          final book = quarterlyWinnerBooks[index];
                          final isSelected = selectedBookId == book.bookId;

                          return _buildBookCard(book, isSelected, l10n);
                        },
                      ),
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
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(minHeight: 100),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? V2Colors.primary.withValues(alpha: 0.06)
                    : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isSelected
                      ? V2Colors.primary.withValues(alpha: 0.3)
                      : V2Colors.borderStrong.withValues(alpha: .1),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: V2Colors.primary.withValues(alpha: 0.08),
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      book.name ?? l10n.unknown,
                      style: TextStyle(
                        fontFamily: V2Typography.family,
                        fontSize: 18,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        color:
                            isSelected
                                ? V2Colors.primary
                                : V2Colors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (book.author != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${l10n.author}: ${book.author}',
                        style: const TextStyle(
                          fontFamily: V2Typography.family,
                          fontSize: 14,
                          color: V2Colors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (book.myRating != null && book.myRating! > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${l10n.rating}: ${book.myRating!.toStringAsFixed(2)}/5',
                        style: const TextStyle(
                          fontFamily: V2Typography.family,
                          fontSize: 14,
                          color: V2Colors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isSelected ? V2Colors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? V2Colors.primary : V2Colors.border,
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
            backgroundColor: V2Colors.primary,
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
              fontFamily: V2Typography.family,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

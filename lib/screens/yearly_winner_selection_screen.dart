import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/repositories/book_competition_repository.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';

class YearlyWinnerSelectionScreen extends StatefulWidget {
  final int year;

  const YearlyWinnerSelectionScreen({super.key, required this.year});

  @override
  State<YearlyWinnerSelectionScreen> createState() =>
      _YearlyWinnerSelectionScreenState();
}

class _YearlyWinnerSelectionScreenState
    extends State<YearlyWinnerSelectionScreen> {
  List<Book> semifinalWinnerBooks = [];
  bool isLoading = true;
  int? selectedBookId;

  @override
  void initState() {
    super.initState();
    _loadSemifinalWinners();
  }

  Future<void> _loadSemifinalWinners() async {
    setState(() => isLoading = true);

    try {
      final db = await DatabaseHelper.instance.database;
      final competitionRepository = BookCompetitionRepository(db);
      final bookRepository = BookRepository(db);

      final competitionResult = await competitionRepository
          .getCompetitionResults(widget.year);

      if (competitionResult != null) {
        final semifinalWinners = competitionResult.semifinalWinners;

        // Fetch full book details for each semifinal winner
        List<Book> books = [];
        for (final semifinalWinner in semifinalWinners) {
          final book = await bookRepository.getBookById(
            semifinalWinner.winner.bookId,
          );
          if (book != null) {
            books.add(book);
          }
        }

        if (mounted) {
          setState(() {
            semifinalWinnerBooks = books;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading semifinal winners: $e')),
        );
      }
    }
  }

  Future<void> _saveWinner() async {
    if (selectedBookId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a book')));
      return;
    }

    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookCompetitionRepository(db);

      final selectedBook = semifinalWinnerBooks.firstWhere(
        (book) => book.bookId == selectedBookId,
      );

      await repository.saveYearlyWinner(
        widget.year,
        selectedBook.bookId!,
        selectedBook.name!,
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving winner: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select ${widget.year} Yearly Winner')),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : semifinalWinnerBooks.isEmpty
              ? const Center(child: Text('No semifinal winners available'))
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      itemCount: semifinalWinnerBooks.length,
                      itemBuilder: (context, index) {
                        final book = semifinalWinnerBooks[index];
                        final isSelected = selectedBookId == book.bookId;

                        return Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.8,
                            ),
                            child: Card(
                              elevation: isSelected ? 8 : 4,
                              color:
                                  isSelected
                                      ? Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer
                                      : null,
                              child: Container(
                                constraints: BoxConstraints(
                                  minHeight: 100,
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                                  title: Text(
                                    book.name ?? 'Unknown',
                                    style:
                                        isSelected
                                            ? const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            )
                                            : const TextStyle(fontSize: 18),
                                    textAlign: TextAlign.center,
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      const SizedBox(height: 8),
                                      if (book.author != null)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 4.0),
                                          child: Text(
                                            'Author: ${book.author}',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      if (book.myRating != null && book.myRating! > 0)
                                        Text(
                                          'Rating: ${book.myRating}/5',
                                          textAlign: TextAlign.center,
                                        ),
                                    ],
                                  ),
                                  trailing:
                                      isSelected
                                          ? Icon(
                                            Icons.check_circle,
                                            color:
                                                Theme.of(context).colorScheme.primary,
                                            size: 32,
                                          )
                                          : const SizedBox.shrink(),
                                  onTap: () {
                                    setState(() {
                                      selectedBookId =
                                          isSelected ? null : book.bookId;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (selectedBookId != null)
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveWinner,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                        ),
                        child: const Text(
                          'Select',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 50),
                ],
              ),
    );
  }
}

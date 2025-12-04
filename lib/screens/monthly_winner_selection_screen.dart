import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/repositories/book_competition_repository.dart';

class MonthlyWinnerSelectionScreen extends StatefulWidget {
  final int year;
  final int month;

  const MonthlyWinnerSelectionScreen({
    super.key,
    required this.year,
    required this.month,
  });

  @override
  State<MonthlyWinnerSelectionScreen> createState() =>
      _MonthlyWinnerSelectionScreenState();
}

class _MonthlyWinnerSelectionScreenState
    extends State<MonthlyWinnerSelectionScreen> {
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a book')));
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
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${selectedBook.name} selected as winner!')),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select ${_getMonthName(widget.month)} ${widget.year} Winner',
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : books.isEmpty
              ? const Center(child: Text('No books read this month'))
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: books.length,
                      itemBuilder: (context, index) {
                        final book = books[index];
                        final isSelected = selectedBookId == book.bookId;

                        return Card(
                          elevation: isSelected ? 4 : 1,
                          color:
                              isSelected
                                  ? Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer
                                  : null,
                          child: ListTile(
                            title: Text(
                              book.name ?? 'Unknown',
                              style:
                                  isSelected
                                      ? TextStyle(fontWeight: FontWeight.bold)
                                      : null,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (book.author != null)
                                  Text('Author: ${book.author}'),
                                if (book.myRating != null && book.myRating! > 0)
                                  Text('Rating: ${book.myRating}/5'),
                              ],
                            ),
                            trailing:
                                isSelected
                                    ? Icon(
                                      Icons.check_circle,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    )
                                    : null,
                            onTap: () {
                              setState(() {
                                selectedBookId =
                                    isSelected ? null : book.bookId;
                              });
                            },
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

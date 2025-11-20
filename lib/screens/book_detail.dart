import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myrandomlibrary/config/app_theme.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/model/read_date.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/screens/books_by_saga.dart';
import 'package:myrandomlibrary/screens/edit_book.dart';
import 'package:myrandomlibrary/utils/status_helper.dart';
import 'package:myrandomlibrary/utils/date_formatter.dart';
import 'package:myrandomlibrary/widgets/chronometer_widget.dart';
import 'package:myrandomlibrary/model/reading_session.dart';
import 'package:myrandomlibrary/repositories/reading_session_repository.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

class BookDetailScreen extends StatefulWidget {
  final Book book;

  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late Book _currentBook;
  List<ReadDate> _readDates = [];
  Map<int, List<ReadDate>> _bundleReadDates = {};
  List<ReadingSession> _chronometerSessions = [];
  bool _loadingReadDates = true;

  @override
  void initState() {
    super.initState();
    _currentBook = widget.book;
    _loadReadDates();
  }
  
  Future<void> _loadReadDates() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);
      final sessionRepository = ReadingSessionRepository(db);
      
      if (_currentBook.isBundle == true) {
        // Load bundle read dates
        final bundleReadDates = await repository.getAllBundleReadDates(_currentBook.bookId!);
        setState(() {
          _bundleReadDates = bundleReadDates;
          _loadingReadDates = false;
        });
      } else {
        // Load regular read dates
        final readDates = await repository.getReadDatesForBook(_currentBook.bookId!);
        // Load chronometer sessions
        final sessions = await sessionRepository.getSessionsForBook(_currentBook.bookId!);
        setState(() {
          _readDates = readDates;
          _chronometerSessions = sessions;
          _loadingReadDates = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading read dates: $e');
      setState(() {
        _loadingReadDates = false;
      });
    }
  }
  
  Future<Book?> _loadOriginalBook(int originalBookId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);
      final books = await repository.getAllBooks();
      return books.firstWhere((book) => book.bookId == originalBookId);
    } catch (e) {
      debugPrint('Error loading original book: $e');
      return null;
    }
  }
  
  Future<void> _quickStartReading() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      // Update status to "Started"
      final statusList = await repository.getLookupValues('status');
      final startedStatus = statusList.firstWhere(
        (s) => (s['value'] as String).toLowerCase() == 'started',
        orElse: () => statusList.first,
      );
      
      await db.update(
        'book',
        {
          'status_id': startedStatus['status_id'],
          'date_read_initial': today,
        },
        where: 'book_id = ?',
        whereArgs: [_currentBook.bookId!],
      );
      
      // Create a new reading session with start date
      await repository.addReadDate(ReadDate(
        bookId: _currentBook.bookId!,
        dateStarted: today,
        dateFinished: null,
      ));
      
      // Reload book data
      final updatedBooks = await repository.getAllBooks();
      final updatedBook = updatedBooks.firstWhere((b) => b.bookId == _currentBook.bookId);
      
      setState(() {
        _currentBook = updatedBook;
      });
      await _loadReadDates();
      
      // Update provider
      if (mounted) {
        final provider = Provider.of<BookProvider?>(context, listen: false);
        await provider?.loadBooks();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Started reading!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error starting reading: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _quickFinishReading() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      // Get status values
      final statusList = await repository.getLookupValues('status');
      
      // Check if there are any reading sessions
      final hasReadingSessions = _readDates.isNotEmpty;
      
      // If there are reading sessions, mark as "Yes", otherwise "No"
      final targetStatus = statusList.firstWhere(
        (s) => (s['value'] as String).toLowerCase() == (hasReadingSessions ? 'yes' : 'no'),
        orElse: () => statusList.first,
      );
      
      // Get current read count
      final currentReadCount = _currentBook.readCount ?? 0;
      
      // Update status and increment read count
      await db.update(
        'book',
        {
          'status_id': targetStatus['status_id'],
          'date_read_final': today,
          'read_count': currentReadCount + 1,
        },
        where: 'book_id = ?',
        whereArgs: [_currentBook.bookId!],
      );
      
      // If there's an open reading session, close it
      if (_readDates.isNotEmpty && _readDates.last.dateFinished == null) {
        final updatedReadDate = ReadDate(
          readDateId: _readDates.last.readDateId,
          bookId: _readDates.last.bookId,
          dateStarted: _readDates.last.dateStarted,
          dateFinished: today,
          bundleBookIndex: _readDates.last.bundleBookIndex,
        );
        await repository.updateReadDate(updatedReadDate);
      } else {
        // Create a new reading session with finish date
        await repository.addReadDate(ReadDate(
          bookId: _currentBook.bookId!,
          dateStarted: _currentBook.dateReadInitial ?? today,
          dateFinished: today,
        ));
      }
      
      // Reload book data
      final updatedBooks = await repository.getAllBooks();
      final updatedBook = updatedBooks.firstWhere((b) => b.bookId == _currentBook.bookId);
      
      setState(() {
        _currentBook = updatedBook;
      });
      await _loadReadDates();
      
      // Update provider
      if (mounted) {
        final provider = Provider.of<BookProvider?>(context, listen: false);
        await provider?.loadBooks();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marked as finished!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error finishing reading: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  List<String?> _parseBundleSagaNumbers(String numbersStr) {
    // Parse formats like "1-3", "1, 2, 3", "1,2,3"
    final List<String?> result = [];
    
    if (numbersStr.contains('-')) {
      // Range format: "1-3"
      final parts = numbersStr.split('-');
      if (parts.length == 2) {
        final start = int.tryParse(parts[0].trim());
        final end = int.tryParse(parts[1].trim());
        if (start != null && end != null) {
          for (int i = start; i <= end; i++) {
            result.add(i.toString());
          }
        }
      }
    } else if (numbersStr.contains(',')) {
      // Comma-separated format: "1, 2, 3"
      final parts = numbersStr.split(',');
      for (final part in parts) {
        final trimmed = part.trim();
        if (trimmed.isNotEmpty) {
          result.add(trimmed);
        }
      }
    } else {
      // Single number
      result.add(numbersStr.trim());
    }
    
    return result;
  }
  
  List<Widget> _buildBundleBooksList() {
    List<String?>? titles;
    List<int?>? pages;
    List<int?>? pubYears;
    List<String?>? sagaNumbers;
    
    try {
      if (_currentBook.bundleTitles != null) {
        final List<dynamic> titlesData = jsonDecode(_currentBook.bundleTitles!);
        titles = titlesData.map((t) => t as String?).toList();
      }
    } catch (e) {
      titles = null;
    }
    
    try {
      if (_currentBook.bundlePages != null) {
        final List<dynamic> pagesData = jsonDecode(_currentBook.bundlePages!);
        pages = pagesData.map((p) => p as int?).toList();
      }
    } catch (e) {
      pages = null;
    }
    
    try {
      if (_currentBook.bundlePublicationYears != null) {
        final List<dynamic> yearsData = jsonDecode(_currentBook.bundlePublicationYears!);
        pubYears = yearsData.map((y) => y as int?).toList();
      }
    } catch (e) {
      pubYears = null;
    }
    
    // Parse saga numbers from bundleNumbers string
    if (_currentBook.bundleNumbers != null && _currentBook.bundleNumbers!.isNotEmpty) {
      sagaNumbers = _parseBundleSagaNumbers(_currentBook.bundleNumbers!);
    }
    
    final maxLength = [
      titles?.length ?? 0,
      pages?.length ?? 0,
      pubYears?.length ?? 0,
      sagaNumbers?.length ?? 0,
      _currentBook.bundleCount ?? 0,
    ].reduce((a, b) => a > b ? a : b);
    
    return List.generate(maxLength, (index) {
      final title = titles != null && index < titles.length ? titles[index] : null;
      final pageCount = pages != null && index < pages.length ? pages[index] : null;
      final pubYear = pubYears != null && index < pubYears.length ? pubYears[index] : null;
      final sagaNum = sagaNumbers != null && index < sagaNumbers.length ? sagaNumbers[index] : null;
      final hasReadDates = _bundleReadDates.containsKey(index) && 
                           _bundleReadDates[index]!.any((d) => d.dateFinished != null && d.dateFinished!.isNotEmpty);
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: hasReadDates ? Colors.green : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: hasReadDates ? Colors.white : Colors.grey[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (sagaNum != null && sagaNum.isNotEmpty)
                    Text(
                      'Saga #$sagaNum',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (title != null && title.isNotEmpty)
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (pageCount != null || pubYear != null)
                    Text(
                      [
                        if (pageCount != null) '$pageCount pages',
                        if (pubYear != null) 'Pub. $pubYear',
                      ].join(' • '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  String _formatDateTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
          '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoString.split('T')[0]; // Fallback to date only
    }
  }

  /// Convert database status values to user-friendly display values
  String _getStatusDisplayValue(String dbValue) {
    final lowerValue = dbValue.toLowerCase();

    // Check if status should be "Started" based on read dates
    if (lowerValue == 'no' &&
        _currentBook.dateReadInitial != null &&
        _currentBook.dateReadFinal == null) {
      return 'Started';
    }

    // Use StatusHelper for consistent labeling
    return StatusHelper.getDisplayLabel(dbValue);
  }

  /// Build publication info - shows year and optionally full date for TBReleased books
  List<Widget> _buildPublicationInfo(int pubYearOrDate) {
    final widgets = <Widget>[];

    // Check if it's a full date (YYYYMMDD format, > 9999)
    if (pubYearOrDate > 9999) {
      final year = pubYearOrDate ~/ 10000;
      final month = (pubYearOrDate % 10000) ~/ 100;
      final day = pubYearOrDate % 100;

      // Add year card
      widgets.add(
        _DetailCard(
          icon: Icons.calendar_today,
          label: 'Original Publication Year',
          value: year.toString(),
        ),
      );

      // Add full date card
      widgets.add(
        _DetailCard(
          icon: Icons.event,
          label: 'Original Publication Date',
          value:
              '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year',
        ),
      );
    } else {
      // Just a year
      widgets.add(
        _DetailCard(
          icon: Icons.calendar_today,
          label: 'Original Publication Year',
          value: pubYearOrDate.toString(),
        ),
      );
    }

    return widgets;
  }

  Future<void> _deleteBook(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: Text(
              'Are you sure you want to delete "${_currentBook.name}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true && _currentBook.bookId != null) {
      try {
        final db = await DatabaseHelper.instance.database;
        final repository = BookRepository(db);
        await repository.deleteBook(_currentBook.bookId!);

        if (context.mounted) {
          final provider = Provider.of<BookProvider?>(context, listen: false);
          await provider?.loadBooks();

          Navigator.pop(context); // Go back to list

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Book deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting book: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (!didPop) {
          // Go back to previous screen (list)
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Book Details'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final updatedBook = await Navigator.push<Book>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditBookScreen(book: _currentBook),
                  ),
                );
                if (updatedBook != null && mounted) {
                  setState(() {
                    _currentBook = updatedBook;
                  });
                  // Reload read dates after edit
                  await _loadReadDates();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteBook(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image placeholder
              Container(
                height: 180,
                color: Colors.grey[300],
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.book, size: 60, color: Colors.grey),
                      SizedBox(height: 6),
                      Text(
                        'Image coming soon',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with TBR toggle
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _currentBook.name ?? 'Unknown Title',
                            style: Theme.of(
                              context,
                            ).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _currentBook.tbr == true 
                                ? Icons.bookmark 
                                : Icons.bookmark_border,
                            color: _currentBook.tbr == true 
                                ? Theme.of(context).colorScheme.primary 
                                : Colors.grey,
                          ),
                          onPressed: () async {
                            try {
                              final db = await DatabaseHelper.instance.database;
                              final repository = BookRepository(db);
                              
                              // Toggle TBR status
                              final updatedBook = Book(
                                bookId: _currentBook.bookId,
                                name: _currentBook.name,
                                isbn: _currentBook.isbn,
                                asin: _currentBook.asin,
                                author: _currentBook.author,
                                saga: _currentBook.saga,
                                nSaga: _currentBook.nSaga,
                                sagaUniverse: _currentBook.sagaUniverse,
                                formatSagaValue: _currentBook.formatSagaValue,
                                pages: _currentBook.pages,
                                originalPublicationYear: _currentBook.originalPublicationYear,
                                loaned: _currentBook.loaned,
                                statusValue: _currentBook.statusValue,
                                editorialValue: _currentBook.editorialValue,
                                languageValue: _currentBook.languageValue,
                                placeValue: _currentBook.placeValue,
                                formatValue: _currentBook.formatValue,
                                createdAt: _currentBook.createdAt,
                                genre: _currentBook.genre,
                                dateReadInitial: _currentBook.dateReadInitial,
                                dateReadFinal: _currentBook.dateReadFinal,
                                readCount: _currentBook.readCount,
                                myRating: _currentBook.myRating,
                                myReview: _currentBook.myReview,
                                isBundle: _currentBook.isBundle,
                                bundleCount: _currentBook.bundleCount,
                                bundleNumbers: _currentBook.bundleNumbers,
                                bundleStartDates: _currentBook.bundleStartDates,
                                bundleEndDates: _currentBook.bundleEndDates,
                                bundlePages: _currentBook.bundlePages,
                                bundlePublicationYears: _currentBook.bundlePublicationYears,
                                bundleTitles: _currentBook.bundleTitles,
                                tbr: !(_currentBook.tbr == true), // Toggle
                                isTandem: _currentBook.isTandem,
                              );
                              
                              await repository.deleteBook(_currentBook.bookId!);
                              await repository.addBook(updatedBook);
                              
                              // Reload provider first
                              if (mounted) {
                                final provider = Provider.of<BookProvider?>(context, listen: false);
                                await provider?.loadBooks();
                              }
                              
                              // Then update local state
                              setState(() {
                                _currentBook = updatedBook;
                              });
                              
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      updatedBook.tbr == true 
                                          ? 'Added to TBR' 
                                          : 'Removed from TBR',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              debugPrint('Error toggling TBR: $e');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                          tooltip: _currentBook.tbr == true ? 'Remove from TBR' : 'Add to TBR',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Quick status change buttons (always visible)
                    Container(
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            if (_currentBook.statusValue?.toLowerCase() != 'started')
                              Expanded(
                                child: InkWell(
                                  onTap: _quickStartReading,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(6),
                                    bottomLeft: Radius.circular(6),
                                  ),
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.play_arrow,
                                          color: Theme.of(context).colorScheme.primary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Start Reading',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            if (_currentBook.statusValue?.toLowerCase() != 'started')
                              Container(
                                width: 2,
                                color: Theme.of(context).colorScheme.primary,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            Expanded(
                              child: InkWell(
                                onTap: _quickFinishReading,
                                borderRadius: BorderRadius.only(
                                  topRight: const Radius.circular(6),
                                  bottomRight: const Radius.circular(6),
                                  topLeft: _currentBook.statusValue?.toLowerCase() == 'started' 
                                      ? const Radius.circular(6) 
                                      : Radius.zero,
                                  bottomLeft: _currentBook.statusValue?.toLowerCase() == 'started' 
                                      ? const Radius.circular(6) 
                                      : Radius.zero,
                                ),
                                child: Container(
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Theme.of(context).colorScheme.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Mark as Finished',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    AppTheme.verticalSpaceLarge,

                    // Description (from API - future implementation)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.description,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Description',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'API',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This is a placeholder for the book description that will be fetched from an external API in future development. The description will provide a summary of the book\'s content, themes, and other relevant information.',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppTheme.verticalSpaceXLarge,

                    // Details in cards
                    // Status - MOVED TO TOP
                    if (_currentBook.statusValue != null &&
                        _currentBook.statusValue!.isNotEmpty)
                      _DetailCard(
                        icon: Icons.check_circle,
                        label: AppLocalizations.of(context)!.status,
                        value: _getStatusDisplayValue(
                          _currentBook.statusValue!,
                        ),
                      ),
                    // Original Book (for repeated books)
                    if (_currentBook.statusValue?.toLowerCase() == 'repeated' && 
                        _currentBook.originalBookId != null)
                      FutureBuilder<Book?>(
                        future: _loadOriginalBook(_currentBook.originalBookId!),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            final originalBook = snapshot.data!;
                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BookDetailScreen(book: originalBook),
                                  ),
                                );
                              },
                              child: _DetailCard(
                                icon: Icons.repeat,
                                label: 'Original Book',
                                value: '${originalBook.name}${originalBook.author != null ? " - ${originalBook.author}" : ""}',
                                trailingIcon: Icons.open_in_new,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    if (_currentBook.author != null &&
                        _currentBook.author!.isNotEmpty)
                      _DetailCard(
                        icon: Icons.person,
                        label: 'Author(s)',
                        value: _currentBook.author!,
                      ),
                    if (_currentBook.isbn != null &&
                        _currentBook.isbn!.isNotEmpty)
                      _DetailCard(
                        icon: Icons.numbers,
                        label: 'ISBN',
                        value: _currentBook.isbn!,
                      ),
                    if (_currentBook.asin != null &&
                        _currentBook.asin!.isNotEmpty)
                      _DetailCard(
                        icon: Icons.qr_code,
                        label: 'ASIN',
                        value: _currentBook.asin!,
                      ),
                    if (_currentBook.editorialValue != null &&
                        _currentBook.editorialValue!.isNotEmpty)
                      _DetailCard(
                        icon: Icons.business,
                        label: 'Editorial',
                        value: _currentBook.editorialValue!,
                      ),
                    if (_currentBook.genre != null &&
                        _currentBook.genre!.isNotEmpty)
                      _DetailCard(
                        icon: Icons.category,
                        label: 'Genre(s)',
                        value: _currentBook.genre!,
                      ),
                    if (_currentBook.saga != null &&
                        _currentBook.saga!.isNotEmpty)
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => BooksBySagaScreen(
                                    sagaName: _currentBook.saga!,
                                    sagaUniverse: _currentBook.sagaUniverse,
                                  ),
                            ),
                          );
                        },
                        child: _DetailCard(
                          icon: Icons.collections_bookmark,
                          label: 'Saga',
                          value:
                              '${_currentBook.saga}${_currentBook.nSaga != null ? ' #${_currentBook.nSaga}' : ''}',
                          trailingIcon: Icons.open_in_new,
                        ),
                      ),
                    if (_currentBook.sagaUniverse != null &&
                        _currentBook.sagaUniverse!.isNotEmpty)
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => BooksBySagaScreen(
                                    sagaName: _currentBook.sagaUniverse!,
                                    isSagaUniverse: true,
                                  ),
                            ),
                          );
                        },
                        child: _DetailCard(
                          icon: Icons.public,
                          label: 'Saga Universe',
                          value: _currentBook.sagaUniverse!,
                          trailingIcon: Icons.open_in_new,
                        ),
                      ),
                    if (_currentBook.pages != null)
                      _DetailCard(
                        icon: Icons.description,
                        label: 'Pages',
                        value: _currentBook.pages.toString(),
                      ),
                    if (_currentBook.originalPublicationYear != null)
                      ..._buildPublicationInfo(
                        _currentBook.originalPublicationYear!,
                      ),
                    if (_currentBook.formatSagaValue != null &&
                        _currentBook.formatSagaValue!.isNotEmpty)
                      _DetailCard(
                        icon: Icons.format_shapes,
                        label: 'Format Saga',
                        value: _currentBook.formatSagaValue!,
                      ),
                    if (_currentBook.languageValue != null &&
                        _currentBook.languageValue!.isNotEmpty)
                      _DetailCard(
                        icon: Icons.language,
                        label: 'Language',
                        value: _currentBook.languageValue!,
                      ),
                    if (_currentBook.placeValue != null &&
                        _currentBook.placeValue!.isNotEmpty)
                      _DetailCard(
                        icon: Icons.place,
                        label: 'Place',
                        value: _currentBook.placeValue!,
                      ),
                    if (_currentBook.formatValue != null &&
                        _currentBook.formatValue!.isNotEmpty)
                      _DetailCard(
                        icon: Icons.import_contacts,
                        label: 'Format',
                        value: _currentBook.formatValue!,
                      ),
                    if (_currentBook.loaned != null &&
                        _currentBook.loaned!.isNotEmpty)
                      _DetailCard(
                        icon: Icons.swap_horiz,
                        label: 'Loaned',
                        value: _currentBook.loaned!,
                      ),
                    if (_currentBook.createdAt != null &&
                        _currentBook.createdAt!.isNotEmpty)
                      _DetailCard(
                        icon: Icons.access_time,
                        label: 'Created',
                        value: _formatDateTime(_currentBook.createdAt!),
                      ),

                    // Bundle information
                    if (_currentBook.isBundle == true) ...[
                      Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.library_books,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Bundle Information',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Contains ${_currentBook.bundleCount ?? 0} books',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              if (_currentBook.bundleNumbers != null &&
                                  _currentBook.bundleNumbers!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Saga Numbers: ${_currentBook.bundleNumbers}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                              if (_currentBook.bundleTitles != null ||
                                  _currentBook.bundlePages != null ||
                                  _currentBook.bundlePublicationYears != null) ...[
                                const SizedBox(height: 12),
                                const Divider(),
                                const SizedBox(height: 8),
                                ..._buildBundleBooksList(),
                              ],
                            ],
                          ),
                        ),
                      ),
                      // Bundle Reading Sessions
                      if (_bundleReadDates.isNotEmpty)
                        Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.history,
                                      color: Theme.of(context).colorScheme.primary,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      'Bundle Reading Sessions',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...List.generate(_currentBook.bundleCount ?? 0, (bundleIndex) {
                                  final readDates = _bundleReadDates[bundleIndex] ?? [];
                                  if (readDates.isEmpty) return const SizedBox.shrink();
                                  
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Book ${bundleIndex + 1}',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ...List.generate(readDates.length, (index) {
                                          final readDate = readDates[index];
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 4, left: 16),
                                            child: Row(
                                              children: [
                                                Text(
                                                  '${index + 1}.',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    readDate.dateStarted != null 
                                                        ? formatDateForDisplay(readDate.dateStarted)
                                                        : 'Not started',
                                                    style: Theme.of(context).textTheme.bodySmall,
                                                  ),
                                                ),
                                                const Text(' → '),
                                                Expanded(
                                                  child: Text(
                                                    readDate.dateFinished != null
                                                        ? formatDateForDisplay(readDate.dateFinished)
                                                        : 'Not finished',
                                                    style: Theme.of(context).textTheme.bodySmall,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                    ],

                    // TBR Badge with Checkbox
                    if (_currentBook.tbr == true)
                      Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 12),
                        color: Colors.orange.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CheckboxListTile(
                          value: true,
                          onChanged: (value) async {
                            if (value == false) {
                              // Uncheck TBR
                              try {
                                final db = await DatabaseHelper.instance.database;
                                await db.update(
                                  'book',
                                  {'tbr': 0},
                                  where: 'book_id = ?',
                                  whereArgs: [_currentBook.bookId],
                                );
                                
                                if (mounted) {
                                  // Reload provider and navigate back
                                  final provider = Provider.of<BookProvider?>(context, listen: false);
                                  await provider?.loadBooks();
                                  
                                  // Refresh the screen by popping and pushing again
                                  final updatedBooks = provider?.allBooks ?? [];
                                  final updatedBook = updatedBooks.firstWhere(
                                    (b) => b.bookId == _currentBook.bookId,
                                    orElse: () => _currentBook,
                                  );
                                  
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BookDetailScreen(book: updatedBook),
                                    ),
                                  );
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Removed from TBR'),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          secondary: Icon(
                            Icons.bookmark_add,
                            color: Colors.orange,
                            size: 24,
                          ),
                          title: Text(
                            'To Be Read',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          subtitle: const Text('This book is in your TBR list'),
                        ),
                      ),

                    // Tandem Books
                    if (_currentBook.isTandem == true)
                      _TandemBooksCard(
                        saga: _currentBook.saga,
                        sagaUniverse: _currentBook.sagaUniverse,
                        currentBookId: _currentBook.bookId,
                      ),

                    // New fields
                    if (_currentBook.myRating != null &&
                        _currentBook.myRating! > 0)
                      _RatingCard(
                        label: 'My Rating',
                        rating: _currentBook.myRating!,
                      ),
                    if (_currentBook.readCount != null &&
                        _currentBook.readCount! > 0)
                      _DetailCard(
                        icon: Icons.add_circle_outline,
                        label: 'Times Read',
                        value: '${_currentBook.readCount}',
                      ),
                    
                    // Old date fields removed - now using Reading Sessions
                    
                    // Reading Sessions Card
                    if (!(_currentBook.isBundle == true) && _readDates.isNotEmpty)
                      Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.history,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Reading History (${_readDates.length})',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...List.generate(_readDates.length, (index) {
                                final readDate = _readDates[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Text(
                                        '${index + 1}.',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          readDate.dateStarted != null 
                                              ? formatDateForDisplay(readDate.dateStarted)
                                              : 'Not started',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ),
                                      const Text(' → '),
                                      Expanded(
                                        child: Text(
                                          readDate.dateFinished != null
                                              ? formatDateForDisplay(readDate.dateFinished)
                                              : 'Not finished',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    
                    // Chronometer Sessions Card
                    if (!(_currentBook.isBundle == true) && _chronometerSessions.isNotEmpty)
                      Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.timer,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Timed Reading Sessions (${_chronometerSessions.length})',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...List.generate(_chronometerSessions.length, (index) {
                                final session = _chronometerSessions[index];
                                final duration = session.durationSeconds ?? 0;
                                final hours = duration ~/ 3600;
                                final minutes = (duration % 3600) ~/ 60;
                                final seconds = duration % 60;
                                String durationStr;
                                if (hours > 0) {
                                  durationStr = '${hours}h ${minutes}m ${seconds}s';
                                } else if (minutes > 0) {
                                  durationStr = '${minutes}m ${seconds}s';
                                } else {
                                  durationStr = '${seconds}s';
                                }
                                
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Text(
                                        '${index + 1}.',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${formatDateForDisplay(session.startTime.toIso8601String().split('T')[0])} - $durationStr',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    
                    if (_currentBook.myReview != null &&
                        _currentBook.myReview!.isNotEmpty)
                      Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: AppTheme.cardPadding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.rate_review,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 24,
                                  ),
                                  AppTheme.horizontalSpaceLarge,
                                  Text(
                                    'My Review',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium?.copyWith(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              AppTheme.verticalSpaceMedium,
                              Text(
                                _currentBook.myReview!,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              AppTheme.verticalSpaceXXLarge, // Bottom margin
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => ChronometerWidget(
                bookId: _currentBook.bookId!,
                onSessionComplete: () {
                  _loadReadDates();
                },
              ),
            );
          },
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.timer, color: Colors.white),
        ),
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  final String label;
  final double rating;

  const _RatingCard({required this.label, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) {
                final heartValue = index + 1;
                final isFilled = rating >= heartValue;
                final isPartial =
                    !isFilled && rating > index && rating < heartValue;

                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: _buildHeart(isFilled, isPartial),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeart(bool isFilled, bool isPartial) {
    if (isFilled) {
      return const Icon(Icons.favorite, color: Colors.red, size: 28);
    } else if (isPartial) {
      return Stack(
        children: [
          Icon(Icons.favorite_border, color: Colors.grey[400], size: 28),
          ClipRect(
            clipper: _HalfClipper(),
            child: const Icon(Icons.favorite, color: Colors.red, size: 28),
          ),
        ],
      );
    } else {
      return Icon(Icons.favorite_border, color: Colors.grey[400], size: 28);
    }
  }
}

class _HalfClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width / 2, size.height);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => false;
}

class _BundleDatesCard extends StatelessWidget {
  final String? startDates;
  final String? endDates;
  final String? bundlePages;
  final String? bundlePublicationYears;
  final String? bundleTitles;

  const _BundleDatesCard({this.startDates, this.endDates, this.bundlePages, this.bundlePublicationYears, this.bundleTitles});

  @override
  Widget build(BuildContext context) {
    List<DateTime?>? starts;
    List<DateTime?>? ends;
    List<int?>? pages;
    List<int?>? pubYears;
    List<String?>? titles;

    try {
      if (startDates != null) {
        final List<dynamic> dates = jsonDecode(startDates!);
        starts =
            dates.map((d) => d != null ? DateTime.parse(d) : null).toList();
      }
    } catch (e) {
      starts = null;
    }

    try {
      if (endDates != null) {
        final List<dynamic> dates = jsonDecode(endDates!);
        ends = dates.map((d) => d != null ? DateTime.parse(d) : null).toList();
      }
    } catch (e) {
      ends = null;
    }

    try {
      if (bundlePages != null) {
        final List<dynamic> pagesData = jsonDecode(bundlePages!);
        pages = pagesData.map((p) => p as int?).toList();
      }
    } catch (e) {
      pages = null;
    }

    try {
      if (bundlePublicationYears != null) {
        final List<dynamic> yearsData = jsonDecode(bundlePublicationYears!);
        pubYears = yearsData.map((y) => y as int?).toList();
      }
    } catch (e) {
      pubYears = null;
    }

    try {
      if (bundleTitles != null) {
        final List<dynamic> titlesData = jsonDecode(bundleTitles!);
        titles = titlesData.map((t) => t as String?).toList();
      }
    } catch (e) {
      titles = null;
    }

    final maxLength = [
      starts?.length ?? 0,
      ends?.length ?? 0,
      pages?.length ?? 0,
      pubYears?.length ?? 0,
      titles?.length ?? 0,
    ].reduce((a, b) => a > b ? a : b);

    if (maxLength == 0) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_month,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  'Bundle Reading Dates',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(maxLength, (index) {
              final start =
                  starts != null && index < starts.length
                      ? starts[index]
                      : null;
              final end =
                  ends != null && index < ends.length ? ends[index] : null;
              final pageCount =
                  pages != null && index < pages.length ? pages[index] : null;
              final pubYear =
                  pubYears != null && index < pubYears.length ? pubYears[index] : null;
              final title =
                  titles != null && index < titles.length ? titles[index] : null;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title if available
                    if (title != null && title.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    Row(
                      children: [
                        Text(
                          'Book ${index + 1}:',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            start != null
                                ? formatDateForDisplay('${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}')
                                : '-',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const Text(' → '),
                        Expanded(
                          child: Text(
                            end != null
                                ? formatDateForDisplay('${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}')
                                : '-',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    if (pageCount != null || pubYear != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 4),
                        child: Row(
                          children: [
                            if (pageCount != null)
                              Text(
                                'Pages: $pageCount',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey[600], fontSize: 12),
                              ),
                            if (pageCount != null && pubYear != null)
                              Text(
                                ' • ',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey[600], fontSize: 12),
                              ),
                            if (pubYear != null)
                              Text(
                                'Pub. Year: $pubYear',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey[600], fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final IconData? trailingIcon;

  const _DetailCard({
    required this.icon,
    required this.label,
    required this.value,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied: $value'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(value, style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 8),
                Icon(
                  trailingIcon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TandemBooksCard extends StatefulWidget {
  final String? saga;
  final String? sagaUniverse;
  final int? currentBookId;

  const _TandemBooksCard({this.saga, this.sagaUniverse, this.currentBookId});

  @override
  State<_TandemBooksCard> createState() => _TandemBooksCardState();
}

class _TandemBooksCardState extends State<_TandemBooksCard> {
  List<dynamic> _tandemBooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTandemBooks();
  }

  Future<void> _loadTandemBooks() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);
      final books = await repository.getTandemBooks(
        widget.saga,
        widget.sagaUniverse,
      );

      final filteredBooks =
          books.where((book) => book.bookId != widget.currentBookId).toList();

      if (mounted) {
        setState(() {
          _tandemBooks = filteredBooks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.deepPurple.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.swap_horizontal_circle_outlined,
                  color: Colors.deepPurple,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tandem Books',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Read together with these books',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_tandemBooks.isEmpty)
              Text(
                'No other tandem books in this saga',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ..._tandemBooks.map((book) {
                return InkWell(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookDetailScreen(book: book),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.deepPurple.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.menu_book,
                          size: 20,
                          color: Colors.deepPurple,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book.name ?? 'Unknown',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              if (book.author != null &&
                                  book.author!.isNotEmpty)
                                Text(
                                  book.author!,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }
}

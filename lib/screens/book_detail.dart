import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:myrandomlibrary/config/app_theme.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/model/read_date.dart';
import 'package:myrandomlibrary/model/book_rating_field.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/repositories/book_rating_field_repository.dart';
import 'package:myrandomlibrary/screens/books_by_author.dart';
import 'package:myrandomlibrary/screens/books_by_saga.dart';
import 'package:myrandomlibrary/screens/edit_book.dart';
import 'package:myrandomlibrary/utils/status_helper.dart';
import 'package:myrandomlibrary/utils/date_formatter.dart';
import 'package:myrandomlibrary/widgets/chronometer_widget.dart';
import 'package:myrandomlibrary/widgets/book_clubs_card.dart';
import 'package:myrandomlibrary/model/reading_session.dart';
import 'package:myrandomlibrary/repositories/reading_session_repository.dart';
import 'package:myrandomlibrary/services/book_metadata_service.dart';
import 'package:myrandomlibrary/services/notification_service.dart';
import 'package:myrandomlibrary/model/book_metadata.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  Map<int, List<ReadingSession>> _bundleChronometerSessions = {};
  final Map<int, String> _bundleBookTitles = {}; // Map of index -> book title
  int _bundleBooksKey = 0; // Key to force FutureBuilder rebuild
  bool _isDescriptionExpanded = false; // Track description expansion state
  bool _isFetchingMetadata = false; // Track if metadata is being fetched
  String _currencySymbol = '€';

  bool get _hasReadToday {
    final now = DateTime.now();
    final todayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return _chronometerSessions.any(
      (s) =>
          s.didRead &&
          s.startTime != null &&
          _getDayKey(s.startTime!) == todayKey,
    );
  }

  @override
  void initState() {
    super.initState();
    _currentBook = widget.book;
    _loadCurrencySymbol();
    _loadReadDates();
    // Auto-fetch metadata if missing (cover or description)
    _fetchMetadataIfMissing();
    // Check if book has been idle for more than a week (Started status only)
    _checkStandbySuggestion();
  }

  Future<List<Book>> _loadBundleBooks() async {
    if (_currentBook.isBundle != true) return [];

    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);
      return await repository.getBundleBooks(_currentBook.bookId!);
    } catch (e) {
      debugPrint('Error loading bundle books: $e');
      return [];
    }
  }

  Future<Map<int, List<ReadDate>>> _loadIndividualBundleBooksReadDates() async {
    if (_currentBook.isBundle != true) return {};

    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);

      // Get all individual books in this bundle
      final bundleBooks = await repository.getBundleBooks(_currentBook.bookId!);

      // Load reading sessions for each individual book
      final Map<int, List<ReadDate>> result = {};
      for (int i = 0; i < bundleBooks.length; i++) {
        final book = bundleBooks[i];
        // Store book title
        _bundleBookTitles[i] = book.name ?? 'Book ${i + 1}';
        final readDates = await repository.getReadDatesForBook(book.bookId!);
        if (readDates.isNotEmpty) {
          result[i] = readDates;
        }
      }

      return result;
    } catch (e) {
      debugPrint('Error loading individual bundle books read dates: $e');
      return {};
    }
  }

  Future<Map<int, List<ReadingSession>>>
  _loadIndividualBundleBooksSessions() async {
    if (_currentBook.isBundle != true) return {};

    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);
      final sessionRepository = ReadingSessionRepository(db);

      // Get all individual books in this bundle
      final bundleBooks = await repository.getBundleBooks(_currentBook.bookId!);

      // Load chronometer sessions for each individual book
      final Map<int, List<ReadingSession>> result = {};
      for (int i = 0; i < bundleBooks.length; i++) {
        final book = bundleBooks[i];
        final sessions = await sessionRepository.getSessionsForBook(
          book.bookId!,
        );
        if (sessions.isNotEmpty) {
          result[i] = sessions;
        }
      }

      return result;
    } catch (e) {
      debugPrint('Error loading individual bundle books sessions: $e');
      return {};
    }
  }

  Future<List<BookRatingField>> _loadRatingFieldsForBook(int bookId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRatingFieldRepository(db);
      return await repository.getRatingFieldsForBook(bookId);
    } catch (e) {
      debugPrint('Error loading rating fields: $e');
      return [];
    }
  }

  Future<void> _loadCurrencySymbol() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _currencySymbol = prefs.getString('currency_symbol') ?? '€';
      });
    }
  }

  Future<void> _loadReadDates() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);
      final sessionRepository = ReadingSessionRepository(db);

      if (_currentBook.isBundle == true) {
        // Load bundle read dates from individual books
        final individualReadDates = await _loadIndividualBundleBooksReadDates();

        // Load chronometer sessions from individual books
        final individualSessions = await _loadIndividualBundleBooksSessions();

        setState(() {
          _bundleReadDates = individualReadDates;
          _bundleChronometerSessions = individualSessions;
        });
      } else {
        // Check if this is an individual book that's part of a bundle
        List<ReadDate> readDates;
        List<ReadingSession> sessions;

        // Load reading sessions for this book (works for both regular books and individual bundle books)
        readDates = await repository.getReadDatesForBook(_currentBook.bookId!);
        sessions = await sessionRepository.getDisplaySessionsForBook(
          _currentBook.bookId!,
        );

        debugPrint(
          'BookDetail: Loaded ${readDates.length} read dates and ${sessions.length} sessions for book ${_currentBook.bookId} (${_currentBook.name})',
        );
        setState(() {
          _readDates = readDates;
          _chronometerSessions = sessions;
        });
      }
    } catch (e) {
      debugPrint('Error loading read dates: $e');
    }
  }

  /// Automatically fetch and cache metadata if missing or if ISBN/ASIN changed
  Future<void> _fetchMetadataIfMissing() async {
    // Skip if already fetching
    if (_isFetchingMetadata) return;

    final hasCover =
        _currentBook.coverUrl != null && _currentBook.coverUrl!.isNotEmpty;
    final hasDescription =
        _currentBook.description != null &&
        _currentBook.description!.isNotEmpty;
    final hasMetadata = hasCover && hasDescription;

    // Check if ISBN or ASIN has changed since last fetch
    // If metadata exists but we have a new ISBN/ASIN, refetch
    final hasIsbn = _currentBook.isbn != null && _currentBook.isbn!.isNotEmpty;
    final hasAsin = _currentBook.asin != null && _currentBook.asin!.isNotEmpty;
    final hasTitle = _currentBook.name != null && _currentBook.name!.isNotEmpty;

    // If metadata exists and we have identifiers, assume it's current
    // (In a more sophisticated implementation, you could store the ISBN used for fetching
    // and compare it, but for now we'll refetch only if metadata is missing)
    if (hasMetadata) {
      debugPrint('[BookDetail] Metadata already exists, skipping fetch');
      return;
    }

    // Need at least ISBN, ASIN, or title to fetch metadata
    if (!hasIsbn && !hasAsin && !hasTitle) {
      debugPrint(
        '[BookDetail] No ISBN, ASIN, or title available, cannot fetch metadata',
      );
      return;
    }

    setState(() {
      _isFetchingMetadata = true;
    });

    try {
      debugPrint(
        '[BookDetail] Fetching metadata for book: ${_currentBook.name}',
      );

      final metadataService = BookMetadataService();
      BookMetadata? metadata;

      // Try ISBN first (10 or 13)
      if (_currentBook.isbn != null && _currentBook.isbn!.isNotEmpty) {
        debugPrint('[BookDetail] Trying with ISBN: ${_currentBook.isbn}');
        metadata = await metadataService.fetchMetadata(
          isbn: _currentBook.isbn,
          title: _currentBook.name,
          author: _currentBook.author,
          language: _currentBook.languageValue,
        );
      }

      // If no result, try ASIN
      if (metadata == null &&
          _currentBook.asin != null &&
          _currentBook.asin!.isNotEmpty) {
        debugPrint(
          '[BookDetail] ISBN failed, trying with ASIN: ${_currentBook.asin}',
        );
        metadata = await metadataService.fetchMetadata(
          isbn: _currentBook.asin, // ASIN can be used as ISBN parameter
          title: _currentBook.name,
          author: _currentBook.author,
          language: _currentBook.languageValue,
        );
      }

      // If still no result, try title + author
      if (metadata == null &&
          _currentBook.name != null &&
          _currentBook.name!.isNotEmpty) {
        debugPrint('[BookDetail] ASIN failed, trying with title + author');
        metadata = await metadataService.fetchMetadata(
          title: _currentBook.name,
          author: _currentBook.author,
          language: _currentBook.languageValue,
        );
      }

      // If still no result and book has saga + nSaga, try searching by "saga nSaga"
      if (metadata == null &&
          _currentBook.saga != null &&
          _currentBook.saga!.isNotEmpty &&
          _currentBook.nSaga != null &&
          _currentBook.nSaga!.isNotEmpty) {
        final sagaQuery = '${_currentBook.saga} ${_currentBook.nSaga}';
        debugPrint(
          '[BookDetail] Title+author failed, trying with saga+nSaga: $sagaQuery',
        );
        metadata = await metadataService.fetchMetadata(
          title: sagaQuery,
          author: _currentBook.author,
          language: _currentBook.languageValue,
        );
      }

      if (metadata != null && mounted) {
        debugPrint(
          '[BookDetail] Metadata fetched successfully from ${metadata.source}',
        );

        // Update database with fetched metadata
        final db = await DatabaseHelper.instance.database;
        await db.update(
          'book',
          {
            'cover_url': metadata.bestCoverUrl,
            'description': metadata.description,
            'metadata_source': metadata.source,
            'metadata_fetched_at': DateTime.now().toIso8601String(),
          },
          where: 'book_id = ?',
          whereArgs: [_currentBook.bookId!],
        );

        // Reload book to get updated metadata
        final repository = BookRepository(db);
        final updatedBooks = await repository.getAllBooks();
        final updatedBook = updatedBooks.firstWhere(
          (b) => b.bookId == _currentBook.bookId,
          orElse: () => _currentBook,
        );

        if (mounted) {
          setState(() {
            _currentBook = updatedBook;
            _isFetchingMetadata = false;
          });

          debugPrint('[BookDetail] Book updated with fetched metadata');
        }
      } else {
        debugPrint('[BookDetail] No metadata found');
        if (mounted) {
          setState(() {
            _isFetchingMetadata = false;
          });
        }
      }
    } catch (e) {
      debugPrint('[BookDetail] Error fetching metadata: $e');
      if (mounted) {
        setState(() {
          _isFetchingMetadata = false;
        });
      }
    }
  }

  /// Force refetch metadata (useful when ISBN/ASIN changes)
  Future<void> _refetchMetadata() async {
    if (_isFetchingMetadata) return;

    try {
      // Clear existing metadata first
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'book',
        {
          'cover_url': null,
          'description': null,
          'metadata_source': null,
          'metadata_fetched_at': null,
        },
        where: 'book_id = ?',
        whereArgs: [_currentBook.bookId!],
      );

      // Reload book
      final repository = BookRepository(db);
      final updatedBooks = await repository.getAllBooks();
      final updatedBook = updatedBooks.firstWhere(
        (b) => b.bookId == _currentBook.bookId,
        orElse: () => _currentBook,
      );

      if (mounted) {
        setState(() {
          _currentBook = updatedBook;
        });

        // Now fetch new metadata
        await _fetchMetadataIfMissing();
      }
    } catch (e) {
      debugPrint('[BookDetail] Error refetching metadata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.error_refetching_metadata(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Check if a Started book has been idle for more than 7 days and suggest Standby
  Future<void> _checkStandbySuggestion() async {
    // Only for Started books (not already Standby, not bundles)
    if (_currentBook.statusValue?.toLowerCase() != 'started') return;
    if (_currentBook.isBundle == true) return;
    if (_currentBook.bookId == null) return;

    try {
      final db = await DatabaseHelper.instance.database;
      final sessionRepository = ReadingSessionRepository(db);

      final lastActivity = await sessionRepository.getLastReadingActivityDate(
        _currentBook.bookId!,
      );

      if (lastActivity != null) {
        if (DateTime.now().difference(lastActivity).inDays <= 7) return;
      } else {
        // No reading sessions — try to determine start date from various sources
        DateTime? referenceDate;

        // 1. Check book_read_dates for an open (unfinished) read entry
        final openReadDates = await db.query(
          'book_read_dates',
          where: 'book_id = ? AND date_finished IS NULL',
          whereArgs: [_currentBook.bookId!],
          orderBy: 'date_started DESC',
          limit: 1,
        );
        if (openReadDates.isNotEmpty) {
          final dateStr = openReadDates.first['date_started'] as String?;
          if (dateStr != null && dateStr.isNotEmpty) {
            try {
              referenceDate = DateTime.parse(dateStr);
            } catch (_) {}
          }
        }

        // 2. Fall back to dateReadInitial (legacy field)
        if (referenceDate == null) {
          final startDate = _currentBook.dateReadInitial;
          if (startDate != null && startDate.isNotEmpty) {
            try {
              referenceDate = DateTime.parse(startDate);
            } catch (_) {}
          }
        }

        // 3. Fall back to createdAt (when the book was added to the library)
        if (referenceDate == null) {
          final createdAt = _currentBook.createdAt;
          if (createdAt != null && createdAt.isNotEmpty) {
            try {
              referenceDate = DateTime.parse(createdAt);
            } catch (_) {}
          }
        }

        if (referenceDate == null) return;
        if (DateTime.now().difference(referenceDate).inDays <= 7) return;
      }

      // Book has been idle for more than 7 days — show suggestion modal
      if (!mounted) return;
      // Use addPostFrameCallback to avoid showing dialog during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showStandbySuggestionDialog();
      });
    } catch (e) {
      debugPrint('[BookDetail] Error checking standby suggestion: $e');
    }
  }

  Future<void> _showStandbySuggestionDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            icon: Icon(
              Icons.pause_circle_outline,
              color: Colors.orange,
              size: 48,
            ),
            title: Text(AppLocalizations.of(context)!.standby_suggestion_title),
            content: Text(
              AppLocalizations.of(context)!.standby_suggestion_body,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.keep_reading),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: Text(AppLocalizations.of(context)!.move_to_standby),
              ),
            ],
          ),
    );

    if (result == true) {
      await _moveToStandby();
    }
  }

  Future<void> _moveToStandby() async {
    final provider = Provider.of<BookProvider?>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);

      // Get Standby status ID
      final statusList = await repository.getLookupValues('status');
      final standbyStatus = statusList.firstWhere(
        (s) => (s['value'] as String).toLowerCase() == 'standby',
        orElse: () => statusList.first,
      );

      await db.update(
        'book',
        {'status_id': standbyStatus['status_id']},
        where: 'book_id = ?',
        whereArgs: [_currentBook.bookId!],
      );

      // Reload book data
      final updatedBooks = await repository.getAllBooks();
      final updatedBook = updatedBooks.firstWhere(
        (b) => b.bookId == _currentBook.bookId,
        orElse: () => _currentBook,
      );

      setState(() {
        _currentBook = updatedBook;
      });

      // Reschedule reading reminders (book no longer started)
      NotificationService().scheduleReadingReminders();

      // Update provider
      if (!context.mounted) return;
      await provider?.loadBooks();

      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.move_to_standby),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      debugPrint('[BookDetail] Error moving to standby: $e');
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _moveBackToReading() async {
    final provider = Provider.of<BookProvider?>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);

      // Get Started status ID
      final statusList = await repository.getLookupValues('status');
      final startedStatus = statusList.firstWhere(
        (s) => (s['value'] as String).toLowerCase() == 'started',
        orElse: () => statusList.first,
      );

      await db.update(
        'book',
        {'status_id': startedStatus['status_id']},
        where: 'book_id = ?',
        whereArgs: [_currentBook.bookId!],
      );

      // Reload book data
      final updatedBooks = await repository.getAllBooks();
      final updatedBook = updatedBooks.firstWhere(
        (b) => b.bookId == _currentBook.bookId,
        orElse: () => _currentBook,
      );

      setState(() {
        _currentBook = updatedBook;
      });

      // Reschedule reading reminders (book is now started again)
      NotificationService().scheduleReadingReminders();

      // Update provider
      if (!context.mounted) return;
      await provider?.loadBooks();

      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.moved_back_to_reading),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('[BookDetail] Error moving back to reading: $e');
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
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
    final provider = Provider.of<BookProvider?>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
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
        {'status_id': startedStatus['status_id'], 'date_read_initial': today},
        where: 'book_id = ?',
        whereArgs: [_currentBook.bookId!],
      );

      // Create a new reading session with start date
      await repository.addReadDate(
        ReadDate(
          bookId: _currentBook.bookId!,
          dateStarted: today,
          dateFinished: null,
        ),
      );

      // Reload book data
      final updatedBooks = await repository.getAllBooks();
      final updatedBook = updatedBooks.firstWhere(
        (b) => b.bookId == _currentBook.bookId,
        orElse: () => _currentBook,
      );

      setState(() {
        _currentBook = updatedBook;
      });
      await _loadReadDates();

      // Reschedule reading reminders (new started book)
      NotificationService().scheduleReadingReminders();

      // Update provider
      if (!context.mounted) return;
      await provider?.loadBooks();

      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.started_reading),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error starting reading: $e');
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _quickFinishReading() async {
    final provider = Provider.of<BookProvider?>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    // Show modal to collect ratings and review
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => _FinishBookDialog(
            bookId: _currentBook.bookId!,
            bookName: _currentBook.name ?? '',
          ),
    );

    if (result == null) return; // User cancelled

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
        (s) =>
            (s['value'] as String).toLowerCase() ==
            (hasReadingSessions ? 'yes' : 'no'),
        orElse: () => statusList.first,
      );

      // Get current read count
      final currentReadCount = _currentBook.readCount ?? 0;

      // Update status, increment read count, save review
      final ratings = result['ratings'] as List<Map<String, dynamic>>;
      await db.update(
        'book',
        {
          'status_id': targetStatus['status_id'],
          'date_read_final': today,
          'read_count': currentReadCount + 1,
          'my_review': result['review'],
          'reading_progress': 0, // Reset progress
        },
        where: 'book_id = ?',
        whereArgs: [_currentBook.bookId!],
      );

      // Save rating fields (rating is computed from these, not stored on book)
      final ratingFieldRepository = BookRatingFieldRepository(db);
      for (final rating in ratings) {
        await ratingFieldRepository.insertRatingField(
          BookRatingField(
            bookId: _currentBook.bookId!,
            fieldName: rating['fieldName'],
            ratingValue: rating['ratingValue'],
          ),
        );
      }

      // If there's an open reading session, close it
      if (_readDates.isNotEmpty && _readDates.last.dateFinished == null) {
        final updatedReadDate = ReadDate(
          readDateId: _readDates.last.readDateId,
          bookId: _readDates.last.bookId,
          dateStarted: _readDates.last.dateStarted,
          dateFinished: today,
          bundleBookIndex: _readDates.last.bundleBookIndex,
          readingProgress: _currentBook.readingProgress,
        );
        await repository.updateReadDate(updatedReadDate);
      } else {
        // Create a new reading session with finish date
        await repository.addReadDate(
          ReadDate(
            bookId: _currentBook.bookId!,
            dateStarted: _currentBook.dateReadInitial ?? today,
            dateFinished: today,
            readingProgress: _currentBook.readingProgress,
          ),
        );
      }

      // Reload book data
      final updatedBooks = await repository.getAllBooks();
      final updatedBook = updatedBooks.firstWhere(
        (b) => b.bookId == _currentBook.bookId,
        orElse: () => _currentBook,
      );

      setState(() {
        _currentBook = updatedBook;
      });
      await _loadReadDates();

      // Reschedule reading reminders (book no longer started)
      NotificationService().scheduleReadingReminders();

      // Update provider
      if (!context.mounted) return;
      await provider?.loadBooks();

      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.marked_as_finished),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error finishing reading: $e');
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _markAsRead() async {
    final provider = Provider.of<BookProvider?>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);
      final today = DateTime.now().toIso8601String().split('T')[0];

      // Get status values
      final statusList = await repository.getLookupValues('status');
      final readStatus = statusList.firstWhere(
        (s) => (s['value'] as String).toLowerCase() == 'yes',
        orElse: () => statusList.first,
      );

      // Get current read count
      final currentReadCount = _currentBook.readCount ?? 0;

      // Only increment read count if it's 0
      final newReadCount = currentReadCount == 0 ? 1 : currentReadCount;

      // Update status and conditionally increment read count
      await db.update(
        'book',
        {
          'status_id': readStatus['status_id'],
          'date_read_final': today,
          'read_count': newReadCount,
        },
        where: 'book_id = ?',
        whereArgs: [_currentBook.bookId!],
      );

      // Reload book data
      final updatedBooks = await repository.getAllBooks();
      final updatedBook = updatedBooks.firstWhere(
        (b) => b.bookId == _currentBook.bookId,
      );

      setState(() {
        _currentBook = updatedBook;
      });
      await _loadReadDates();

      // Reschedule reading reminders (book no longer started)
      NotificationService().scheduleReadingReminders();

      // Update provider
      if (!context.mounted) return;
      await provider?.loadBooks();

      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.marked_as_read),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error marking as read: $e');
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showProgressModal() async {
    final provider = Provider.of<BookProvider?>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isPercentage = _currentBook.progressType == 'percentage';
    final currentProgress = _currentBook.readingProgress ?? 0;

    final progressController = TextEditingController(
      text: currentProgress.toString(),
    );

    bool usePercentage = isPercentage;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text(
                    AppLocalizations.of(context)!.update_reading_progress,
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Toggle between percentage and pages
                        Row(
                          children: [
                            Expanded(
                              child: SegmentedButton<bool>(
                                segments: [
                                  ButtonSegment(
                                    value: true,
                                    label: Text(
                                      AppLocalizations.of(context)!.percentage,
                                    ),
                                  ),
                                  ButtonSegment(
                                    value: false,
                                    label: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.pages_label_short,
                                    ),
                                  ),
                                ],
                                selected: {usePercentage},
                                onSelectionChanged: (Set<bool> newSelection) {
                                  setDialogState(() {
                                    usePercentage = newSelection.first;
                                    progressController.clear();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: progressController,
                          decoration: InputDecoration(
                            labelText:
                                usePercentage
                                    ? AppLocalizations.of(
                                      context,
                                    )!.progress_percentage
                                    : AppLocalizations.of(
                                      context,
                                    )!.current_page,
                            border: const OutlineInputBorder(),
                            hintText:
                                usePercentage
                                    ? '0-100'
                                    : '1-${_currentBook.pages ?? 0}',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                        if (!usePercentage && _currentBook.pages != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.total_pages(_currentBook.pages!),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(AppLocalizations.of(context)!.cancel),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final value = int.tryParse(progressController.text);
                        if (value == null || value < 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(
                                  context,
                                )!.enter_valid_number,
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        if (usePercentage && value > 100) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(
                                  context,
                                )!.percentage_cannot_exceed_100,
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        if (!usePercentage &&
                            _currentBook.pages != null &&
                            value > _currentBook.pages!) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(
                                  context,
                                )!.page_cannot_exceed(_currentBook.pages!),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        Navigator.pop(context, {
                          'progress': value,
                          'type': usePercentage ? 'percentage' : 'pages',
                        });
                      },
                      child: Text(AppLocalizations.of(context)!.save),
                    ),
                  ],
                ),
          ),
    );

    if (result != null) {
      try {
        final db = await DatabaseHelper.instance.database;
        await db.update(
          'book',
          {
            'reading_progress': result['progress'],
            'progress_type': result['type'],
          },
          where: 'book_id = ?',
          whereArgs: [_currentBook.bookId!],
        );

        // Reload book data
        final repository = BookRepository(db);
        final updatedBooks = await repository.getAllBooks();
        final updatedBook = updatedBooks.firstWhere(
          (b) => b.bookId == _currentBook.bookId,
        );

        setState(() {
          _currentBook = updatedBook;
        });

        // Update provider
        if (!context.mounted) return;
        await provider?.loadBooks();

        if (!context.mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.progress_updated),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        debugPrint('Error updating progress: $e');
        messenger.showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _markAsReadToday() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final sessionRepository = ReadingSessionRepository(db);

      await sessionRepository.createDidReadSession(_currentBook.bookId!, true);

      await _loadReadDates();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.marked_read_today),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving did read status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showEditSessionsModal() async {
    if (_chronometerSessions.isEmpty) return;

    // Create editable copies of sessions
    List<ReadingSession> editableSessions =
        _chronometerSessions.map((session) => session).toList();

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text(
                    AppLocalizations.of(context)!.edit_reading_sessions,
                  ),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...List.generate(editableSessions.length, (index) {
                            final session = editableSessions[index];
                            final dateController = TextEditingController(
                              text:
                                  session.startTime != null
                                      ? session.startTime!
                                          .toIso8601String()
                                          .split('T')[0]
                                      : '',
                            );
                            final timeController = TextEditingController(
                              text:
                                  session.clickedAt != null
                                      ? '${session.clickedAt!.hour.toString().padLeft(2, '0')}:${session.clickedAt!.minute.toString().padLeft(2, '0')}'
                                      : '',
                            );
                            final durationController = TextEditingController(
                              text:
                                  session.durationSeconds != null &&
                                          session.durationSeconds! > 0
                                      ? _formatDurationForDisplay(
                                        session.durationSeconds!,
                                      )
                                      : '',
                            );

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.session_label(index + 1),
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: dateController,
                                      decoration: InputDecoration(
                                        labelText:
                                            AppLocalizations.of(
                                              context,
                                            )!.date_label,
                                        border: const OutlineInputBorder(),
                                        hintText: 'YYYY-MM-DD',
                                      ),
                                      onChanged: (value) {
                                        try {
                                          final newDate = DateTime.parse(value);
                                          editableSessions[index] = session
                                              .copyWith(startTime: newDate);
                                        } catch (e) {
                                          // Invalid date format
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: timeController,
                                      decoration: InputDecoration(
                                        labelText:
                                            AppLocalizations.of(
                                              context,
                                            )!.time_hhmmss,
                                        hintText: 'HH:MM',
                                      ),
                                      onChanged: (value) {
                                        try {
                                          final timeParts = value.split(':');
                                          if (timeParts.length >= 2) {
                                            final hour = int.parse(
                                              timeParts[0],
                                            );
                                            final minute = int.parse(
                                              timeParts[1],
                                            );

                                            final newClickedAt = DateTime(
                                              session.clickedAt?.year ??
                                                  DateTime.now().year,
                                              session.clickedAt?.month ??
                                                  DateTime.now().month,
                                              session.clickedAt?.day ??
                                                  DateTime.now().day,
                                              hour,
                                              minute,
                                            );
                                            editableSessions[index] = session
                                                .copyWith(
                                                  clickedAt: newClickedAt,
                                                );
                                          }
                                        } catch (e) {
                                          // Invalid time format
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: durationController,
                                      decoration: InputDecoration(
                                        labelText:
                                            AppLocalizations.of(
                                              context,
                                            )!.duration_label,
                                        hintText:
                                            'e.g., 1h 30m 5s or 90m or 3600',
                                        helperText:
                                            AppLocalizations.of(
                                              context,
                                            )!.duration_hint,
                                      ),
                                      onChanged: (value) {
                                        try {
                                          final duration =
                                              _parseDurationToSeconds(value);
                                          editableSessions[index] = session
                                              .copyWith(
                                                durationSeconds: duration,
                                              );
                                        } catch (e) {
                                          // Invalid duration format, try parsing as plain seconds
                                          try {
                                            final duration = int.parse(value);
                                            editableSessions[index] = session
                                                .copyWith(
                                                  durationSeconds: duration,
                                                );
                                          } catch (e2) {
                                            // Invalid format, ignore
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(AppLocalizations.of(context)!.cancel),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(AppLocalizations.of(context)!.save),
                    ),
                  ],
                ),
          ),
    );

    if (result == true) {
      try {
        final db = await DatabaseHelper.instance.database;
        final sessionRepository = ReadingSessionRepository(db);

        for (final session in editableSessions) {
          await sessionRepository.updateSession(session);
        }

        await _loadReadDates();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.sessions_updated),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error updating sessions: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _showAddSessionModal() async {
    final dateController = TextEditingController(
      text: DateTime.now().toIso8601String().split('T')[0],
    );
    final timeController = TextEditingController(
      text:
          '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
    );

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.add_reading_session),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: dateController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.date_label,
                    border: const OutlineInputBorder(),
                    hintText: 'YYYY-MM-DD',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: timeController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.time_hhmmss,
                    border: const OutlineInputBorder(),
                    hintText: '14:30',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(AppLocalizations.of(context)!.add),
              ),
            ],
          ),
    );

    if (result == true) {
      try {
        final dateStr = dateController.text;
        final timeStr = timeController.text;

        final dateParts = dateStr.split('-');
        final timeParts = timeStr.split(':');

        if (dateParts.length == 3 && timeParts.length == 2) {
          final dateTime = DateTime(
            int.parse(dateParts[0]),
            int.parse(dateParts[1]),
            int.parse(dateParts[2]),
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
          );

          final db = await DatabaseHelper.instance.database;
          final sessionRepository = ReadingSessionRepository(db);

          await sessionRepository.createCustomSession(
            _currentBook.bookId!,
            dateTime,
            didRead: true,
          );

          await _loadReadDates();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.session_added),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Error adding session: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
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

  /// Calculate reading time for the book using three-case algorithm
  Map<String, dynamic> _calculateReadingTime() {
    if (_currentBook.isBundle == true) {
      return _calculateBundleReadingTime();
    } else {
      return _calculateSingleBookReadingTime(
        _currentBook,
        _chronometerSessions,
        _readDates,
      );
    }
  }

  /// Calculate reading time for a single book
  Map<String, dynamic> _calculateSingleBookReadingTime(
    Book book,
    List<ReadingSession> sessions,
    List<ReadDate> readDates,
  ) {
    // Only calculate for read books
    if (book.statusValue?.toLowerCase() != 'yes' ||
        book.readCount == null ||
        book.readCount! <= 0) {
      return {'days': 0, 'method': 'Not read', 'hasData': false};
    }

    final dailyData = _mapSessionsToDailyReadings(sessions);

    if (dailyData.hasTimeReadData) {
      // Case 1: Has timeRead data
      return {
        'days': dailyData.totalReadingDays,
        'method': 'Time-based',
        'hasData': true,
        'details': {
          'days_with_time': dailyData.totalDaysWithTimeRead,
          'days_with_didread_only': dailyData.totalDaysWithDidReadOnly,
          'total_hours': dailyData.totalSecondsRead / 3600,
        },
      };
    } else if (dailyData.hasDidReadData) {
      // Case 2: Only didReadToday data
      return {
        'days': dailyData.totalReadingDays,
        'method': 'DidRead-based',
        'hasData': true,
        'details': {
          'days_with_didread_only': dailyData.totalDaysWithDidReadOnly,
        },
      };
    } else {
      // Case 3: No session data, use dates from readDates
      if (readDates.isNotEmpty) {
        // Use the most recent read date entry
        final latestReadDate = readDates.first;

        if (latestReadDate.dateStarted != null &&
            latestReadDate.dateFinished != null) {
          final startDate = _parseDate(latestReadDate.dateStarted!);
          final endDate = _parseDate(latestReadDate.dateFinished!);

          if (startDate != null &&
              endDate != null &&
              endDate.isAfter(startDate)) {
            final days = endDate.difference(startDate).inDays + 1;
            return {
              'days': days,
              'method': 'Date-based',
              'hasData': true,
              'details': {
                'start_date': latestReadDate.dateStarted,
                'end_date': latestReadDate.dateFinished,
              },
            };
          }
        }
      }

      return {'days': 0, 'method': 'No data', 'hasData': false};
    }
  }

  /// Calculate reading time for bundle books
  Map<String, dynamic> _calculateBundleReadingTime() {
    int totalDays = 0;
    List<String> methodsUsed = [];
    Map<String, int> methodCounts = {};
    bool hasAnyData = false;

    for (var entry in _bundleChronometerSessions.entries) {
      final bookIndex = entry.key;
      final sessions = entry.value;

      // Get the corresponding book title
      final bookTitle = _bundleBookTitles[bookIndex] ?? 'Book ${bookIndex + 1}';

      // Create a temporary book object for calculation
      final tempBook = Book(
        bookId: -1, // Temporary ID
        name: bookTitle,
        saga: null,
        nSaga: null,
        sagaUniverse: null,
        formatSagaValue: null,
        isbn: null,
        asin: null,
        pages: null,
        originalPublicationYear: null,
        loaned: null,
        statusValue: 'Yes',
        editorialValue: null,
        languageValue: null,
        placeValue: null,
        formatValue: null,
        createdAt: null,
        author: null,
        genre: null,
        dateReadInitial: null,
        dateReadFinal: null,
        readCount: 1,
        myReview: null,
        isBundle: false,
        bundleCount: null,
        bundleNumbers: null,
        bundleStartDates: null,
        bundleEndDates: null,
        bundlePages: null,
        bundlePublicationYears: null,
        bundleTitles: null,
        bundleAuthors: null,
        tbr: null,
        isTandem: null,
        originalBookId: null,
        notificationEnabled: null,
        notificationDatetime: null,
        bundleParentId: null,
        readingProgress: null,
        progressType: null,
      );

      // Get read dates for this bundle book
      final bundleBookReadDates = _bundleReadDates[bookIndex] ?? [];

      final result = _calculateSingleBookReadingTime(
        tempBook,
        sessions,
        bundleBookReadDates,
      );

      if (result['hasData'] == true) {
        totalDays += result['days'] as int;
        hasAnyData = true;
        methodsUsed.add(result['method'] as String);
        methodCounts[result['method'] as String] =
            (methodCounts[result['method'] as String] ?? 0) + 1;
      }
    }

    String primaryMethod = 'No data';
    if (hasAnyData && methodCounts.isNotEmpty) {
      primaryMethod =
          methodCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    return {
      'days': totalDays,
      'method': primaryMethod,
      'hasData': hasAnyData,
      'details': {
        'methods_used': methodsUsed,
        'method_counts': methodCounts,
        'books_calculated': _bundleChronometerSessions.length,
      },
    };
  }

  /// Convert reading sessions to daily reading data
  _DailyReadingData _mapSessionsToDailyReadings(List<ReadingSession> sessions) {
    final Map<String, List<ReadingSession>> dailySessions = {};

    for (var session in sessions) {
      if (session.startTime != null) {
        final dayKey = _getDayKey(session.startTime!);
        dailySessions[dayKey] ??= [];
        dailySessions[dayKey]!.add(session);
      }
    }

    int totalDaysWithTimeRead = 0;
    int totalDaysWithDidReadOnly = 0;
    int totalSecondsRead = 0;
    final Set<String> uniqueReadingDays = {};

    for (var entry in dailySessions.entries) {
      final daySessions = entry.value;
      final dayKey = entry.key;

      int dayTimeSeconds = 0;
      bool hasDidRead = false;

      for (var session in daySessions) {
        if (session.durationSeconds != null && session.durationSeconds! > 0) {
          dayTimeSeconds += session.durationSeconds!;
        }
        if (session.didRead) {
          hasDidRead = true;
        }
      }

      // Apply counting rules
      if (dayTimeSeconds > 0) {
        totalDaysWithTimeRead++;
        totalSecondsRead += dayTimeSeconds;
        uniqueReadingDays.add(dayKey);
      } else if (hasDidRead) {
        totalDaysWithDidReadOnly++;
        uniqueReadingDays.add(dayKey);
      }
    }

    return _DailyReadingData(
      totalDaysWithTimeRead: totalDaysWithTimeRead,
      totalDaysWithDidReadOnly: totalDaysWithDidReadOnly,
      totalSecondsRead: totalSecondsRead,
      totalReadingDays: uniqueReadingDays.length,
      hasTimeReadData: totalSecondsRead > 0,
      hasDidReadData:
          totalDaysWithDidReadOnly > 0 ||
          (totalDaysWithTimeRead > 0 && totalDaysWithDidReadOnly >= 0),
    );
  }

  /// Get day key in YYYY-MM-DD format
  String _getDayKey(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  /// Parse date string with multiple formats
  DateTime? _parseDate(String dateStr) {
    if (dateStr.trim().isEmpty) return null;

    try {
      return DateTime.parse(dateStr.trim());
    } catch (e) {
      // Try other formats if needed
      if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          try {
            final year = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final day = int.parse(parts[2]);
            if (year > 1900) {
              return DateTime(year, month, day);
            }
          } catch (e) {
            // Continue to return null
          }
        }
      }
    }
    return null;
  }

  /// Format duration in seconds to readable format (e.g., "1h 30m 5s")
  String _formatDurationForDisplay(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${secs}s';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }

  /// Parse duration string back to seconds
  int _parseDurationToSeconds(String durationStr) {
    if (durationStr.trim().isEmpty) return 0;

    int totalSeconds = 0;
    final parts = durationStr.split(' ');

    for (final part in parts) {
      if (part.endsWith('h')) {
        final hours = int.tryParse(part.substring(0, part.length - 1)) ?? 0;
        totalSeconds += hours * 3600;
      } else if (part.endsWith('m')) {
        final minutes = int.tryParse(part.substring(0, part.length - 1)) ?? 0;
        totalSeconds += minutes * 60;
      } else if (part.endsWith('s')) {
        final seconds = int.tryParse(part.substring(0, part.length - 1)) ?? 0;
        totalSeconds += seconds;
      } else {
        // Try parsing as plain number (assume seconds)
        final seconds = int.tryParse(part) ?? 0;
        totalSeconds += seconds;
      }
    }

    return totalSeconds;
  }

  /// Build reading time card showing how long it took to read the book
  Widget _buildReadingTimeCard() {
    final readingTimeData = _calculateReadingTime();

    if (!readingTimeData['hasData']) {
      return const SizedBox.shrink();
    }

    final days = readingTimeData['days'] as int;
    final method = readingTimeData['method'] as String;
    final details = readingTimeData['details'] as Map<String, dynamic>;

    String timeText;
    IconData timeIcon;
    Color timeColor;

    // Build time text with hours if available
    if (method == 'Time-based' && details.containsKey('total_hours')) {
      final totalHours = details['total_hours'] as double;
      final hoursText = totalHours.toStringAsFixed(1);

      if (days == 1) {
        timeText = '$days day ($hoursText hours)';
      } else {
        timeText = '$days days ($hoursText hours)';
      }
    } else {
      // No hours data, show only days
      if (days == 1) {
        timeText = '1 day';
      } else {
        timeText = '$days days';
      }
    }

    // Choose icon and color based on method
    switch (method) {
      case 'Time-based':
        timeIcon = Icons.timer;
        timeColor = Colors.blue;
        break;
      case 'DidRead-based':
        timeIcon = Icons.check_circle_outline;
        timeColor = Colors.green;
        break;
      case 'Date-based':
        timeIcon = Icons.date_range;
        timeColor = Colors.orange;
        break;
      default:
        timeIcon = Icons.help_outline;
        timeColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          _showReadingTimeDetails(readingTimeData);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(timeIcon, size: 20, color: timeColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.reading_time,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: timeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      method,
                      style: TextStyle(
                        fontSize: 11,
                        color: timeColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    timeText,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show detailed reading time information in a dialog
  void _showReadingTimeDetails(Map<String, dynamic> readingTimeData) {
    final days = readingTimeData['days'] as int;
    final method = readingTimeData['method'] as String;
    final details = readingTimeData['details'] as Map<String, dynamic>;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.reading_time_details,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.book_took_days(
                    days,
                    days == 1
                        ? AppLocalizations.of(context)!.day_word
                        : AppLocalizations.of(context)!.days_word,
                  ),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.calculation_method(method),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                if (method == 'Time-based' &&
                    details.containsKey('total_hours')) ...[
                  Text(
                    'Total reading time: ${(details['total_hours'] as double).toStringAsFixed(1)} hours',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (details['days_with_time'] > 0)
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.days_with_time_tracking(details['days_with_time']),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (details['days_with_didread_only'] > 0)
                    Text(
                      AppLocalizations.of(context)!.days_with_reading_flag(
                        details['days_with_didread_only'],
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ] else if (method == 'DidRead-based' &&
                    details.containsKey('days_with_didread_only')) ...[
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.days_marked_as_read(details['days_with_didread_only']),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ] else if (method == 'Date-based' &&
                    details.containsKey('start_date')) ...[
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.start_date_label(details['start_date']),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.end_date_label(details['end_date']),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (_currentBook.isBundle == true &&
                    details.containsKey('books_calculated')) ...[
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.bundle_books_calculated(details['books_calculated']),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.of(context)!.close),
              ),
            ],
          ),
    );
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
          label: AppLocalizations.of(context)!.original_publication_year_label,
          value: year.toString(),
        ),
      );

      // Add full date card
      widgets.add(
        _DetailCard(
          icon: Icons.event,
          label: AppLocalizations.of(context)!.original_publication_date_label,
          value:
              '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year',
        ),
      );
    } else {
      // Just a year
      widgets.add(
        _DetailCard(
          icon: Icons.calendar_today,
          label: AppLocalizations.of(context)!.original_publication_year_label,
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
            title: Text(AppLocalizations.of(context)!.confirm_delete_title),
            content: Text(AppLocalizations.of(context)!.confirm_delete),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text(AppLocalizations.of(context)!.delete),
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

          if (!context.mounted) return;
          Navigator.pop(context); // Go back to list

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.book_updated_successfully,
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.error_deleting_book(e.toString()),
              ),
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
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop) {
          // Go back to previous screen (list)
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.book_details),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: AppLocalizations.of(context)!.refresh_metadata,
              onPressed: _refetchMetadata,
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final updatedBook = await Navigator.push<Book>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditBookScreen(book: _currentBook),
                  ),
                );
                if (updatedBook != null && context.mounted) {
                  setState(() {
                    _currentBook = updatedBook;
                  });
                  // Reload read dates after edit
                  await _loadReadDates();

                  if (!context.mounted) return;
                  // If this is an individual book in a bundle, notify parent to refresh
                  if (_currentBook.bundleParentId != null) {
                    // Pop with result to notify parent bundle detail screen
                    Navigator.pop(context, updatedBook);
                  }

                  // Removed auto-fetch - only manual refresh button will fetch metadata
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
              // Book cover image with glassmorphism effect
              Container(
                height: 250,
                decoration: BoxDecoration(color: Colors.grey[300]),
                child:
                    _currentBook.coverUrl != null &&
                            _currentBook.coverUrl!.isNotEmpty
                        ? Stack(
                          fit: StackFit.expand,
                          children: [
                            // Blurred background image
                            Image.network(
                              _currentBook.coverUrl!,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) => Container(),
                            ),
                            // Blur effect
                            BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                              child: Container(
                                color: Colors.black.withValues(alpha: 0.1),
                              ),
                            ),
                            // Centered cover with glassmorphism
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 10,
                                      sigmaY: 10,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.2,
                                          ),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.1,
                                            ),
                                            blurRadius: 20,
                                            spreadRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Image.network(
                                          _currentBook.coverUrl!,
                                          fit: BoxFit.contain,
                                          height: 210,
                                          loadingBuilder: (
                                            context,
                                            child,
                                            loadingProgress,
                                          ) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            return SizedBox(
                                              height: 210,
                                              child: Center(
                                                child: CircularProgressIndicator(
                                                  value:
                                                      loadingProgress
                                                                  .expectedTotalBytes !=
                                                              null
                                                          ? loadingProgress
                                                                  .cumulativeBytesLoaded /
                                                              loadingProgress
                                                                  .expectedTotalBytes!
                                                          : null,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            );
                                          },
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return SizedBox(
                                              height: 210,
                                              child: Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(
                                                      Icons.broken_image,
                                                      size: 60,
                                                      color: Colors.white70,
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      AppLocalizations.of(
                                                        context,
                                                      )!.failed_to_load_image,
                                                      style: const TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                        : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isFetchingMetadata) ...[
                                const CircularProgressIndicator(),
                                const SizedBox(height: 12),
                                Text(
                                  AppLocalizations.of(context)!.fetching_cover,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ] else ...[
                                const Icon(
                                  Icons.book,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  AppLocalizations.of(context)!.no_cover_image,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
              ),
              const SizedBox(height: 24), // Spacing between cover and content
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
                            color:
                                _currentBook.tbr == true
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey,
                          ),
                          onPressed: () async {
                            try {
                              final db = await DatabaseHelper.instance.database;

                              // Toggle TBR status
                              final newTbr = !(_currentBook.tbr == true);
                              await db.update(
                                'book',
                                {'tbr': newTbr ? 1 : 0},
                                where: 'book_id = ?',
                                whereArgs: [_currentBook.bookId],
                              );

                              // Reload provider
                              if (!context.mounted) return;
                              final provider = Provider.of<BookProvider?>(
                                context,
                                listen: false,
                              );
                              await provider?.loadBooks();

                              if (!context.mounted) return;
                              // Update local state from provider
                              final updatedBooks = provider?.allBooks ?? [];
                              final updatedBook = updatedBooks.firstWhere(
                                (b) => b.bookId == _currentBook.bookId,
                                orElse: () => _currentBook,
                              );
                              setState(() {
                                _currentBook = updatedBook;
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    newTbr
                                        ? AppLocalizations.of(
                                          context,
                                        )!.added_to_tbr
                                        : AppLocalizations.of(
                                          context,
                                        )!.removed_from_tbr,
                                  ),
                                ),
                              );
                            } catch (e) {
                              debugPrint('Error toggling TBR: $e');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                          tooltip:
                              _currentBook.tbr == true
                                  ? AppLocalizations.of(
                                    context,
                                  )!.remove_from_tbr
                                  : AppLocalizations.of(
                                    context,
                                  )!.add_to_tbr_short,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Quick status change buttons (only for individual books, not bundles)
                    if (_currentBook.isBundle != true) ...[
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
                            if (_currentBook.statusValue?.toLowerCase() !=
                                'started')
                              Expanded(
                                child: InkWell(
                                  onTap:
                                      _currentBook.statusValue?.toLowerCase() ==
                                              'standby'
                                          ? _moveBackToReading
                                          : _quickStartReading,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(6),
                                    bottomLeft: Radius.circular(6),
                                  ),
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _currentBook.statusValue
                                                      ?.toLowerCase() ==
                                                  'standby'
                                              ? Icons.replay
                                              : Icons.play_arrow,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            _currentBook.statusValue
                                                        ?.toLowerCase() ==
                                                    'standby'
                                                ? AppLocalizations.of(
                                                  context,
                                                )!.move_back_to_reading
                                                : AppLocalizations.of(
                                                  context,
                                                )!.start_reading,
                                            style: TextStyle(
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            if (_currentBook.statusValue?.toLowerCase() !=
                                'started')
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
                                  topLeft:
                                      _currentBook.statusValue?.toLowerCase() ==
                                              'started'
                                          ? const Radius.circular(6)
                                          : Radius.zero,
                                  bottomLeft:
                                      _currentBook.statusValue?.toLowerCase() ==
                                              'started'
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
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.mark_as_finished,
                                          style: TextStyle(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
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

                      // Mark as Read button (full width) - hidden when Started or Standby
                      if (_currentBook.statusValue?.toLowerCase() !=
                              'started' &&
                          _currentBook.statusValue?.toLowerCase() !=
                              'standby') ...[
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          child: InkWell(
                            onTap: _markAsRead,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.done_all,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    AppLocalizations.of(context)!.mark_as_read,
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        AppTheme.verticalSpaceLarge,
                      ],
                    ],

                    // Did you read today? button (only for Started or Standby status, not for bundles)
                    if ((_currentBook.statusValue?.toLowerCase() == 'started' ||
                            _currentBook.statusValue?.toLowerCase() ==
                                'standby') &&
                        _currentBook.isBundle != true) ...[
                      Builder(
                        builder: (context) {
                          final alreadyRead = _hasReadToday;
                          final borderColor =
                              alreadyRead ? Colors.grey : Colors.orange;
                          final contentColor =
                              alreadyRead ? Colors.grey : Colors.orange;
                          return Container(
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: borderColor, width: 2),
                            ),
                            child: InkWell(
                              onTap: alreadyRead ? null : _markAsReadToday,
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      alreadyRead
                                          ? Icons.check_circle
                                          : Icons.check_circle_outline,
                                      color: contentColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      alreadyRead
                                          ? AppLocalizations.of(
                                            context,
                                          )!.marked_read_today
                                          : AppLocalizations.of(
                                            context,
                                          )!.did_you_read_today,
                                      style: TextStyle(
                                        color: contentColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      AppTheme.verticalSpaceLarge,
                    ],

                    // Progress bar (only show for Started or Standby status)
                    if (_currentBook.statusValue?.toLowerCase() == 'started' ||
                        _currentBook.statusValue?.toLowerCase() ==
                            'standby') ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.2),
                          ),
                        ),
                        child: InkWell(
                          onTap: _showProgressModal,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.reading_progress,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    () {
                                      final progress =
                                          _currentBook.readingProgress ?? 0;
                                      if (_currentBook.progressType ==
                                              'pages' &&
                                          _currentBook.pages != null &&
                                          _currentBook.pages! > 0) {
                                        return '${(progress * 100 / _currentBook.pages!).round()}%';
                                      }
                                      return '$progress%';
                                    }(),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: () {
                                    final progress =
                                        _currentBook.readingProgress ?? 0;
                                    if (_currentBook.progressType == 'pages' &&
                                        _currentBook.pages != null &&
                                        _currentBook.pages! > 0) {
                                      return (progress / _currentBook.pages!)
                                          .clamp(0.0, 1.0);
                                    }
                                    return (progress / 100).clamp(0.0, 1.0);
                                  }(),
                                  minHeight: 8,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.tap_to_update_progress,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      AppTheme.verticalSpaceLarge,
                    ],

                    // Description - Collapsible (always shown)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          initiallyExpanded: _isDescriptionExpanded,
                          onExpansionChanged: (expanded) {
                            setState(() {
                              _isDescriptionExpanded = expanded;
                            });
                          },
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          childrenPadding: const EdgeInsets.only(
                            left: 12,
                            right: 12,
                            bottom: 12,
                          ),
                          title: Row(
                            children: [
                              Icon(
                                Icons.description,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                AppLocalizations.of(context)!.description,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (_currentBook.metadataSource != null) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _currentBook.metadataSource ==
                                            'google_books'
                                        ? AppLocalizations.of(
                                          context,
                                        )!.google_books
                                        : _currentBook.metadataSource ==
                                            'open_library'
                                        ? AppLocalizations.of(
                                          context,
                                        )!.open_library
                                        : 'API',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          children: [
                            if (_isFetchingMetadata)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12.0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.fetching_description,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (_currentBook.description != null &&
                                _currentBook.description!.isNotEmpty)
                              Text(
                                _currentBook.description!.replaceAll(
                                  '. ',
                                  '.\n',
                                ),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey[700]),
                              )
                            else
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.no_description_available,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
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

                    // Bundle Books - Show immediately after status for bundles
                    if (_currentBook.isBundle == true) ...[
                      const SizedBox(height: 12),
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
                                    Icons.menu_book,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Books in Bundle',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall?.copyWith(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              FutureBuilder<List<Book>>(
                                key: ValueKey(_bundleBooksKey),
                                future: _loadBundleBooks(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }

                                  if (snapshot.hasError) {
                                    return Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.error_loading_bundle_books,
                                        style: TextStyle(
                                          color: Colors.red[700],
                                        ),
                                      ),
                                    );
                                  }

                                  if (!snapshot.hasData ||
                                      snapshot.data!.isEmpty) {
                                    return Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.no_books_in_bundle,
                                      ),
                                    );
                                  }

                                  final bundleBooks = snapshot.data!;
                                  return Column(
                                    children:
                                        bundleBooks.asMap().entries.map((
                                          entry,
                                        ) {
                                          final index = entry.key;
                                          final book = entry.value;

                                          // Determine icon and color based on status
                                          IconData statusIcon;
                                          Color statusColor;
                                          if (book.statusValue == 'Yes') {
                                            statusIcon = Icons.check_circle;
                                            statusColor = Colors.green;
                                          } else if (book.statusValue ==
                                              'Started') {
                                            statusIcon = Icons.play_circle;
                                            statusColor = Colors.orange;
                                          } else {
                                            statusIcon = Icons.circle_outlined;
                                            statusColor = Colors.grey;
                                          }

                                          return Column(
                                            children: [
                                              if (index > 0)
                                                const Divider(height: 1),
                                              ListTile(
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 0,
                                                      vertical: 4,
                                                    ),
                                                leading: Icon(
                                                  statusIcon,
                                                  color: statusColor,
                                                  size: 28,
                                                ),
                                                title: Text(
                                                  book.name ??
                                                      AppLocalizations.of(
                                                        context,
                                                      )!.unknown_title,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                subtitle: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    if (book.author != null &&
                                                        book.author!.isNotEmpty)
                                                      Text(
                                                        book.author!,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          book.statusValue ??
                                                              AppLocalizations.of(
                                                                context,
                                                              )!.no_status,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: statusColor,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                        if (book.pages !=
                                                            null) ...[
                                                          Text(
                                                            ' • ${book.pages} pages',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color:
                                                                  Colors
                                                                      .grey[600],
                                                            ),
                                                          ),
                                                        ],
                                                        if (book.nSaga !=
                                                                null &&
                                                            book
                                                                .nSaga!
                                                                .isNotEmpty) ...[
                                                          Text(
                                                            ' • #${book.nSaga}',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color:
                                                                  Colors
                                                                      .grey[600],
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                trailing: const Icon(
                                                  Icons.arrow_forward_ios,
                                                  size: 16,
                                                ),
                                                onTap: () async {
                                                  // Navigate to individual book details
                                                  final result =
                                                      await Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder:
                                                              (context) =>
                                                                  BookDetailScreen(
                                                                    book: book,
                                                                  ),
                                                        ),
                                                      );
                                                  // Always reload bundle books when returning from individual book detail
                                                  // (status may have changed via Start Reading, edit, etc.)
                                                  if (mounted) {
                                                    if (result != null) {
                                                      await _loadReadDates();
                                                    }
                                                    if (mounted) {
                                                      setState(() {
                                                        _bundleBooksKey++;
                                                      });
                                                    }
                                                  }
                                                },
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Reading Time - only show for read books with data
                    if (_currentBook.statusValue?.toLowerCase() == 'yes' &&
                        (_chronometerSessions.isNotEmpty ||
                            _readDates.isNotEmpty ||
                            _bundleChronometerSessions.isNotEmpty))
                      _buildReadingTimeCard(),
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
                                    builder:
                                        (context) => BookDetailScreen(
                                          book: originalBook,
                                        ),
                                  ),
                                );
                              },
                              child: _DetailCard(
                                icon: Icons.repeat,
                                label:
                                    AppLocalizations.of(context)!.original_book,
                                value:
                                    '${originalBook.name}${originalBook.author != null ? " - ${originalBook.author}" : ""}',
                                trailingIcon: Icons.open_in_new,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    if (_currentBook.author != null &&
                        _currentBook.author!.isNotEmpty)
                      InkWell(
                        onTap: () {
                          // Parse authors (comma-separated)
                          final authors =
                              _currentBook.author!
                                  .split(',')
                                  .map((a) => a.trim())
                                  .where((a) => a.isNotEmpty)
                                  .toList();

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      BooksByAuthorScreen(authors: authors),
                            ),
                          );
                        },
                        child: _DetailCard(
                          icon: Icons.person,
                          label: AppLocalizations.of(context)!.author,
                          value: _currentBook.author!,
                          trailingIcon: Icons.open_in_new,
                        ),
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
                        label: AppLocalizations.of(context)!.editorial,
                        value: _currentBook.editorialValue!,
                      ),
                    if (_currentBook.genre != null &&
                        _currentBook.genre!.isNotEmpty)
                      _DetailCard(
                        icon: Icons.category,
                        label: AppLocalizations.of(context)!.genre,
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
                          label: AppLocalizations.of(context)!.saga,
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
                          label: AppLocalizations.of(context)!.saga_universe,
                          value: _currentBook.sagaUniverse!,
                          trailingIcon: Icons.open_in_new,
                        ),
                      ),
                    if (_currentBook.pages != null)
                      _DetailCard(
                        icon: Icons.description,
                        label: AppLocalizations.of(context)!.pages,
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
                        label: AppLocalizations.of(context)!.format_saga,
                        value: _currentBook.formatSagaValue!,
                      ),
                    if (_currentBook.languageValue != null &&
                        _currentBook.languageValue!.isNotEmpty)
                      _DetailCard(
                        icon: Icons.language,
                        label: AppLocalizations.of(context)!.language,
                        value: _currentBook.languageValue!,
                      ),
                    if (_currentBook.placeValue != null &&
                        _currentBook.placeValue!.isNotEmpty)
                      _DetailCard(
                        icon: Icons.place,
                        label: AppLocalizations.of(context)!.place,
                        value: _currentBook.placeValue!,
                      ),
                    if (_currentBook.formatValue != null &&
                        _currentBook.formatValue!.isNotEmpty)
                      _DetailCard(
                        icon: Icons.import_contacts,
                        label: AppLocalizations.of(context)!.format,
                        value: _currentBook.formatValue!,
                      ),
                    if (_currentBook.loaned != null &&
                        _currentBook.loaned!.isNotEmpty)
                      _DetailCard(
                        icon: Icons.swap_horiz,
                        label: AppLocalizations.of(context)!.loaned,
                        value: _currentBook.loaned!,
                      ),
                    if (_currentBook.createdAt != null &&
                        _currentBook.createdAt!.isNotEmpty)
                      _DetailCard(
                        icon: Icons.access_time,
                        label: AppLocalizations.of(context)!.created_label,
                        value: _formatDateTime(_currentBook.createdAt!),
                      ),

                    // Bundle Reading Sessions (only show for bundles)
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
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.bundle_reading_sessions,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall?.copyWith(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...List.generate(_currentBook.bundleCount ?? 0, (
                                bundleIndex,
                              ) {
                                final readDates =
                                    _bundleReadDates[bundleIndex] ?? [];
                                if (readDates.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _bundleBookTitles[bundleIndex] ??
                                            AppLocalizations.of(
                                              context,
                                            )!.book_n(bundleIndex + 1),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ...List.generate(readDates.length, (
                                        index,
                                      ) {
                                        final readDate = readDates[index];
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 4,
                                            left: 16,
                                          ),
                                          child: Row(
                                            children: [
                                              Text(
                                                '${index + 1}.',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  readDate.dateStarted != null
                                                      ? formatDateForDisplay(
                                                        readDate.dateStarted,
                                                      )
                                                      : AppLocalizations.of(
                                                        context,
                                                      )!.not_set,
                                                  style:
                                                      Theme.of(
                                                        context,
                                                      ).textTheme.bodySmall,
                                                ),
                                              ),
                                              const Text(' → '),
                                              Expanded(
                                                child: Text(
                                                  readDate.dateFinished != null
                                                      ? formatDateForDisplay(
                                                        readDate.dateFinished,
                                                      )
                                                      : AppLocalizations.of(
                                                        context,
                                                      )!.not_set,
                                                  style:
                                                      Theme.of(
                                                        context,
                                                      ).textTheme.bodySmall,
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

                    // Bundle Chronometer Sessions
                    if (_bundleChronometerSessions.isNotEmpty)
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
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.bundle_timed_reading_sessions,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall?.copyWith(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...List.generate(_currentBook.bundleCount ?? 0, (
                                bundleIndex,
                              ) {
                                final sessions =
                                    _bundleChronometerSessions[bundleIndex] ??
                                    [];
                                if (sessions.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _bundleBookTitles[bundleIndex] ??
                                            AppLocalizations.of(
                                              context,
                                            )!.book_n(bundleIndex + 1),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ...List.generate(sessions.length, (
                                        index,
                                      ) {
                                        final session = sessions[index];
                                        final duration =
                                            session.durationSeconds ?? 0;
                                        final hours = duration ~/ 3600;
                                        final minutes = (duration % 3600) ~/ 60;
                                        final seconds = duration % 60;
                                        String durationStr;
                                        if (hours > 0) {
                                          durationStr =
                                              '${hours}h ${minutes}m ${seconds}s';
                                        } else if (minutes > 0) {
                                          durationStr =
                                              '${minutes}m ${seconds}s';
                                        } else {
                                          durationStr = '${seconds}s';
                                        }

                                        // Format clicked_at time if available
                                        String clickedAtStr = '';
                                        if (session.clickedAt != null) {
                                          final clickedTime =
                                              session.clickedAt!;
                                          clickedAtStr =
                                              ' (Started: ${clickedTime.hour.toString().padLeft(2, '0')}:${clickedTime.minute.toString().padLeft(2, '0')})';
                                        }

                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 4,
                                            left: 16,
                                          ),
                                          child: Row(
                                            children: [
                                              Text(
                                                '${index + 1}.',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  '${formatDateForDisplay(session.startTime?.toIso8601String().split('T')[0] ?? 'Unknown')} - $durationStr$clickedAtStr',
                                                  style:
                                                      Theme.of(
                                                        context,
                                                      ).textTheme.bodySmall,
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
                                final db =
                                    await DatabaseHelper.instance.database;
                                await db.update(
                                  'book',
                                  {'tbr': 0},
                                  where: 'book_id = ?',
                                  whereArgs: [_currentBook.bookId],
                                );

                                if (context.mounted) {
                                  // Reload provider and navigate back
                                  final provider = Provider.of<BookProvider?>(
                                    context,
                                    listen: false,
                                  );
                                  await provider?.loadBooks();

                                  if (!context.mounted) return;
                                  // Refresh the screen by popping and pushing again
                                  final updatedBooks = provider?.allBooks ?? [];
                                  final updatedBook = updatedBooks.firstWhere(
                                    (b) => b.bookId == _currentBook.bookId,
                                    orElse: () => _currentBook,
                                  );

                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => BookDetailScreen(
                                            book: updatedBook,
                                          ),
                                    ),
                                  );

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.removed_from_tbr,
                                      ),
                                      backgroundColor: Colors.green,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
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
                            AppLocalizations.of(context)!.tbr_label,
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          subtitle: Text(
                            AppLocalizations.of(context)!.tbr_list_subtitle,
                          ),
                        ),
                      ),

                    // Notification Badge
                    if (_currentBook.notificationEnabled == true &&
                        _currentBook.notificationDatetime != null)
                      Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.notifications_active,
                            color: Colors.blue.shade700,
                          ),
                          title: Text(
                            AppLocalizations.of(context)!.release_notification,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            AppLocalizations.of(context)!.scheduled_for(
                              formatDateForDisplay(
                                _currentBook.notificationDatetime!.split(
                                  'T',
                                )[0],
                              ),
                            ),
                          ),
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
                        label: AppLocalizations.of(context)!.my_rating_label,
                        rating: _currentBook.myRating!,
                      ),

                    // Rating Breakdown
                    if (_currentBook.myRating != null &&
                        _currentBook.myRating! > 0)
                      FutureBuilder<List<BookRatingField>>(
                        future: _loadRatingFieldsForBook(_currentBook.bookId!),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ExpansionTile(
                              leading: Icon(
                                Icons.analytics,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              title: Text(
                                AppLocalizations.of(context)!.rating_breakdown,
                                style: Theme.of(
                                  context,
                                ).textTheme.titleSmall?.copyWith(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                _currentBook.ratingOverride == true
                                    ? AppLocalizations.of(
                                      context,
                                    )!.manual_rating
                                    : AppLocalizations.of(
                                      context,
                                    )!.auto_calculated,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              children:
                                  snapshot.data!
                                      .map(
                                        (field) => ListTile(
                                          title: Text(field.fieldName),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: List.generate(
                                              5,
                                              (i) => Icon(
                                                i < field.ratingValue.round()
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                color: Colors.red,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                          );
                        },
                      ),

                    // Price
                    if (_currentBook.price != null && _currentBook.price! >= 0)
                      _DetailCard(
                        icon: Icons.attach_money,
                        label: AppLocalizations.of(context)!.price_label,
                        value:
                            '$_currencySymbol${_currentBook.price!.toStringAsFixed(2)}',
                      ),

                    // Acquired Date
                    if (_currentBook.acquiredDate != null &&
                        _currentBook.acquiredDate!.isNotEmpty)
                      _DetailCard(
                        icon: Icons.calendar_today,
                        label: AppLocalizations.of(context)!.acquired_date,
                        value: () {
                          final a = _currentBook.acquiredDate!;
                          final parts = a.split('-');
                          if (parts.length == 3) {
                            return '${parts[2]}/${parts[1]}/${parts[0]}';
                          }
                          return a;
                        }(),
                      ),

                    if (_currentBook.readCount != null &&
                        _currentBook.readCount! > 0)
                      _DetailCard(
                        icon: Icons.add_circle_outline,
                        label: AppLocalizations.of(context)!.times_read,
                        value: '${_currentBook.readCount}',
                      ),

                    // Old date fields removed - now using Reading Sessions

                    // Reading Sessions Card
                    if (!(_currentBook.isBundle == true) &&
                        _readDates.isNotEmpty)
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
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    '${AppLocalizations.of(context)!.reading_history} (${_readDates.length})',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall?.copyWith(
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
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          readDate.dateStarted != null
                                              ? formatDateForDisplay(
                                                readDate.dateStarted,
                                              )
                                              : AppLocalizations.of(
                                                context,
                                              )!.not_set,
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                        ),
                                      ),
                                      const Text(' → '),
                                      Expanded(
                                        child: Text(
                                          readDate.dateFinished != null
                                              ? formatDateForDisplay(
                                                readDate.dateFinished,
                                              )
                                              : AppLocalizations.of(
                                                context,
                                              )!.not_set,
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
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
                    if (!(_currentBook.isBundle == true) &&
                        _chronometerSessions.isNotEmpty)
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
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      '${AppLocalizations.of(context)!.reading_sessions} (${_chronometerSessions.length})',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall?.copyWith(
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  // Edit icon
                                  if (_chronometerSessions.isNotEmpty)
                                    IconButton(
                                      onPressed: _showEditSessionsModal,
                                      icon: const Icon(Icons.edit, size: 20),
                                      tooltip:
                                          AppLocalizations.of(
                                            context,
                                          )!.edit_reading_sessions,
                                    ),
                                  // Plus icon
                                  IconButton(
                                    onPressed: _showAddSessionModal,
                                    icon: const Icon(Icons.add, size: 20),
                                    tooltip:
                                        AppLocalizations.of(
                                          context,
                                        )!.add_reading_session,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...List.generate(_chronometerSessions.length, (
                                index,
                              ) {
                                final session = _chronometerSessions[index];
                                String displayText;

                                // Check if there's duration data first
                                if (session.durationSeconds != null &&
                                    session.durationSeconds! > 0) {
                                  // Has duration - show it (regardless of didRead flag)
                                  final duration = session.durationSeconds!;
                                  final hours = duration ~/ 3600;
                                  final minutes = (duration % 3600) ~/ 60;
                                  final seconds = duration % 60;
                                  String durationStr;
                                  if (hours > 0) {
                                    durationStr =
                                        '${hours}h ${minutes}m ${seconds}s';
                                  } else if (minutes > 0) {
                                    durationStr = '${minutes}m ${seconds}s';
                                  } else {
                                    durationStr = '${seconds}s';
                                  }

                                  displayText =
                                      '${formatDateForDisplay(session.startTime?.toIso8601String().split('T')[0] ?? 'Unknown')} - $durationStr';
                                } else if (session.didRead) {
                                  // No duration but didRead - show "Read today"
                                  displayText =
                                      '${formatDateForDisplay(session.startTime?.toIso8601String().split('T')[0] ?? 'Unknown')} - ${AppLocalizations.of(context)!.read_today_check}';
                                } else {
                                  // No duration and not didRead - show date only
                                  displayText = formatDateForDisplay(
                                    session.startTime?.toIso8601String().split(
                                          'T',
                                        )[0] ??
                                        'Unknown',
                                  );
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Text(
                                        '${index + 1}.',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          displayText,
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
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
                                    AppLocalizations.of(context)!.my_review,
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

                    // Notes
                    if (_currentBook.notes != null &&
                        _currentBook.notes!.isNotEmpty)
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
                                    Icons.notes,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 24,
                                  ),
                                  AppTheme.horizontalSpaceLarge,
                                  Text(
                                    AppLocalizations.of(context)!.notes,
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
                                _currentBook.notes!,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Reading Clubs
                    BookClubsCard(
                      bookId: _currentBook.bookId!,
                      onClubsChanged: () {
                        // Optionally reload book data if needed
                      },
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
              builder:
                  (context) => ChronometerWidget(
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
            content: Text(
              AppLocalizations.of(context)!.copied_to_clipboard(value),
            ),
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
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
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
                        AppLocalizations.of(context)!.tandem_books,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.read_together_with,
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
                AppLocalizations.of(context)!.no_tandem_books,
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
                        color: Colors.deepPurple.withValues(alpha: 0.2),
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
                                book.name ??
                                    AppLocalizations.of(context)!.unknown_title,
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
              }),
          ],
        ),
      ),
    );
  }
}

/// Dialog for collecting ratings and review when finishing a book
class _FinishBookDialog extends StatefulWidget {
  final int bookId;
  final String bookName;

  const _FinishBookDialog({required this.bookId, required this.bookName});

  @override
  State<_FinishBookDialog> createState() => _FinishBookDialogState();
}

class _FinishBookDialogState extends State<_FinishBookDialog> {
  final TextEditingController _reviewController = TextEditingController();
  List<String> _availableFieldNames = [];
  final Map<String, double> _ratings = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFieldNames();
  }

  Future<void> _loadFieldNames() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRatingFieldRepository(db);
      final names = await repository.getAllFieldNames();

      setState(() {
        _availableFieldNames = names;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading field names: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        '${AppLocalizations.of(context)!.finish_book} "${widget.bookName}"',
      ),
      content:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.rate_reading_experience,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_availableFieldNames.isEmpty)
                      Text(
                        AppLocalizations.of(context)!.no_rating_fields,
                        style: const TextStyle(color: Colors.grey),
                      )
                    else
                      ..._availableFieldNames.map((fieldName) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fieldName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: List.generate(5, (index) {
                                  final starValue = (index + 1).toDouble();
                                  return IconButton(
                                    icon: Icon(
                                      _ratings[fieldName] != null &&
                                              _ratings[fieldName]! >= starValue
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _ratings[fieldName] = starValue;
                                      });
                                    },
                                  );
                                }),
                              ),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.write_review_optional,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _reviewController,
                      decoration: InputDecoration(
                        hintText:
                            AppLocalizations.of(context)!.share_your_thoughts,
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            // Convert ratings map to list format
            final ratingsList =
                _ratings.entries
                    .map((e) => {'fieldName': e.key, 'ratingValue': e.value})
                    .toList();

            Navigator.pop(context, {
              'ratings': ratingsList,
              'review': _reviewController.text.trim(),
            });
          },
          child: Text(AppLocalizations.of(context)!.finish_book),
        ),
      ],
    );
  }
}

/// Internal data structure representing the conceptual DailyReadings table
class _DailyReadingData {
  final int totalDaysWithTimeRead; // Days where timeRead > 0
  final int
  totalDaysWithDidReadOnly; // Days where didReadToday = true but no timeRead
  final int totalSecondsRead; // Sum of all timeRead values (in seconds)
  final int totalReadingDays; // Total unique reading days
  final bool hasTimeReadData; // Whether any day has timeRead > 0
  final bool hasDidReadData; // Whether any day has didReadToday = true

  _DailyReadingData({
    required this.totalDaysWithTimeRead,
    required this.totalDaysWithDidReadOnly,
    required this.totalSecondsRead,
    required this.totalReadingDays,
    required this.hasTimeReadData,
    required this.hasDidReadData,
  });
}

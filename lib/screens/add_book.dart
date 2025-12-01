import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/model/read_date.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/utils/status_helper.dart';
import 'package:myrandomlibrary/widgets/autocomplete_text_field.dart';
import 'package:myrandomlibrary/widgets/chip_autocomplete_field.dart';
import 'package:myrandomlibrary/widgets/tbr_limit_setting.dart';
import 'package:myrandomlibrary/widgets/bundle_input_widget_v2.dart';
import 'package:myrandomlibrary/widgets/read_dates_widget.dart';
import 'package:myrandomlibrary/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:myrandomlibrary/widgets/heart_rating_input.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _nameController = TextEditingController();
  final _isbnController = TextEditingController();
  final _asinController = TextEditingController();
  final _authorController = TextEditingController();
  final _sagaController = TextEditingController();
  final _nSagaController = TextEditingController();
  final _sagaUniverseController = TextEditingController();
  final _pagesController = TextEditingController();
  final _publicationYearController = TextEditingController();
  DateTime? _releaseDate;
  final _editorialController = TextEditingController();
  final _genreController = TextEditingController();
  final _myReviewController = TextEditingController();
  double _myRating = 0.0;
  int _readCount = 0;

  // Read dates (new multi-session system)
  List<ReadDate> _readDates = [];

  // Bundle fields
  bool _isBundle = false;
  int? _bundleCount;
  List<BundleBookData>? _bundleBooks;

  // TBR and Tandem fields
  bool _tbr = false;
  bool _isTandem = false;

  // Notification fields
  bool _notificationEnabled = false;
  DateTime? _notificationDateTime;
  TimeOfDay? _notificationTime;

  // Dropdown values
  int? _selectedStatusId;
  String? _selectedStatusValue;
  int? _selectedOriginalBookId; // For repeated books
  int? _selectedFormatSagaId;
  int? _selectedLanguageId;
  int? _selectedPlaceId;
  int? _selectedFormatId;
  String? _selectedLoaned;

  // Lookup table data
  List<Map<String, dynamic>> _statusList = [];
  List<Map<String, dynamic>> _formatSagaList = [];
  List<Map<String, dynamic>> _languageList = [];
  List<Map<String, dynamic>> _placeList = [];
  List<Map<String, dynamic>> _formatList = [];

  // Autocomplete suggestions
  List<String> _authorSuggestions = [];
  List<String> _genreSuggestions = [];
  List<String> _editorialSuggestions = [];
  List<String> _sagaSuggestions = [];
  List<String> _sagaUniverseSuggestions = [];

  // Multi-value fields
  List<String> _selectedAuthors = [];
  List<String> _selectedGenres = [];

  bool _isLoading = true;

  /// Capitalize only the first letter, rest lowercase
  String _capitalizeFirstWord(String text) {
    if (text.isEmpty) return text;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
  }

  /// Get publication year or full date (YYYYMMDD) for TBReleased books
  int? _getPublicationYearOrDate() {
    final yearStr = _publicationYearController.text.trim();
    if (yearStr.isEmpty) return null;

    final year = int.tryParse(yearStr);
    if (year == null) return null;

    // Check if this is a TBReleased book with release date
    final isTBReleased =
        _statusList.isNotEmpty &&
        _selectedStatusId != null &&
        _statusList.any(
          (s) =>
              s['status_id'] == _selectedStatusId &&
              (s['value'] as String).toLowerCase() == 'tbreleased',
        );

    if (isTBReleased && _releaseDate != null) {
      // Store as YYYYMMDD
      return _releaseDate!.year * 10000 +
          _releaseDate!.month * 100 +
          _releaseDate!.day;
    }

    // Just return the year
    return year;
  }

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);

      final status = await repository.getLookupValues('status');
      final formatSaga = await repository.getLookupValues('format_saga');
      final language = await repository.getLookupValues('language');
      final place = await repository.getLookupValues('place');
      final format = await repository.getLookupValues('format');
      final authors = await repository.getLookupValues('author');
      final genres = await repository.getLookupValues('genre');
      final editorials = await repository.getLookupValues('editorial');
      final sagas = await repository.getDistinctSagas();
      final sagaUniverses = await repository.getDistinctSagaUniverses();

      setState(() {
        // Deduplicate lists by ID to avoid dropdown errors
        _statusList = _deduplicateById(status, 'status_id');
        _formatSagaList = _deduplicateById(formatSaga, 'format_id');
        _languageList = _deduplicateById(language, 'language_id');
        _placeList = _deduplicateById(place, 'place_id');
        _formatList = _deduplicateById(format, 'format_id');
        _authorSuggestions = authors.map((a) => a['name'] as String).toList();
        _genreSuggestions = genres.map((g) => g['name'] as String).toList();
        _editorialSuggestions =
            editorials.map((e) => e['name'] as String).toList();
        _sagaSuggestions = sagas;
        _sagaUniverseSuggestions = sagaUniverses;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading dropdown data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _deduplicateById(
    List<Map<String, dynamic>> list,
    String idColumn,
  ) {
    final seen = <int>{};
    final seenValues = <String>{};
    final result = <Map<String, dynamic>>[];

    // Determine value column based on table
    final valueColumn =
        idColumn.contains('status') || idColumn.contains('format')
            ? 'value'
            : 'name';

    for (final item in list) {
      final id = item[idColumn] as int?;
      final value = item[valueColumn]?.toString().toLowerCase();

      // Skip if we've seen this ID or this value (case-insensitive)
      if (id != null &&
          !seen.contains(id) &&
          (value == null || !seenValues.contains(value))) {
        seen.add(id);
        if (value != null) seenValues.add(value);
        result.add(item);
      }
    }

    return result;
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (BuildContext dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Book Added Successfully!',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'What would you like to do next?',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton.icon(
                onPressed: () async {
                  debugPrint(
                    '📚 Add Another clicked - reloading dropdown data...',
                  );
                  Navigator.of(dialogContext).pop();
                  // Reload dropdown data to include newly added authors, sagas, etc.
                  await _loadDropdownData();
                  debugPrint('✅ Dropdown data reloaded successfully');
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Another'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  // Go back to previous screen (home)
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.home),
                label: const Text('Go to Home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
            actionsAlignment: MainAxisAlignment.spaceEvenly,
          ),
    );
  }

  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate Tandem book requires saga or saga universe
    if (_isTandem &&
        _sagaController.text.trim().isEmpty &&
        _sagaUniverseController.text.trim().isEmpty) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  const Text('Missing Information'),
                ],
              ),
              content: const Text(
                'Tandem books must have a Saga or Saga Universe.\n\n'
                'Please fill in at least one of these fields to mark this book as Tandem.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
      return;
    }

    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);

      // Get the actual values from IDs
      String? statusValue =
          _selectedStatusId != null
              ? _statusList.firstWhere(
                    (s) => s['status_id'] == _selectedStatusId,
                  )['value']
                  as String?
              : null;
      String? formatSagaValue =
          _selectedFormatSagaId != null
              ? _formatSagaList.firstWhere(
                    (f) => f['format_id'] == _selectedFormatSagaId,
                  )['value']
                  as String?
              : null;
      String? languageValue =
          _selectedLanguageId != null
              ? _languageList.firstWhere(
                    (l) => l['language_id'] == _selectedLanguageId,
                  )['name']
                  as String?
              : null;
      String? placeValue =
          _selectedPlaceId != null
              ? _placeList.firstWhere(
                    (p) => p['place_id'] == _selectedPlaceId,
                  )['name']
                  as String?
              : null;
      String? formatValue =
          _selectedFormatId != null
              ? _formatList.firstWhere(
                    (f) => f['format_id'] == _selectedFormatId,
                  )['value']
                  as String?
              : null;

      final book = Book(
        bookId: null,
        name:
            _nameController.text.trim().isEmpty
                ? null
                : _capitalizeFirstWord(_nameController.text.trim()),
        isbn:
            _isbnController.text.trim().isEmpty
                ? null
                : _isbnController.text.trim(),
        asin:
            _asinController.text.trim().isEmpty
                ? null
                : _asinController.text.trim(),
        author: _selectedAuthors.isEmpty ? null : _selectedAuthors.join(', '),
        saga:
            _sagaController.text.trim().isEmpty
                ? null
                : _capitalizeFirstWord(_sagaController.text.trim()),
        nSaga:
            _nSagaController.text.trim().isEmpty
                ? null
                : _nSagaController.text.trim(),
        sagaUniverse:
            _sagaUniverseController.text.trim().isEmpty
                ? null
                : _sagaUniverseController.text.trim(),
        pages:
            _pagesController.text.trim().isEmpty
                ? null
                : int.tryParse(_pagesController.text.trim()),
        originalPublicationYear: _getPublicationYearOrDate(),
        loaned:
            (_selectedLoaned ?? 'no').toLowerCase(), // Normalize to lowercase
        statusValue: statusValue,
        editorialValue:
            _editorialController.text.trim().isEmpty
                ? null
                : _editorialController.text.trim(),
        languageValue: languageValue,
        placeValue: placeValue,
        formatValue: formatValue,
        formatSagaValue: formatSagaValue,
        createdAt: DateTime.now().toIso8601String(),
        genre: _selectedGenres.isEmpty ? null : _selectedGenres.join(', '),
        dateReadInitial: null,
        dateReadFinal: null,
        readCount: _readCount,
        myRating: _myRating > 0 ? _myRating : null,
        myReview:
            _myReviewController.text.trim().isEmpty
                ? null
                : _myReviewController.text.trim(),
        isBundle: _isBundle,
        bundleCount: _bundleCount,
        bundleNumbers: null, // No longer used in new system
        bundleStartDates: null,
        bundleEndDates: null,
        bundlePages: null, // No longer used in new system
        bundlePublicationYears: null, // No longer used in new system
        bundleTitles: null, // No longer used in new system
        bundleAuthors: null, // No longer used in new system
        tbr: _tbr,
        isTandem: _isTandem,
        originalBookId: _selectedOriginalBookId,
        notificationEnabled: _notificationEnabled,
        notificationDatetime:
            _notificationEnabled && _notificationDateTime != null
                ? _notificationDateTime!.toIso8601String()
                : null,
        bundleParentId: null, // This is the parent book
      );

      final bookId = await repository.addBook(book);

      // If this is a bundle, create individual books
      if (_isBundle && _bundleBooks != null && _bundleBooks!.isNotEmpty) {
        for (int i = 0; i < _bundleBooks!.length; i++) {
          final bundleBookData = _bundleBooks![i];

          // Create individual book with parent's shared data
          final individualBook = Book(
            bookId: null,
            name: bundleBookData.title ?? 'Book ${i + 1}',
            isbn: null, // Individual books don't have ISBN
            asin: null,
            saga:
                _sagaController.text.trim().isEmpty
                    ? null
                    : _sagaController.text.trim(),
            nSaga: bundleBookData.sagaNumber,
            sagaUniverse:
                _sagaUniverseController.text.trim().isEmpty
                    ? null
                    : _sagaUniverseController.text.trim(),
            pages: bundleBookData.pages,
            originalPublicationYear: bundleBookData.publicationYear,
            loaned: (_selectedLoaned ?? 'no').toLowerCase(),
            statusValue: bundleBookData.status ?? 'No',
            editorialValue:
                _editorialController.text.trim().isEmpty
                    ? null
                    : _editorialController.text.trim(),
            languageValue: languageValue,
            placeValue: placeValue,
            formatValue: formatValue,
            formatSagaValue: formatSagaValue,
            createdAt: DateTime.now().toIso8601String(),
            author:
                bundleBookData.author ??
                (_selectedAuthors.isEmpty ? null : _selectedAuthors.join(', ')),
            genre: _selectedGenres.isEmpty ? null : _selectedGenres.join(', '),
            dateReadInitial: null,
            dateReadFinal: null,
            readCount: 0,
            myRating: null,
            myReview: null,
            isBundle: false, // Individual books are not bundles
            bundleCount: null,
            bundleNumbers: null,
            bundleStartDates: null,
            bundleEndDates: null,
            bundlePages: null,
            bundlePublicationYears: null,
            bundleTitles: null,
            bundleAuthors: null,
            tbr: false,
            isTandem: false,
            originalBookId: null,
            notificationEnabled: false,
            notificationDatetime: null,
            bundleParentId: bookId, // Link to parent bundle
          );

          await repository.addBook(individualBook);
        }
      }

      // Save read dates for non-bundle books only
      if (!_isBundle) {
        for (final readDate in _readDates) {
          await repository.addReadDate(
            ReadDate(
              bookId: bookId,
              dateStarted: readDate.dateStarted,
              dateFinished: readDate.dateFinished,
            ),
          );
        }
      }

      // Schedule notification if enabled
      if (_notificationEnabled && _notificationDateTime != null) {
        try {
          debugPrint('📅 Attempting to schedule notification...');
          debugPrint('📅 Book ID: $bookId');
          debugPrint('📅 Scheduled date: $_notificationDateTime');
          debugPrint('📅 Current time: ${DateTime.now()}');
          
          final notificationService = NotificationService();
          final permissionGranted = await notificationService.requestPermissions();
          debugPrint('📅 Permission granted: $permissionGranted');
          
          // Only schedule if the datetime is in the future
          if (_notificationDateTime!.isAfter(DateTime.now())) {
            await notificationService.scheduleBookReleaseNotification(
              bookId: bookId,
              bookTitle: _nameController.text.trim(),
              scheduledDate: _notificationDateTime!,
            );
            debugPrint('✅ Notification scheduled successfully for book ID: $bookId');
          } else {
            debugPrint('⚠️ Notification time is in the past, not scheduling');
          }
        } catch (e) {
          debugPrint('❌ Error scheduling notification: $e');
        }
      }

      // Reload books in provider
      if (mounted) {
        final provider = Provider.of<BookProvider?>(context, listen: false);
        await provider?.loadBooks();

        debugPrint('📖 Book saved successfully with ID: $bookId');
        debugPrint('🧹 Clearing form and resetting state...');

        // Clear form first
        _formKey.currentState!.reset();
        _nameController.clear();
        _isbnController.clear();
        _asinController.clear();
        _authorController.clear();
        _sagaController.clear();
        _nSagaController.clear();
        _sagaUniverseController.clear();
        _pagesController.clear();
        _publicationYearController.clear();
        _releaseDate = null;
        _notificationEnabled = false;
        _notificationDateTime = null;
        _notificationTime = null;
        _editorialController.clear();
        _genreController.clear();
        _myReviewController.clear();

        setState(() {
          _myRating = 0.0;
          _readCount = 0;
          _readDates = [];
          _selectedAuthors = [];
          _selectedGenres = [];
          _selectedStatusId = null;
          _selectedStatusValue = null;
          _selectedOriginalBookId = null;
          _selectedFormatSagaId = null;
          _selectedLanguageId = null;
          _selectedPlaceId = null;
          _selectedFormatId = null;
          _selectedLoaned = null;
          _isBundle = false;
          _bundleCount = null;
          _bundleBooks = null;
          _tbr = false;
          _isTandem = false;
        });

        debugPrint('✅ Form cleared. Controllers reset:');
        debugPrint('   - Name: "${_nameController.text}"');
        debugPrint('   - Author: "${_authorController.text}"');
        debugPrint('   - Saga: "${_sagaController.text}"');
        debugPrint('   - Selected Authors: $_selectedAuthors');
        debugPrint('   - Selected Genres: $_selectedGenres');
        debugPrint('   - Selected Status: $_selectedStatusId');

        // Show success dialog
        _showSuccessDialog(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding book: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<List<Book>> _loadAllBooksForSelection() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);
      final books = await repository.getAllBooks();
      // Filter out books with status "Repeated" to avoid circular references
      return books.where((b) => b.statusValue != 'Repeated').toList();
    } catch (e) {
      debugPrint('Error loading books for selection: $e');
      return [];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _isbnController.dispose();
    _authorController.dispose();
    _sagaController.dispose();
    _nSagaController.dispose();
    _pagesController.dispose();
    _publicationYearController.dispose();
    _editorialController.dispose();
    _genreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Book'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status dropdown (required) - MOVED TO TOP
              DropdownButtonFormField<int>(
                value: _selectedStatusId,
                decoration: const InputDecoration(
                  labelText: 'Reading Status *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.check_circle),
                ),
                items:
                    _statusList.map((status) {
                      return DropdownMenuItem<int>(
                        value: status['status_id'] as int,
                        child: Text(
                          StatusHelper.getDisplayLabel(
                            status['value'] as String,
                          ),
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStatusId = value;
                    // Find the status value
                    final status = _statusList.firstWhere(
                      (s) => s['status_id'] == value,
                      orElse: () => {},
                    );
                    _selectedStatusValue = status['value'] as String?;
                    // Clear original book if status is not Repeated
                    if (_selectedStatusValue != 'Repeated') {
                      _selectedOriginalBookId = null;
                    }
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Status is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Original Book Selection (shown only for Repeated status)
              if (_selectedStatusValue == 'Repeated')
                FutureBuilder<List<Book>>(
                  future: _loadAllBooksForSelection(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox(
                        height: 50,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final books = snapshot.data!;
                    Book? selectedBook;
                    if (_selectedOriginalBookId != null) {
                      try {
                        selectedBook = books.firstWhere(
                          (b) => b.bookId == _selectedOriginalBookId,
                        );
                      } catch (e) {
                        selectedBook = null;
                      }
                    }

                    return Autocomplete<Book>(
                      initialValue:
                          _selectedOriginalBookId != null &&
                                  selectedBook != null
                              ? TextEditingValue(
                                text:
                                    '${selectedBook.name}${selectedBook.author != null ? " - ${selectedBook.author}" : ""}',
                              )
                              : const TextEditingValue(),
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return books;
                        }
                        return books.where((book) {
                          final searchText =
                              textEditingValue.text.toLowerCase();
                          final bookText =
                              '${book.name} ${book.author ?? ""}'.toLowerCase();
                          return bookText.contains(searchText);
                        });
                      },
                      displayStringForOption:
                          (Book book) =>
                              '${book.name}${book.author != null ? " - ${book.author}" : ""}',
                      onSelected: (Book book) {
                        setState(() {
                          _selectedOriginalBookId = book.bookId;
                        });
                      },
                      fieldViewBuilder: (
                        context,
                        controller,
                        focusNode,
                        onFieldSubmitted,
                      ) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'Original Book *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.book),
                            hintText: 'Search for the original book...',
                          ),
                          validator: (value) {
                            if (_selectedStatusValue == 'Repeated' &&
                                _selectedOriginalBookId == null) {
                              return 'Original book is required';
                            }
                            return null;
                          },
                        );
                      },
                    );
                  },
                ),
              if (_selectedStatusValue == 'Repeated')
                const SizedBox(height: 16),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Book Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.book),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),

              // ISBN field
              TextFormField(
                controller: _isbnController,
                decoration: InputDecoration(
                  labelText: 'ISBN',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.numbers),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner_outlined),
                    onPressed: () => _scanISBN(),
                    tooltip: 'Scan ISBN',
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // ASIN field
              TextFormField(
                controller: _asinController,
                decoration: const InputDecoration(
                  labelText: 'ASIN',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.qr_code),
                ),
              ),
              const SizedBox(height: 16),

              // Author field
              ChipAutocompleteField(
                labelText: 'Author(s)',
                prefixIcon: Icons.person,
                suggestions: _authorSuggestions,
                initialValues: _selectedAuthors,
                hintText: 'Type to search or add new author',
                onChanged: (values) {
                  setState(() {
                    _selectedAuthors = values;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Editorial field
              AutocompleteTextField(
                controller: _editorialController,
                labelText: AppLocalizations.of(context)!.editorial,
                prefixIcon: Icons.business,
                suggestions: _editorialSuggestions,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Genre field
              ChipAutocompleteField(
                labelText: 'Genre(s)',
                prefixIcon: Icons.category,
                suggestions: _genreSuggestions,
                initialValues: _selectedGenres,
                hintText: 'Type to search or add new genre',
                onChanged: (values) {
                  setState(() {
                    _selectedGenres = values;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Saga field
              AutocompleteTextField(
                controller: _sagaController,
                labelText: AppLocalizations.of(context)!.saga,
                prefixIcon: Icons.collections_bookmark,
                suggestions: _sagaSuggestions,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // N Saga field
              TextFormField(
                controller: _nSagaController,
                decoration: const InputDecoration(
                  labelText: 'Saga Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.format_list_numbered),
                ),
              ),
              const SizedBox(height: 16),

              // Saga Universe field
              AutocompleteTextField(
                controller: _sagaUniverseController,
                labelText: AppLocalizations.of(context)!.saga_universe,
                prefixIcon: Icons.public,
                suggestions: _sagaUniverseSuggestions,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Pages field
              TextFormField(
                controller: _pagesController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.pages,
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),

              // Publication Year field
              TextFormField(
                controller: _publicationYearController,
                decoration: const InputDecoration(
                  labelText: 'Publication Year',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),

              // Release date picker (only for TBReleased books)
              if (_statusList.isNotEmpty &&
                  _selectedStatusId != null &&
                  _statusList.any(
                    (s) =>
                        s['status_id'] == _selectedStatusId &&
                        (s['value'] as String).toLowerCase() == 'tbreleased',
                  ))
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Original Publication Date (for notifications)',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _releaseDate ?? DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            _releaseDate = pickedDate;
                            // Update publication year to match
                            _publicationYearController.text =
                                pickedDate.year.toString();
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Release Date',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _releaseDate != null
                              ? '${_releaseDate!.day}/${_releaseDate!.month}/${_releaseDate!.year}'
                              : 'Select release date',
                          style: TextStyle(
                            color: _releaseDate != null ? null : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Notification checkbox
                    CheckboxListTile(
                      title: const Text('Enable Release Notification'),
                      subtitle: const Text(
                        'Get notified when this book is released',
                      ),
                      value: _notificationEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationEnabled = value ?? false;
                          if (_notificationEnabled &&
                              _notificationDateTime == null) {
                            // Set default notification time to release date at 9 AM
                            _notificationDateTime =
                                _releaseDate != null
                                    ? DateTime(
                                      _releaseDate!.year,
                                      _releaseDate!.month,
                                      _releaseDate!.day,
                                      9,
                                      0,
                                    )
                                    : DateTime.now().add(
                                      const Duration(days: 1),
                                    );
                            _notificationTime = const TimeOfDay(
                              hour: 9,
                              minute: 0,
                            );
                          }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),

                    // Notification datetime picker
                    if (_notificationEnabled) ...[
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate:
                                _notificationDateTime ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime:
                                  _notificationTime ??
                                  const TimeOfDay(hour: 9, minute: 0),
                            );
                            if (pickedTime != null) {
                              setState(() {
                                _notificationDateTime = DateTime(
                                  pickedDate.year,
                                  pickedDate.month,
                                  pickedDate.day,
                                  pickedTime.hour,
                                  pickedTime.minute,
                                );
                                _notificationTime = pickedTime;
                              });
                            }
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Notification Date & Time',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.notifications_active),
                          ),
                          child: Text(
                            _notificationDateTime != null
                                ? '${_notificationDateTime!.day}/${_notificationDateTime!.month}/${_notificationDateTime!.year} at ${_notificationTime!.format(context)}'
                                : 'Select notification date and time',
                            style: TextStyle(
                              color:
                                  _notificationDateTime != null
                                      ? null
                                      : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),

              // Format Saga dropdown
              DropdownButtonFormField<int>(
                value: _selectedFormatSagaId,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.format_saga,
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.format_shapes),
                ),
                items:
                    _formatSagaList.map((format) {
                      return DropdownMenuItem<int>(
                        value: format['format_id'] as int,
                        child: Text(format['value'] as String),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFormatSagaId = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Language dropdown
              DropdownButtonFormField<int>(
                value: _selectedLanguageId,
                decoration: const InputDecoration(
                  labelText: 'Language',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.language),
                ),
                items:
                    _languageList.map((lang) {
                      return DropdownMenuItem<int>(
                        value: lang['language_id'] as int,
                        child: Text(lang['name'] as String),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedLanguageId = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Place dropdown
              DropdownButtonFormField<int>(
                value: _selectedPlaceId,
                decoration: const InputDecoration(
                  labelText: 'Place',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.place),
                ),
                items:
                    _placeList.map((place) {
                      return DropdownMenuItem<int>(
                        value: place['place_id'] as int,
                        child: Text(place['name'] as String),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPlaceId = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Format dropdown
              DropdownButtonFormField<int>(
                value: _selectedFormatId,
                decoration: const InputDecoration(
                  labelText: 'Format',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.import_contacts),
                ),
                items:
                    _formatList.map((format) {
                      return DropdownMenuItem<int>(
                        value: format['format_id'] as int,
                        child: Text(format['value'] as String),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFormatId = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Loaned dropdown
              DropdownButtonFormField<String>(
                value: _selectedLoaned,
                decoration: const InputDecoration(
                  labelText: 'Loaned',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.swap_horiz),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'yes',
                    child: Text(AppLocalizations.of(context)!.yes),
                  ),
                  DropdownMenuItem(
                    value: 'no',
                    child: Text(AppLocalizations.of(context)!.no),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedLoaned = value;
                  });
                },
              ),
              const SizedBox(height: 32),

              // Bundle section
              BundleInputWidgetV2(
                initialIsBundle: _isBundle,
                initialBundleCount: _bundleCount,
                initialBundleBooks: _bundleBooks,
                statusOptions: _statusList,
                onChanged: (isBundle, count, bundleBooks) {
                  setState(() {
                    _isBundle = isBundle;
                    _bundleCount = count;
                    _bundleBooks = bundleBooks;
                  });
                },
              ),
              const SizedBox(height: 16),

              // TBR and Tandem section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Book Lists',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        title: const Text('Add to TBR (To Be Read)'),
                        subtitle: const Text(
                          'Mark this book for your reading list',
                        ),
                        value: _tbr,
                        onChanged: (value) async {
                          if (value == true) {
                            // Check TBR limit
                            final db = await DatabaseHelper.instance.database;
                            final repository = BookRepository(db);
                            final currentCount = await repository.getTBRCount();
                            final limit = await getTBRLimit();

                            if (currentCount >= limit) {
                              if (mounted) {
                                showDialog(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: Row(
                                          children: [
                                            Icon(
                                              Icons.warning_amber,
                                              color: Colors.orange,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text('TBR Limit Reached'),
                                          ],
                                        ),
                                        content: Text(
                                          'You have reached your TBR limit of $limit books.\n\n'
                                          'Please uncheck some books in the My Books screen to add more.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(context),
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      ),
                                );
                              }
                              return;
                            }
                          }
                          setState(() {
                            _tbr = value ?? false;
                          });
                        },
                        secondary: const Icon(Icons.bookmark_add),
                      ),
                      CheckboxListTile(
                        title: const Text('Mark as Tandem Book'),
                        subtitle: const Text(
                          'Read together with other books in this saga',
                        ),
                        value: _isTandem,
                        onChanged: (value) {
                          setState(() {
                            _isTandem = value ?? false;
                          });
                        },
                        secondary: const Icon(
                          Icons.swap_horizontal_circle_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // New fields section
              Text(
                'Reading Information (Optional)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),

              // My Rating with hearts
              HeartRatingInput(
                initialRating: _myRating,
                onRatingChanged: (rating) {
                  setState(() {
                    _myRating = rating;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Read Count with - and + buttons
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Times Read',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Minus button
                      IconButton(
                        onPressed:
                            _readCount > 0
                                ? () {
                                  setState(() {
                                    _readCount--;
                                  });
                                }
                                : null,
                        icon: const Icon(Icons.remove),
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1),
                          foregroundColor:
                              Theme.of(context).colorScheme.primary,
                          disabledBackgroundColor: Colors.grey[200],
                          disabledForegroundColor: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_readCount',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Plus button
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _readCount++;
                          });
                        },
                        icon: const Icon(Icons.add),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Reading Sessions (hidden for bundles)
              if (!_isBundle)
                ReadDatesWidget(
                  bookId: 0, // Temporary ID for new books
                  initialReadDates: _readDates,
                  onChanged: (readDates) {
                    setState(() {
                      _readDates = readDates;
                      // Update read count based on finished sessions
                      _readCount =
                          readDates
                              .where(
                                (rd) =>
                                    rd.dateFinished != null &&
                                    rd.dateFinished!.isNotEmpty,
                              )
                              .length;
                    });
                  },
                ),
              if (!_isBundle) const SizedBox(height: 16),

              // My Review field
              TextFormField(
                controller: _myReviewController,
                decoration: const InputDecoration(
                  labelText: 'My Review',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.rate_review),
                  hintText: 'Write your thoughts about this book...',
                ),
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 32),

              // Save button
              ElevatedButton(
                onPressed: _saveBook,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Add Book',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _scanISBN() async {
    try {
      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => const ISBNScannerScreen()),
      );

      if (result != null && result.isNotEmpty) {
        setState(() {
          _isbnController.text = result;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning ISBN: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class ISBNScannerScreen extends StatefulWidget {
  const ISBNScannerScreen({super.key});

  @override
  State<ISBNScannerScreen> createState() => _ISBNScannerScreenState();
}

class _ISBNScannerScreenState extends State<ISBNScannerScreen> {
  late MobileScannerController controller;
  bool _scanned = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      formats: const [
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.code128,
      ],
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan ISBN'), centerTitle: true),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (_scanned) return;

              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
                  _scanned = true;
                  // Return the scanned ISBN
                  Navigator.pop(context, barcode.rawValue);
                  return;
                }
              }
            },
          ),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Point camera at barcode',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

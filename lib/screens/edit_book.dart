import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/model/read_date.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/utils/status_helper.dart';
import 'package:myrandomlibrary/widgets/autocomplete_text_field.dart';
import 'package:myrandomlibrary/widgets/bundle_input_widget.dart';
import 'package:myrandomlibrary/widgets/bundle_read_dates_widget.dart';
import 'package:myrandomlibrary/widgets/chip_autocomplete_field.dart';
import 'package:myrandomlibrary/widgets/heart_rating_input.dart';
import 'package:myrandomlibrary/widgets/read_dates_widget.dart';
import 'package:myrandomlibrary/widgets/tbr_limit_setting.dart';
import 'package:provider/provider.dart';

class EditBookScreen extends StatefulWidget {
  final Book book;

  const EditBookScreen({super.key, required this.book});

  @override
  State<EditBookScreen> createState() => _EditBookScreenState();
}

class _EditBookScreenState extends State<EditBookScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  late TextEditingController _nameController;
  late TextEditingController _isbnController;
  late TextEditingController _asinController;
  late TextEditingController _authorController;
  late TextEditingController _sagaController;
  late TextEditingController _nSagaController;
  late TextEditingController _sagaUniverseController;
  late TextEditingController _pagesController;
  late TextEditingController _publicationYearController;
  DateTime? _releaseDate;
  late TextEditingController _editorialController;
  late TextEditingController _genreController;
  late TextEditingController _myReviewController;
  late double _myRating;
  late int _readCount;
  
  // Read dates (new multi-session system)
  List<ReadDate> _readDates = [];
  
  // Bundle read dates (map of bundle book index to list of read dates)
  Map<int, List<ReadDate>> _bundleReadDates = {};

  // Bundle fields
  late bool _isBundle = false;
  int? _bundleCount;
  String? _bundleNumbers;
  List<int?>? _bundlePages;
  List<int?>? _bundlePublicationYears;
  List<String?>? _bundleTitles;

  // TBR and Tandem fields
  late bool _tbr;
  late bool _isTandem;
  
  // Repeated books
  String? _selectedStatusValue;
  int? _selectedOriginalBookId;

  // Dropdown values
  int? _selectedStatusId;
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
  
  // Manual bundle read status (for books without reading sessions)
  Map<int, bool> _manualBundleReadStatus = {};

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
    _initializeControllers();
    _loadDropdownData();
    _loadReadDates();
    _loadBundleReadDates();
  }
  
  Future<void> _loadReadDates() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);
      final readDates = await repository.getReadDatesForBook(widget.book.bookId!);
      setState(() {
        _readDates = readDates;
      });
    } catch (e) {
      debugPrint('Error loading read dates: $e');
    }
  }
  
  Future<void> _loadBundleReadDates() async {
    if (widget.book.isBundle != true) return;
    
    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);
      final bundleReadDates = await repository.getAllBundleReadDates(widget.book.bookId!);
      setState(() {
        _bundleReadDates = bundleReadDates;
      });
    } catch (e) {
      debugPrint('Error loading bundle read dates: $e');
    }
  }
  
  Future<List<Book>> _loadAllBooksForSelection() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);
      final books = await repository.getAllBooks();
      // Filter out books with status "Repeated" and the current book
      return books.where((b) => 
        b.statusValue != 'Repeated' && b.bookId != widget.book.bookId
      ).toList();
    } catch (e) {
      debugPrint('Error loading books for selection: $e');
      return [];
    }
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.book.name ?? '');
    _isbnController = TextEditingController(text: widget.book.isbn ?? '');
    _asinController = TextEditingController(text: widget.book.asin ?? '');
    _authorController = TextEditingController(text: widget.book.author ?? '');
    _editorialController = TextEditingController(
      text: widget.book.editorialValue ?? '',
    );
    _genreController = TextEditingController(text: widget.book.genre ?? '');

    // Initialize chip values from comma-separated strings
    if (widget.book.author != null && widget.book.author!.isNotEmpty) {
      _selectedAuthors =
          widget.book.author!
              .split(',')
              .map((a) => a.trim())
              .where((a) => a.isNotEmpty)
              .toList();
    }
    if (widget.book.genre != null && widget.book.genre!.isNotEmpty) {
      _selectedGenres =
          widget.book.genre!
              .split(',')
              .map((g) => g.trim())
              .where((g) => g.isNotEmpty)
              .toList();
    }
    _sagaController = TextEditingController(text: widget.book.saga);
    _nSagaController = TextEditingController(text: widget.book.nSaga);
    _sagaUniverseController = TextEditingController(
      text: widget.book.sagaUniverse,
    );
    _pagesController = TextEditingController(
      text: widget.book.pages?.toString() ?? '',
    );
    _publicationYearController = TextEditingController(
      text: widget.book.originalPublicationYear?.toString() ?? '',
    );

    // Parse release date if it's in YYYYMMDD format (> 9999)
    if (widget.book.originalPublicationYear != null &&
        widget.book.originalPublicationYear! > 9999) {
      final dateInt = widget.book.originalPublicationYear!;
      final year = dateInt ~/ 10000;
      final month = (dateInt % 10000) ~/ 100;
      final day = dateInt % 100;
      try {
        _releaseDate = DateTime(year, month, day);
        _publicationYearController.text = year.toString();
      } catch (e) {
        // Invalid date, just use the value as year
      }
    }
    _editorialController = TextEditingController(
      text: widget.book.editorialValue,
    );
    _genreController = TextEditingController(text: widget.book.genre);
    _myReviewController = TextEditingController(text: widget.book.myReview);
    _myRating = widget.book.myRating ?? 0.0;
    _readCount = widget.book.readCount ?? 0;
    _selectedLoaned = widget.book.loaned?.toLowerCase() ?? 'no';

    // Initialize bundle fields
    _isBundle = widget.book.isBundle ?? false;
    _bundleCount = widget.book.bundleCount;
    _bundleNumbers = widget.book.bundleNumbers;

    // Initialize TBR and Tandem fields
    _tbr = widget.book.tbr ?? false;
    _isTandem = widget.book.isTandem ?? false;
    _selectedStatusValue = widget.book.statusValue;
    _selectedOriginalBookId = widget.book.originalBookId;

    // Parse bundle dates from JSON
    if (widget.book.bundlePages != null) {
      try {
        final List<dynamic> pages = jsonDecode(widget.book.bundlePages!);
        _bundlePages = pages.map((p) => p as int?).toList();
      } catch (e) {
        _bundlePages = null;
      }
    }
    if (widget.book.bundlePublicationYears != null) {
      try {
        final List<dynamic> years = jsonDecode(widget.book.bundlePublicationYears!);
        _bundlePublicationYears = years.map((y) => y as int?).toList();
      } catch (e) {
        _bundlePublicationYears = null;
      }
    }

    if (widget.book.bundleTitles != null) {
      try {
        final List<dynamic> titles = jsonDecode(widget.book.bundleTitles!);
        _bundleTitles = titles.map((t) => t as String?).toList();
      } catch (e) {
        _bundleTitles = null;
      }
    }
    
    // Old date fields removed - now using book_read_dates table
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

        // Set selected dropdown values based on book data
        // Validate that the selected ID exists in the deduplicated list
        final tempStatusId = _findIdByValue(
          _statusList,
          'status_id',
          'value',
          widget.book.statusValue,
        );
        final statusExists = _statusList.any(
          (s) => s['status_id'] == tempStatusId,
        );
        _selectedStatusId =
            statusExists
                ? tempStatusId
                : (_statusList.isNotEmpty
                    ? _statusList.first['status_id'] as int?
                    : null);

        final tempFormatSagaId = _findIdByValue(
          _formatSagaList,
          'format_id',
          'value',
          widget.book.formatSagaValue,
        );
        _selectedFormatSagaId =
            _formatSagaList.any((f) => f['format_id'] == tempFormatSagaId)
                ? tempFormatSagaId
                : null;

        final tempLanguageId = _findIdByValue(
          _languageList,
          'language_id',
          'name',
          widget.book.languageValue,
        );
        _selectedLanguageId =
            _languageList.any((l) => l['language_id'] == tempLanguageId)
                ? tempLanguageId
                : null;

        final tempPlaceId = _findIdByValue(
          _placeList,
          'place_id',
          'name',
          widget.book.placeValue,
        );
        _selectedPlaceId =
            _placeList.any((p) => p['place_id'] == tempPlaceId)
                ? tempPlaceId
                : null;

        final tempFormatId = _findIdByValue(
          _formatList,
          'format_id',
          'value',
          widget.book.formatValue,
        );
        _selectedFormatId =
            _formatList.any((f) => f['format_id'] == tempFormatId)
                ? tempFormatId
                : null;

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

  int? _findIdByValue(
    List<Map<String, dynamic>> list,
    String idColumn,
    String valueColumn,
    String? value,
  ) {
    if (value == null || value.isEmpty) return null;
    try {
      final item = list.firstWhere((item) => item[valueColumn] == value);
      return item[idColumn] as int?;
    } catch (e) {
      return null;
    }
  }

  Future<void> _updateBook() async {
    if (!_formKey.currentState!.validate()) {
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

      final updatedBook = Book(
        bookId: widget.book.bookId,
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
        loaned: (_selectedLoaned ?? 'no').toLowerCase(),
        statusValue: statusValue,
        editorialValue:
            _editorialController.text.trim().isEmpty
                ? null
                : _editorialController.text.trim(),
        languageValue: languageValue,
        placeValue: placeValue,
        formatValue: formatValue,
        formatSagaValue: formatSagaValue,
        createdAt: widget.book.createdAt,
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
        bundleNumbers: _bundleNumbers,
        bundleStartDates: null,
        bundleEndDates: null,
        bundlePages: _bundlePages != null ? jsonEncode(_bundlePages!) : null,
        bundlePublicationYears: _bundlePublicationYears != null ? jsonEncode(_bundlePublicationYears!) : null,
        bundleTitles: _bundleTitles != null ? jsonEncode(_bundleTitles!) : null,
        tbr: _tbr,
        isTandem: _isTandem,
        originalBookId: _selectedOriginalBookId,
      );

      // Update the book (delete and re-add with same ID)
      await repository.deleteBook(widget.book.bookId!);
      // Preserve the original book ID by creating a new book with the same ID
      final bookToAdd = Book(
        bookId: widget.book.bookId,
        name: updatedBook.name,
        isbn: updatedBook.isbn,
        asin: updatedBook.asin,
        author: updatedBook.author,
        saga: updatedBook.saga,
        nSaga: updatedBook.nSaga,
        sagaUniverse: updatedBook.sagaUniverse,
        pages: updatedBook.pages,
        originalPublicationYear: updatedBook.originalPublicationYear,
        statusValue: updatedBook.statusValue,
        formatSagaValue: updatedBook.formatSagaValue,
        languageValue: updatedBook.languageValue,
        placeValue: updatedBook.placeValue,
        formatValue: updatedBook.formatValue,
        editorialValue: updatedBook.editorialValue,
        genre: updatedBook.genre,
        loaned: updatedBook.loaned,
        createdAt: updatedBook.createdAt,
        myRating: updatedBook.myRating,
        readCount: updatedBook.readCount,
        dateReadInitial: updatedBook.dateReadInitial,
        dateReadFinal: updatedBook.dateReadFinal,
        myReview: updatedBook.myReview,
        isBundle: updatedBook.isBundle,
        bundleCount: updatedBook.bundleCount,
        bundleNumbers: updatedBook.bundleNumbers,
        bundleStartDates: null,
        bundleEndDates: null,
        bundlePages: updatedBook.bundlePages,
        bundlePublicationYears: updatedBook.bundlePublicationYears,
        bundleTitles: updatedBook.bundleTitles,
        tbr: _tbr,
        isTandem: _isTandem,
        originalBookId: _selectedOriginalBookId,
      );
      await repository.addBook(bookToAdd);

      // Update read dates in the new table
      // First, delete all existing read dates for this book
      await repository.deleteAllReadDatesForBook(widget.book.bookId!);
      
      // Then add the updated read dates
      if (_isBundle) {
        // Save bundle read dates
        for (var entry in _bundleReadDates.entries) {
          for (var readDate in entry.value) {
            await repository.addReadDate(ReadDate(
              bookId: widget.book.bookId!,
              dateStarted: readDate.dateStarted,
              dateFinished: readDate.dateFinished,
              bundleBookIndex: entry.key,
            ));
          }
        }
      } else {
        // Save regular read dates
        for (final readDate in _readDates) {
          await repository.addReadDate(ReadDate(
            bookId: widget.book.bookId!,
            dateStarted: readDate.dateStarted,
            dateFinished: readDate.dateFinished,
          ));
        }
      }

      // Reload books in provider
      if (mounted) {
        final provider = Provider.of<BookProvider?>(context, listen: false);
        await provider?.loadBooks();

        // Return the book with preserved ID to the detail screen
        Navigator.pop(context, bookToAdd);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating book: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _isbnController.dispose();
    _asinController.dispose();
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: true, // Allow normal back navigation to details
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Book'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_outlined),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),

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
                        initialValue: _selectedOriginalBookId != null && selectedBook != null
                            ? TextEditingValue(
                                text: '${selectedBook.name}${selectedBook.author != null ? " - ${selectedBook.author}" : ""}',
                              )
                            : const TextEditingValue(),
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return books;
                          }
                          return books.where((book) {
                            final searchText = textEditingValue.text.toLowerCase();
                            final bookText = '${book.name} ${book.author ?? ""}'.toLowerCase();
                            return bookText.contains(searchText);
                          });
                        },
                        displayStringForOption: (Book book) =>
                            '${book.name}${book.author != null ? " - ${book.author}" : ""}',
                        onSelected: (Book book) {
                          setState(() {
                            _selectedOriginalBookId = book.bookId;
                          });
                        },
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
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
                              if (_selectedStatusValue == 'Repeated' && _selectedOriginalBookId == null) {
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
                  decoration: const InputDecoration(
                    labelText: 'ISBN',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.numbers),
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
                  labelText: 'Editorial',
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
                  labelText: 'Saga',
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
                  labelText: 'Saga Universe',
                  prefixIcon: Icons.public,
                  suggestions: _sagaUniverseSuggestions,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),

                // Pages field
                TextFormField(
                  controller: _pagesController,
                  decoration: const InputDecoration(
                    labelText: 'Pages',
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
                    ],
                  ),

                // Format Saga dropdown
                DropdownButtonFormField<int>(
                  value: _selectedFormatSagaId,
                  decoration: const InputDecoration(
                    labelText: 'Format Saga',
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
                  items: const [
                    DropdownMenuItem(value: 'yes', child: Text('Yes')),
                    DropdownMenuItem(value: 'no', child: Text('No')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedLoaned = value;
                    });
                  },
                ),
                const SizedBox(height: 32),

                // Bundle section
                BundleInputWidget(
                  initialIsBundle: _isBundle,
                  initialBundleCount: _bundleCount,
                  initialBundleNumbers: _bundleNumbers,
                  initialBundlePages: _bundlePages,
                  initialBundlePublicationYears: _bundlePublicationYears,
                  initialBundleTitles: _bundleTitles,
                  bundleBooksReadStatus: _bundleReadDates.map((index, dates) {
                    // Check if there are actual reading sessions
                    final hasReadingSessions = dates.any((d) => d.dateFinished != null && d.dateFinished!.isNotEmpty);
                    // If no reading sessions, use manual status
                    return MapEntry(index, hasReadingSessions || (_manualBundleReadStatus[index] ?? false));
                  }),
                  onReadStatusChanged: (index, isRead) {
                    setState(() {
                      _manualBundleReadStatus[index] = isRead;
                    });
                  },
                  onChanged: (
                    isBundle,
                    count,
                    numbers,
                    bundlePages,
                    bundlePublicationYears,
                    bundleTitles,
                  ) {
                    setState(() {
                      _isBundle = isBundle;
                      _bundleCount = count;
                      _bundleNumbers = numbers;
                      _bundlePages = bundlePages;
                      _bundlePublicationYears = bundlePublicationYears;
                      _bundleTitles = bundleTitles;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Bundle Read Dates (shown only for bundles)
                if (_isBundle && _bundleCount != null && _bundleCount! > 0)
                  BundleReadDatesWidget(
                    bookId: widget.book.bookId!,
                    bundleCount: _bundleCount!,
                    initialBundleReadDates: _bundleReadDates,
                    onChanged: (bundleReadDates) {
                      setState(() {
                        _bundleReadDates = bundleReadDates;
                      });
                    },
                  ),
                if (_isBundle && _bundleCount != null && _bundleCount! > 0)
                  const SizedBox(height: 16),
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
                            if (value == true && !_tbr) {
                              // Check TBR limit only when checking (not unchecking)
                              final db = await DatabaseHelper.instance.database;
                              final repository = BookRepository(db);
                              final currentCount =
                                  await repository.getTBRCount();
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
                        if (_sagaController.text.isNotEmpty ||
                            _sagaUniverseController.text.isNotEmpty)
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
                    bookId: widget.book.bookId!,
                    initialReadDates: _readDates,
                    onChanged: (readDates) {
                      setState(() {
                        _readDates = readDates;
                        // Update read count based on finished sessions
                        _readCount = readDates.where((rd) => rd.dateFinished != null && rd.dateFinished!.isNotEmpty).length;
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

                // Update button
                ElevatedButton(
                  onPressed: _updateBook,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Update Book',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 50), // Bottom margin
              ],
            ),
          ),
        ),
      ),
    );
  }
}

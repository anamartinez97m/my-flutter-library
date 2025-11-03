import 'package:flutter/material.dart';
import 'package:myrandomlibrary/widgets/autocomplete_text_field.dart';
import 'package:myrandomlibrary/widgets/chip_autocomplete_field.dart';
import 'package:flutter/services.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/widgets/heart_rating_input.dart';
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
  late TextEditingController _authorController;
  late TextEditingController _sagaController;
  late TextEditingController _nSagaController;
  late TextEditingController _pagesController;
  late TextEditingController _publicationYearController;
  DateTime? _releaseDate;
  late TextEditingController _editorialController;
  late TextEditingController _genreController;
  late TextEditingController _myReviewController;
  late double _myRating;
  late int _readCount;
  DateTime? _dateReadInitial;
  DateTime? _dateReadFinal;

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
    final isTBReleased = _statusList.isNotEmpty && 
        _selectedStatusId != null &&
        _statusList.any((s) => 
          s['status_id'] == _selectedStatusId && 
          (s['value'] as String).toLowerCase() == 'tbreleased');
    
    if (isTBReleased && _releaseDate != null) {
      // Store as YYYYMMDD
      return _releaseDate!.year * 10000 + _releaseDate!.month * 100 + _releaseDate!.day;
    }
    
    // Just return the year
    return year;
  }

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadDropdownData();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.book.name ?? '');
    _isbnController = TextEditingController(text: widget.book.isbn ?? '');
    _authorController = TextEditingController(text: widget.book.author ?? '');
    _editorialController = TextEditingController(text: widget.book.editorialValue ?? '');
    _genreController = TextEditingController(text: widget.book.genre ?? '');
    
    // Initialize chip values from comma-separated strings
    if (widget.book.author != null && widget.book.author!.isNotEmpty) {
      _selectedAuthors = widget.book.author!.split(',').map((a) => a.trim()).where((a) => a.isNotEmpty).toList();
    }
    if (widget.book.genre != null && widget.book.genre!.isNotEmpty) {
      _selectedGenres = widget.book.genre!.split(',').map((g) => g.trim()).where((g) => g.isNotEmpty).toList();
    }
    _sagaController = TextEditingController(text: widget.book.saga);
    _nSagaController = TextEditingController(text: widget.book.nSaga);
    _pagesController = TextEditingController(
      text: widget.book.pages?.toString() ?? '',
    );
    _publicationYearController = TextEditingController(
      text: widget.book.originalPublicationYear?.toString() ?? '',
    );
    
    // Parse release date if it's in YYYYMMDD format (> 9999)
    if (widget.book.originalPublicationYear != null && widget.book.originalPublicationYear! > 9999) {
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
    _selectedLoaned = widget.book.loaned;

    // Parse dates
    if (widget.book.dateReadInitial != null) {
      try {
        _dateReadInitial = DateTime.parse(widget.book.dateReadInitial!);
      } catch (e) {
        _dateReadInitial = null;
      }
    }
    if (widget.book.dateReadFinal != null) {
      try {
        _dateReadFinal = DateTime.parse(widget.book.dateReadFinal!);
      } catch (e) {
        _dateReadFinal = null;
      }
    }
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

      setState(() {
        _statusList = status;
        _formatSagaList = formatSaga;
        _languageList = language;
        _placeList = place;
        _formatList = format;
        _authorSuggestions = authors.map((a) => a['name'] as String).toList();
        _genreSuggestions = genres.map((g) => g['name'] as String).toList();
        _editorialSuggestions = editorials.map((e) => e['name'] as String).toList();

        // Set selected dropdown values based on book data
        _selectedStatusId = _findIdByValue(
          _statusList,
          'status_id',
          'value',
          widget.book.statusValue,
        );
        _selectedFormatSagaId = _findIdByValue(
          _formatSagaList,
          'format_id',
          'value',
          widget.book.formatSagaValue,
        );
        _selectedLanguageId = _findIdByValue(
          _languageList,
          'language_id',
          'name',
          widget.book.languageValue,
        );
        _selectedPlaceId = _findIdByValue(
          _placeList,
          'place_id',
          'name',
          widget.book.placeValue,
        );
        _selectedFormatId = _findIdByValue(
          _formatList,
          'format_id',
          'value',
          widget.book.formatValue,
        );

        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading dropdown data: $e');
      setState(() {
        _isLoading = false;
      });
    }
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
        author:
            _selectedAuthors.isEmpty
                ? null
                : _selectedAuthors.join(', '),
        saga:
            _sagaController.text.trim().isEmpty
                ? null
                : _capitalizeFirstWord(_sagaController.text.trim()),
        nSaga:
            _nSagaController.text.trim().isEmpty
                ? null
                : _nSagaController.text.trim(),
        pages:
            _pagesController.text.trim().isEmpty
                ? null
                : int.tryParse(_pagesController.text.trim()),
        originalPublicationYear: _getPublicationYearOrDate(),
        loaned: _selectedLoaned ?? 'no',
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
        genre:
            _selectedGenres.isEmpty
                ? null
                : _selectedGenres.join(', '),
        dateReadInitial: _dateReadInitial?.toIso8601String(),
        dateReadFinal: _dateReadFinal?.toIso8601String(),
        readCount: _readCount,
        myRating: _myRating > 0 ? _myRating : null,
        myReview:
            _myReviewController.text.trim().isEmpty
                ? null
                : _myReviewController.text.trim(),
      );

      // Update the book (delete and re-add with same ID)
      await repository.deleteBook(widget.book.bookId!);
      // Preserve the original book ID by creating a new book with the same ID
      final bookToAdd = Book(
        bookId: widget.book.bookId,
        name: updatedBook.name,
        isbn: updatedBook.isbn,
        author: updatedBook.author,
        saga: updatedBook.saga,
        nSaga: updatedBook.nSaga,
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
      );
      await repository.addBook(bookToAdd);

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
        ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              TextFormField(
                controller: _sagaController,
                decoration: const InputDecoration(
                  labelText: 'Saga',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.collections_bookmark),
                ),
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
                  _statusList.any((s) => 
                    s['status_id'] == _selectedStatusId && 
                    (s['value'] as String).toLowerCase() == 'tbreleased'))
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
                            _publicationYearController.text = pickedDate.year.toString();
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

              // Status dropdown (required)
              DropdownButtonFormField<int>(
                value: _selectedStatusId,
                decoration: const InputDecoration(
                  labelText: 'Status *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.check_circle),
                ),
                items:
                    _statusList.map((status) {
                      return DropdownMenuItem<int>(
                        value: status['status_id'] as int,
                        child: Text(status['value'] as String),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStatusId = value;
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
                  DropdownMenuItem(value: 'Yes', child: Text('Yes')),
                  DropdownMenuItem(value: 'No', child: Text('No')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedLoaned = value;
                  });
                },
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
                        onPressed: _readCount > 0
                            ? () {
                                setState(() {
                                  _readCount--;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.remove),
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          foregroundColor: Theme.of(context).colorScheme.primary,
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
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
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
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Date Started Reading
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dateReadInitial ?? DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _dateReadInitial = date;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date Started Reading',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.event),
                  ),
                  child: Text(
                    _dateReadInitial != null
                        ? '${_dateReadInitial!.year}-${_dateReadInitial!.month.toString().padLeft(2, '0')}-${_dateReadInitial!.day.toString().padLeft(2, '0')}'
                        : 'Select date',
                    style: TextStyle(
                      color: _dateReadInitial != null ? null : Colors.grey[600],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Date Finished Reading
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dateReadFinal ?? DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _dateReadFinal = date;
                      // Auto-increment read count when finishing a book
                      _readCount++;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date Finished Reading',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.event_available),
                  ),
                  child: Text(
                    _dateReadFinal != null
                        ? '${_dateReadFinal!.year}-${_dateReadFinal!.month.toString().padLeft(2, '0')}-${_dateReadFinal!.day.toString().padLeft(2, '0')}'
                        : 'Select date',
                    style: TextStyle(
                      color: _dateReadFinal != null ? null : Colors.grey[600],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

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

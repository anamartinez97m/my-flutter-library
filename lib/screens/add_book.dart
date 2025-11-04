import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/screens/navigation.dart';
import 'package:myrandomlibrary/widgets/autocomplete_text_field.dart';
import 'package:myrandomlibrary/widgets/chip_autocomplete_field.dart';
import 'package:myrandomlibrary/widgets/bundle_input_widget.dart';
import 'package:provider/provider.dart';
import 'package:myrandomlibrary/widgets/heart_rating_input.dart';
import 'dart:convert';

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
  final _authorController = TextEditingController();
  final _sagaController = TextEditingController();
  final _nSagaController = TextEditingController();
  final _pagesController = TextEditingController();
  final _publicationYearController = TextEditingController();
  DateTime? _releaseDate;
  final _editorialController = TextEditingController();
  final _genreController = TextEditingController();
  final _myReviewController = TextEditingController();
  double _myRating = 0.0;
  int _readCount = 0;
  DateTime? _dateReadInitial;
  DateTime? _dateReadFinal;
  
  // Bundle fields
  bool _isBundle = false;
  int? _bundleCount;
  String? _bundleNumbers;
  List<DateTime?>? _bundleStartDates;
  List<DateTime?>? _bundleEndDates;

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

      setState(() {
        _statusList = status;
        _formatSagaList = formatSaga;
        _languageList = language;
        _placeList = place;
        _formatList = format;
        _authorSuggestions = authors.map((a) => a['name'] as String).toList();
        _genreSuggestions = genres.map((g) => g['name'] as String).toList();
        _editorialSuggestions = editorials.map((e) => e['name'] as String).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading dropdown data: $e');
      setState(() {
        _isLoading = false;
      });
    }
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
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  // Stay on add book screen to add another
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Another'),
                style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  // Switch to home tab (index 0)
                  NavigationScreen.of(context)?.switchToTab(0);
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
        loaned: _selectedLoaned ?? 'no', // Default to "no" if not selected
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
        isBundle: _isBundle,
        bundleCount: _bundleCount,
        bundleNumbers: _bundleNumbers,
        bundleStartDates: _bundleStartDates != null ? jsonEncode(_bundleStartDates!.map((d) => d?.toIso8601String()).toList()) : null,
        bundleEndDates: _bundleEndDates != null ? jsonEncode(_bundleEndDates!.map((d) => d?.toIso8601String()).toList()) : null,
      );

      await repository.addBook(book);

      // Reload books in provider
      if (mounted) {
        final provider = Provider.of<BookProvider?>(context, listen: false);
        await provider?.loadBooks();

        // Clear form first
        _formKey.currentState!.reset();
        _nameController.clear();
        _isbnController.clear();
        _authorController.clear();
        _sagaController.clear();
        _nSagaController.clear();
        _pagesController.clear();
        _publicationYearController.clear();
        _releaseDate = null;
        _editorialController.clear();
        _genreController.clear();
        _myReviewController.clear();

        setState(() {
          _myRating = 0.0;
          _readCount = 0;
          _dateReadInitial = null;
          _dateReadFinal = null;
          _selectedStatusId = null;
          _selectedFormatSagaId = null;
          _selectedLanguageId = null;
          _selectedPlaceId = null;
          _selectedFormatId = null;
          _selectedLoaned = null;
          _dateReadInitial = null;
          _dateReadFinal = null;
          _isBundle = false;
          _bundleCount = null;
          _bundleNumbers = null;
          _bundleStartDates = null;
          _bundleEndDates = null;
        });

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
          onPressed: () => NavigationScreen.of(context)?.switchToTab(0),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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

              // Bundle section
              BundleInputWidget(
                initialIsBundle: _isBundle,
                initialBundleCount: _bundleCount,
                initialBundleNumbers: _bundleNumbers,
                initialStartDates: _bundleStartDates,
                initialEndDates: _bundleEndDates,
                onChanged: (isBundle, count, numbers, startDates, endDates) {
                  setState(() {
                    _isBundle = isBundle;
                    _bundleCount = count;
                    _bundleNumbers = numbers;
                    _bundleStartDates = startDates;
                    _bundleEndDates = endDates;
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
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mylibrary/db/database_helper.dart';
import 'package:mylibrary/model/book.dart';
import 'package:mylibrary/providers/book_provider.dart';
import 'package:mylibrary/repositories/book_repository.dart';
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
  late TextEditingController _editorialController;
  late TextEditingController _genreController;

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

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadDropdownData();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.book.name);
    _isbnController = TextEditingController(text: widget.book.isbn);
    _authorController = TextEditingController(text: widget.book.author);
    _sagaController = TextEditingController(text: widget.book.saga);
    _nSagaController = TextEditingController(text: widget.book.nSaga);
    _pagesController = TextEditingController(
      text: widget.book.pages?.toString() ?? '',
    );
    _publicationYearController = TextEditingController(
      text: widget.book.originalPublicationYear?.toString() ?? '',
    );
    _editorialController =
        TextEditingController(text: widget.book.editorialValue);
    _genreController = TextEditingController(text: widget.book.genre);
    _selectedLoaned = widget.book.loaned;
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

      setState(() {
        _statusList = status;
        _formatSagaList = formatSaga;
        _languageList = language;
        _placeList = place;
        _formatList = format;

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
      String? statusValue = _selectedStatusId != null
          ? _statusList
              .firstWhere((s) => s['status_id'] == _selectedStatusId)['value']
              as String?
          : null;
      String? formatSagaValue = _selectedFormatSagaId != null
          ? _formatSagaList.firstWhere(
              (f) => f['format_id'] == _selectedFormatSagaId)['value'] as String?
          : null;
      String? languageValue = _selectedLanguageId != null
          ? _languageList.firstWhere(
              (l) => l['language_id'] == _selectedLanguageId)['name'] as String?
          : null;
      String? placeValue = _selectedPlaceId != null
          ? _placeList
              .firstWhere((p) => p['place_id'] == _selectedPlaceId)['name']
              as String?
          : null;
      String? formatValue = _selectedFormatId != null
          ? _formatList
              .firstWhere((f) => f['format_id'] == _selectedFormatId)['value']
              as String?
          : null;

      final updatedBook = Book(
        bookId: widget.book.bookId,
        name: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        isbn: _isbnController.text.trim().isEmpty
            ? null
            : _isbnController.text.trim(),
        author: _authorController.text.trim().isEmpty
            ? null
            : _authorController.text.trim(),
        saga: _sagaController.text.trim().isEmpty
            ? null
            : _sagaController.text.trim(),
        nSaga: _nSagaController.text.trim().isEmpty
            ? null
            : _nSagaController.text.trim(),
        pages: _pagesController.text.trim().isEmpty
            ? null
            : int.tryParse(_pagesController.text.trim()),
        originalPublicationYear: _publicationYearController.text.trim().isEmpty
            ? null
            : int.tryParse(_publicationYearController.text.trim()),
        loaned: _selectedLoaned ?? 'no',
        statusValue: statusValue,
        editorialValue: _editorialController.text.trim().isEmpty
            ? null
            : _editorialController.text.trim(),
        languageValue: languageValue,
        placeValue: placeValue,
        formatValue: formatValue,
        formatSagaValue: formatSagaValue,
        createdAt: widget.book.createdAt,
        genre: _genreController.text.trim().isEmpty
            ? null
            : _genreController.text.trim(),
      );

      // Delete and re-add (simpler than updating with all relationships)
      await repository.deleteBook(widget.book.bookId!);
      await repository.addBook(updatedBook);

      // Reload books in provider
      if (mounted) {
        final provider = Provider.of<BookProvider?>(context, listen: false);
        await provider?.loadBooks();

        Navigator.pop(context); // Go back to detail screen
        Navigator.pop(context); // Go back to list

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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Book'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
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
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(
                  labelText: 'Author(s)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 4),
                child: Text(
                  'For multiple authors, separate with commas: author1, author2',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
              const SizedBox(height: 16),

              // Editorial field
              TextFormField(
                controller: _editorialController,
                decoration: const InputDecoration(
                  labelText: 'Editorial',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
              ),
              const SizedBox(height: 16),

              // Genre field
              TextFormField(
                controller: _genreController,
                decoration: const InputDecoration(
                  labelText: 'Genre(s)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 4),
                child: Text(
                  'For multiple genres, separate with commas: genre1, genre2',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                ),
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

              // Status dropdown (required)
              DropdownButtonFormField<int>(
                value: _selectedStatusId,
                decoration: const InputDecoration(
                  labelText: 'Status *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.check_circle),
                ),
                items: _statusList.map((status) {
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
                items: _formatSagaList.map((format) {
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
                items: _languageList.map((lang) {
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
                items: _placeList.map((place) {
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
                items: _formatList.map((format) {
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

              // Update button
              ElevatedButton(
                onPressed: _updateBook,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
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
              const SizedBox(height: 24), // Bottom margin
            ],
          ),
        ),
      ),
    );
  }
}

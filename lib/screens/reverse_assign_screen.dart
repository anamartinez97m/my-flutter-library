import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:provider/provider.dart';

class ReverseAssignScreen extends StatefulWidget {
  const ReverseAssignScreen({super.key});

  @override
  State<ReverseAssignScreen> createState() => _ReverseAssignScreenState();
}

class _ReverseAssignScreenState extends State<ReverseAssignScreen> {
  int _currentStep = 0;
  String? _selectedField;
  String? _selectedValue;
  List<Map<String, dynamic>> _fieldValues = [];
  List<Book> _candidateBooks = [];
  final Set<int> _selectedBookIds = {};
  bool _isLoading = false;
  bool _isApplying = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _availableFields = [
    {'key': 'genre', 'icon': 'category'},
    {'key': 'format', 'icon': 'book'},
    {'key': 'language', 'icon': 'language'},
    {'key': 'place', 'icon': 'place'},
    {'key': 'editorial', 'icon': 'business'},
    {'key': 'format_saga', 'icon': 'collections_bookmark'},
  ];

  String _getFieldLabel(String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'genre':
        return l10n.genre;
      case 'format':
        return l10n.format;
      case 'language':
        return l10n.language;
      case 'place':
        return l10n.place;
      case 'editorial':
        return l10n.editorial;
      case 'format_saga':
        return l10n.format_saga;
      default:
        return key;
    }
  }

  IconData _getFieldIcon(String key) {
    switch (key) {
      case 'genre':
        return Icons.category;
      case 'format':
        return Icons.book;
      case 'language':
        return Icons.language;
      case 'place':
        return Icons.place;
      case 'editorial':
        return Icons.business;
      case 'format_saga':
        return Icons.collections_bookmark;
      default:
        return Icons.label;
    }
  }

  String _getValueName(Map<String, dynamic> item) {
    if (_selectedField == 'status' ||
        _selectedField == 'format' ||
        _selectedField == 'format_saga') {
      return item['value'] as String;
    }
    return item['name'] as String;
  }

  String _getCurrentFieldValue(Book book) {
    switch (_selectedField) {
      case 'genre':
        return book.genre ?? '';
      case 'format':
        return book.formatValue ?? '';
      case 'language':
        return book.languageValue ?? '';
      case 'place':
        return book.placeValue ?? '';
      case 'editorial':
        return book.editorialValue ?? '';
      case 'format_saga':
        return book.formatSagaValue ?? '';
      default:
        return '';
    }
  }

  Future<void> _loadFieldValues() async {
    if (_selectedField == null) return;

    setState(() => _isLoading = true);

    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);
      final values = await repository.getLookupValues(_selectedField!);

      setState(() {
        _fieldValues = values;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading field values: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCandidateBooks() async {
    if (_selectedField == null || _selectedValue == null) return;

    setState(() => _isLoading = true);

    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);
      final books = await repository.getBooksWithoutFieldValue(
        _selectedField!,
        _selectedValue!,
      );

      setState(() {
        _candidateBooks = books;
        _selectedBookIds.clear();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading candidate books: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _applyToSelected() async {
    if (_selectedBookIds.isEmpty ||
        _selectedField == null ||
        _selectedValue == null) {
      return;
    }

    setState(() => _isApplying = true);

    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);
      final count = await repository.updateBooksField(
        _selectedBookIds.toList(),
        _selectedField!,
        _selectedValue!,
      );

      if (mounted) {
        final provider = Provider.of<BookProvider?>(context, listen: false);
        await provider?.loadBooks();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.bulk_updated_books(count),
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Reload candidate books to reflect changes
        await _loadCandidateBooks();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  List<Book> get _filteredBooks {
    if (_searchQuery.isEmpty) return _candidateBooks;
    final query = _searchQuery.toLowerCase();
    return _candidateBooks.where((book) {
      return (book.name?.toLowerCase().contains(query) ?? false) ||
          (book.author?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.assign_books_to_value),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _onStepContinue,
        onStepCancel: _onStepCancel,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                if (_currentStep < 2)
                  ElevatedButton(
                    onPressed:
                        _canContinue() ? details.onStepContinue : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(l10n.continue_label),
                  ),
                if (_currentStep == 2)
                  ElevatedButton.icon(
                    onPressed:
                        (_selectedBookIds.isNotEmpty && !_isApplying)
                            ? _applyToSelected
                            : null,
                    icon:
                        _isApplying
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(Icons.check),
                    label: Text(
                      l10n.apply_to_n_books(_selectedBookIds.length),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                const SizedBox(width: 8),
                if (_currentStep > 0)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: Text(l10n.back),
                  ),
              ],
            ),
          );
        },
        steps: [
          // Step 1: Pick field
          Step(
            title: Text(l10n.select_field),
            subtitle:
                _selectedField != null
                    ? Text(_getFieldLabel(_selectedField!))
                    : null,
            isActive: _currentStep >= 0,
            state:
                _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: _buildFieldSelector(),
          ),
          // Step 2: Pick value
          Step(
            title: Text(l10n.select_value),
            subtitle:
                _selectedValue != null ? Text(_selectedValue!) : null,
            isActive: _currentStep >= 1,
            state:
                _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: _buildValueSelector(),
          ),
          // Step 3: Select books
          Step(
            title: Text(l10n.select_books),
            subtitle:
                _selectedBookIds.isNotEmpty
                    ? Text(
                      l10n.books_selected(_selectedBookIds.length),
                    )
                    : null,
            isActive: _currentStep >= 2,
            state: StepState.indexed,
            content: _buildBookSelector(),
          ),
        ],
      ),
    );
  }

  bool _canContinue() {
    switch (_currentStep) {
      case 0:
        return _selectedField != null;
      case 1:
        return _selectedValue != null;
      default:
        return false;
    }
  }

  void _onStepContinue() {
    if (_currentStep == 0 && _selectedField != null) {
      _loadFieldValues();
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1 && _selectedValue != null) {
      _loadCandidateBooks();
      setState(() => _currentStep = 2);
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        if (_currentStep == 0) {
          _selectedValue = null;
          _fieldValues = [];
        }
        if (_currentStep <= 1) {
          _candidateBooks = [];
          _selectedBookIds.clear();
          _searchQuery = '';
          _searchController.clear();
        }
      });
    }
  }

  Widget _buildFieldSelector() {
    return Column(
      children:
          _availableFields.map((field) {
            final key = field['key']!;
            final isSelected = _selectedField == key;

            return Card(
              elevation: isSelected ? 3 : 1,
              color:
                  isSelected
                      ? Colors.deepPurple.shade50
                      : null,
              child: ListTile(
                leading: Icon(
                  _getFieldIcon(key),
                  color: isSelected ? Colors.deepPurple : Colors.grey,
                ),
                title: Text(
                  _getFieldLabel(key),
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.deepPurple : null,
                  ),
                ),
                trailing:
                    isSelected
                        ? const Icon(
                          Icons.check_circle,
                          color: Colors.deepPurple,
                        )
                        : null,
                onTap: () {
                  setState(() {
                    _selectedField = key;
                    _selectedValue = null;
                    _fieldValues = [];
                    _candidateBooks = [];
                    _selectedBookIds.clear();
                  });
                },
              ),
            );
          }).toList(),
    );
  }

  Widget _buildValueSelector() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_fieldValues.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.no_values_available,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _fieldValues.length,
        itemBuilder: (context, index) {
          final item = _fieldValues[index];
          final valueName = _getValueName(item);
          final isSelected = _selectedValue == valueName;

          return Card(
            elevation: isSelected ? 3 : 1,
            color:
                isSelected ? Colors.deepPurple.shade50 : null,
            child: ListTile(
              title: Text(
                valueName,
                style: TextStyle(
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.deepPurple : null,
                ),
              ),
              trailing:
                  isSelected
                      ? const Icon(
                        Icons.check_circle,
                        color: Colors.deepPurple,
                      )
                      : null,
              onTap: () {
                setState(() {
                  _selectedValue = valueName;
                  _candidateBooks = [];
                  _selectedBookIds.clear();
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookSelector() {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final books = _filteredBooks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info bar
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.reverse_assign_info(
                    _selectedValue ?? '',
                    _getFieldLabel(_selectedField ?? ''),
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Search + Select All
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.search_books_by_title,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: const OutlineInputBorder(),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  if (_selectedBookIds.length == books.length) {
                    _selectedBookIds.clear();
                  } else {
                    _selectedBookIds.clear();
                    for (final book in books) {
                      if (book.bookId != null) {
                        _selectedBookIds.add(book.bookId!);
                      }
                    }
                  }
                });
              },
              icon: Icon(
                _selectedBookIds.length == books.length && books.isNotEmpty
                    ? Icons.deselect
                    : Icons.select_all,
                size: 18,
              ),
              label: Text(
                _selectedBookIds.length == books.length && books.isNotEmpty
                    ? l10n.deselect_all
                    : l10n.select_all,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Count
        Text(
          '${books.length} ${l10n.books_available}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),

        // Book list
        SizedBox(
          height: 400,
          child:
              books.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 48,
                          color: Colors.green[300],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.all_books_already_have_value,
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    itemCount: books.length,
                    itemBuilder: (context, index) {
                      final book = books[index];
                      final isSelected = _selectedBookIds.contains(
                        book.bookId,
                      );
                      final currentValue = _getCurrentFieldValue(book);

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (selected) {
                          setState(() {
                            if (selected == true && book.bookId != null) {
                              _selectedBookIds.add(book.bookId!);
                            } else {
                              _selectedBookIds.remove(book.bookId);
                            }
                          });
                        },
                        title: Text(
                          book.name ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (book.author != null && book.author!.isNotEmpty)
                              Text(
                                book.author!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            if (currentValue.isNotEmpty)
                              Text(
                                '${_getFieldLabel(_selectedField!)}: $currentValue',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange[700],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                        dense: true,
                        activeColor: Colors.deepPurple,
                      );
                    },
                  ),
        ),
      ],
    );
  }
}

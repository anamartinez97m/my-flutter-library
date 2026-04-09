import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:provider/provider.dart';

class FillEmptyWizardScreen extends StatefulWidget {
  const FillEmptyWizardScreen({super.key});

  @override
  State<FillEmptyWizardScreen> createState() => _FillEmptyWizardScreenState();
}

class _FillEmptyWizardScreenState extends State<FillEmptyWizardScreen> {
  String? _selectedField;
  bool _isLoading = false;
  bool _isApplying = false;

  // Groups of books: key = group name (author/saga), value = list of books
  List<_BookGroup> _groups = [];
  int _currentGroupIndex = 0;

  // Available values for the selected field
  List<Map<String, dynamic>> _fieldValues = [];

  // Per-group selected value
  String? _groupSelectedValue;

  // Per-group selected book IDs
  final Set<int> _groupSelectedBookIds = {};

  final List<Map<String, String>> _availableFields = [
    {'key': 'genre'},
    {'key': 'format'},
    {'key': 'language'},
    {'key': 'place'},
    {'key': 'editorial'},
    {'key': 'format_saga'},
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

  Future<void> _loadEmptyBooks() async {
    if (_selectedField == null) return;

    setState(() => _isLoading = true);

    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);

      // Load books with empty field
      final books = await repository.getBooksWithEmptyField(_selectedField!);

      // Load available values for the field
      final values = await repository.getLookupValues(_selectedField!);

      // Load ALL books to find peer suggestions
      final allBooks = await repository.getAllBooks();

      // Group books by author (primary grouping)
      final Map<String, List<Book>> authorGroups = {};
      for (final book in books) {
        final authors = book.author?.split(',').map((a) => a.trim()).toList() ?? [];
        if (authors.isEmpty || authors.first.isEmpty) {
          authorGroups.putIfAbsent('', () => []).add(book);
        } else {
          // Put book in the first author's group
          authorGroups.putIfAbsent(authors.first, () => []).add(book);
        }
      }

      // Build groups with suggestions
      final groups = <_BookGroup>[];
      for (final entry in authorGroups.entries) {
        final groupName = entry.key.isEmpty
            ? AppLocalizations.of(context)!.ungrouped
            : entry.key;

        // Find suggestions from peer books (same author, different books that HAVE the field)
        final suggestions = <String>{};
        if (entry.key.isNotEmpty) {
          for (final allBook in allBooks) {
            if (allBook.author?.contains(entry.key) == true) {
              final peerValue = _getBookFieldValue(allBook);
              if (peerValue.isNotEmpty) {
                // For genre, may have comma-separated values
                if (_selectedField == 'genre') {
                  suggestions.addAll(
                    peerValue.split(',').map((g) => g.trim()).where((g) => g.isNotEmpty),
                  );
                } else {
                  suggestions.add(peerValue);
                }
              }
            }
          }
        }

        groups.add(_BookGroup(
          name: groupName,
          books: entry.value,
          suggestions: suggestions.toList(),
        ));
      }

      // Sort: groups with suggestions first, then by size (desc)
      groups.sort((a, b) {
        if (a.suggestions.isNotEmpty && b.suggestions.isEmpty) return -1;
        if (a.suggestions.isEmpty && b.suggestions.isNotEmpty) return 1;
        return b.books.length.compareTo(a.books.length);
      });

      setState(() {
        _groups = groups;
        _fieldValues = values;
        _currentGroupIndex = 0;
        _groupSelectedValue = null;
        _groupSelectedBookIds.clear();
        _isLoading = false;
        // Pre-select all books in first group
        if (groups.isNotEmpty) {
          _preselectGroup(0);
        }
      });
    } catch (e) {
      debugPrint('Error loading empty books: $e');
      setState(() => _isLoading = false);
    }
  }

  String _getBookFieldValue(Book book) {
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

  void _preselectGroup(int index) {
    _groupSelectedBookIds.clear();
    _groupSelectedValue = null;
    if (index < _groups.length) {
      for (final book in _groups[index].books) {
        if (book.bookId != null) {
          _groupSelectedBookIds.add(book.bookId!);
        }
      }
      // Auto-select first suggestion if available
      if (_groups[index].suggestions.isNotEmpty) {
        _groupSelectedValue = _groups[index].suggestions.first;
      }
    }
  }

  Future<void> _applyToGroup() async {
    if (_groupSelectedBookIds.isEmpty ||
        _groupSelectedValue == null ||
        _selectedField == null) {
      return;
    }

    setState(() => _isApplying = true);

    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);
      final count = await repository.updateBooksField(
        _groupSelectedBookIds.toList(),
        _selectedField!,
        _groupSelectedValue!,
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

        // Remove applied books from current group
        final appliedIds = Set<int>.from(_groupSelectedBookIds);
        _groups[_currentGroupIndex].books.removeWhere(
          (b) => appliedIds.contains(b.bookId),
        );

        // If group is now empty, remove it and move to next
        if (_groups[_currentGroupIndex].books.isEmpty) {
          _groups.removeAt(_currentGroupIndex);
          if (_currentGroupIndex >= _groups.length && _groups.isNotEmpty) {
            _currentGroupIndex = _groups.length - 1;
          }
        }

        // Reset selection for new group
        if (_groups.isNotEmpty && _currentGroupIndex < _groups.length) {
          _preselectGroup(_currentGroupIndex);
        } else {
          _groupSelectedBookIds.clear();
          _groupSelectedValue = null;
        }
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.fill_empty_fields),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _selectedField == null ? _buildFieldPicker() : _buildWizard(),
    );
  }

  Widget _buildFieldPicker() {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.select_field_to_fill,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          ..._availableFields.map((field) {
            final key = field['key']!;
            return Card(
              child: ListTile(
                leading: Icon(_getFieldIcon(key), color: Colors.deepPurple),
                title: Text(_getFieldLabel(key)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  setState(() => _selectedField = key);
                  _loadEmptyBooks();
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWizard() {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green[300]),
            const SizedBox(height: 16),
            Text(
              l10n.no_books_with_empty_field,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedField = null;
                  _groups = [];
                });
              },
              icon: const Icon(Icons.arrow_back),
              label: Text(l10n.back),
            ),
          ],
        ),
      );
    }

    final group = _groups[_currentGroupIndex];
    final totalEmpty = _groups.fold<int>(0, (sum, g) => sum + g.books.length);

    return Column(
      children: [
        // Progress header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.deepPurple.shade50,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _selectedField = null;
                    _groups = [];
                  });
                },
                tooltip: l10n.back,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.group_n_of_total(
                        _currentGroupIndex + 1,
                        _groups.length,
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      l10n.books_without_field(
                        totalEmpty,
                        _getFieldLabel(_selectedField!),
                      ),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // Nav buttons
              IconButton(
                onPressed: _currentGroupIndex > 0
                    ? () {
                        setState(() {
                          _currentGroupIndex--;
                          _preselectGroup(_currentGroupIndex);
                        });
                      }
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                onPressed: _currentGroupIndex < _groups.length - 1
                    ? () {
                        setState(() {
                          _currentGroupIndex++;
                          _preselectGroup(_currentGroupIndex);
                        });
                      }
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),

        // Progress bar
        LinearProgressIndicator(
          value: _groups.isEmpty
              ? 0
              : (_currentGroupIndex + 1) / _groups.length,
          backgroundColor: Colors.grey[200],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group header
                Card(
                  color: Colors.deepPurple.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.person, color: Colors.deepPurple),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                l10n.books_in_group(group.books.length),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Suggestions from peers
                if (group.suggestions.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_outline,
                                color: Colors.amber.shade700, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.other_books_have(
                                  group.suggestions.join(', '),
                                ),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: group.suggestions.map((s) {
                            final isSelected = _groupSelectedValue == s;
                            return ActionChip(
                              label: Text(s),
                              backgroundColor: isSelected
                                  ? Colors.deepPurple.shade100
                                  : null,
                              side: isSelected
                                  ? BorderSide(color: Colors.deepPurple)
                                  : null,
                              onPressed: () {
                                setState(() => _groupSelectedValue = s);
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),

                // Value picker dropdown
                DropdownButtonFormField<String>(
                  value: _groupSelectedValue,
                  decoration: InputDecoration(
                    labelText: l10n.select_value_to_apply,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.label),
                  ),
                  items: _fieldValues.map((item) {
                    final name = _getValueName(item);
                    return DropdownMenuItem(value: name, child: Text(name));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _groupSelectedValue = value);
                  },
                ),
                const SizedBox(height: 12),

                // Book list with checkboxes
                ...group.books.map((book) {
                  final isSelected = _groupSelectedBookIds.contains(book.bookId);
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (selected) {
                      setState(() {
                        if (selected == true && book.bookId != null) {
                          _groupSelectedBookIds.add(book.bookId!);
                        } else {
                          _groupSelectedBookIds.remove(book.bookId);
                        }
                      });
                    },
                    title: Text(
                      book.name ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: book.author != null
                        ? Text(
                            book.author!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          )
                        : null,
                    dense: true,
                    activeColor: Colors.deepPurple,
                  );
                }),
                const SizedBox(height: 16),

                // Apply button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        (_groupSelectedBookIds.isNotEmpty &&
                                _groupSelectedValue != null &&
                                !_isApplying)
                            ? _applyToGroup
                            : null,
                    icon: _isApplying
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
                      l10n.apply_to_group,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BookGroup {
  final String name;
  final List<Book> books;
  final List<String> suggestions;

  _BookGroup({
    required this.name,
    required this.books,
    required this.suggestions,
  });
}

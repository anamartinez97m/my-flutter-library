import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:provider/provider.dart';

class ManageDropdownsScreen extends StatefulWidget {
  const ManageDropdownsScreen({super.key});

  @override
  State<ManageDropdownsScreen> createState() => _ManageDropdownsScreenState();
}

class _ManageDropdownsScreenState extends State<ManageDropdownsScreen> {
  String _selectedTable = 'status';
  List<Map<String, dynamic>> _values = [];
  bool _isLoading = false;

  final Map<String, String> _tableLabels = {
    'status': 'Status',
    'format_saga': 'Format Saga',
    'language': 'Language',
    'place': 'Place',
    'format': 'Format',
    'author': 'Authors',
    'genre': 'Genres',
    'editorial': 'Editorials',
    'saga': 'Saga',
    'saga_universe': 'Saga Universe',
  };

  // Core status values that cannot be deleted (case-insensitive)
  final Set<String> _coreStatusValues = {
    'yes',
    'no',
    'started',
    'tbreleased',
    'abandoned',
    'repeated',
    'standby',
  };

  // Core format saga values that cannot be deleted (case-insensitive)
  final Set<String> _coreFormatSagaValues = {
    'standalone',
    'bilogy',
    'trilogy',
    'tetralogy',
    'pentalogy',
    'hexalogy',
    'saga',
  };

  bool _isCoreStatusValue(String value) {
    return _selectedTable == 'status' &&
        _coreStatusValues.contains(value.toLowerCase());
  }

  bool _isCoreFormatSagaValue(String value) {
    return _selectedTable == 'format_saga' &&
        _coreFormatSagaValues.contains(value.toLowerCase());
  }

  bool _isCoreValue(String value) {
    return _isCoreStatusValue(value) || _isCoreFormatSagaValue(value);
  }

  @override
  void initState() {
    super.initState();
    _loadValues();
  }

  Future<void> _loadValues() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);
      final values = await repository.getLookupValues(_selectedTable);

      setState(() {
        _values = values;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading values: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Shows a dialog to ask for expected books count for format_saga values
  Future<int?> _showFormatSagaHelper(String formatSagaName) async {
    final controller = TextEditingController();
    String? selectedOption = 'number'; // 'number' or 'unknown'

    return await showDialog<int?>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.saga_completion_setup,
                        ),
                      ),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.you_are_adding(formatSagaName),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.how_many_books_saga,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.saga_completion_explanation,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        RadioListTile<String>(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!.specific_number_of_books,
                          ),
                          value: 'number',
                          groupValue: selectedOption,
                          onChanged: (value) {
                            setState(() {
                              selectedOption = value;
                            });
                          },
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        if (selectedOption == 'number')
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 32,
                              right: 16,
                              bottom: 8,
                            ),
                            child: TextField(
                              controller: controller,
                              decoration: InputDecoration(
                                labelText:
                                    AppLocalizations.of(
                                      context,
                                    )!.number_of_books,
                                hintText: 'e.g., 7',
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                              autofocus: true,
                            ),
                          ),
                        RadioListTile<String>(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!.unknown_show_as_question,
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!.for_sagas_unknown_length,
                            style: const TextStyle(fontSize: 12),
                          ),
                          value: 'unknown',
                          groupValue: selectedOption,
                          onChanged: (value) {
                            setState(() {
                              selectedOption = value;
                            });
                          },
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.examples,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildFormatExample('Trilogy', '3 books'),
                        _buildFormatExample('Heptalogy', '7 books'),
                        _buildFormatExample('Saga', '? (unknown)'),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, null),
                      child: Text(AppLocalizations.of(context)!.cancel),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (selectedOption == 'unknown') {
                          Navigator.pop(context, -1); // -1 means unknown
                        } else {
                          final value = int.tryParse(controller.text.trim());
                          if (value == null || value < 1) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.enter_valid_number,
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }
                          Navigator.pop(context, value);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(AppLocalizations.of(context)!.continue_label),
                    ),
                  ],
                ),
          ),
    );
  }

  Widget _buildFormatExample(String format, String total) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        children: [
          Icon(Icons.circle, size: 6, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            '$format: ',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          ),
          Text(
            total,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _addValue() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              '${AppLocalizations.of(context)!.add} ${_tableLabels[_selectedTable]}',
            ),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.value_label,
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: Text(AppLocalizations.of(context)!.add),
              ),
            ],
          ),
    );

    if (result != null && result.isNotEmpty) {
      int? expectedBooks;

      // For format_saga, show helper modal to get expected books count
      if (_selectedTable == 'format_saga') {
        expectedBooks = await _showFormatSagaHelper(result);
        if (expectedBooks == null) {
          return; // User cancelled
        }
        // Convert -1 (unknown) to null for database
        if (expectedBooks == -1) {
          expectedBooks = null;
        }
      }

      try {
        final db = await DatabaseHelper.instance.database;
        final repository = BookRepository(db);
        await repository.addLookupValue(
          _selectedTable,
          result,
          expectedBooks: expectedBooks,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.value_added_successfully,
              ),
              backgroundColor: Colors.green,
            ),
          );
        }

        _loadValues();

        // Refresh book list in home screen
        if (mounted) {
          final provider = Provider.of<BookProvider?>(context, listen: false);
          await provider?.loadBooks();
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
      }
    }
  }

  Future<void> _editValue(int id, String currentValue) async {
    final controller = TextEditingController(text: currentValue);
    final isCoreStatus = _isCoreStatusValue(currentValue);
    final isCoreFormatSaga = _isCoreFormatSagaValue(currentValue);
    final isCoreValue = isCoreStatus || isCoreFormatSaga;

    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              '${AppLocalizations.of(context)!.edit} ${_tableLabels[_selectedTable]}',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isCoreValue)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isCoreStatus
                                ? AppLocalizations.of(
                                  context,
                                )!.core_status_warning
                                : AppLocalizations.of(
                                  context,
                                )!.core_format_saga_warning,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.value_label,
                    border: const OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: Text(AppLocalizations.of(context)!.save),
              ),
            ],
          ),
    );

    if (result != null && result.isNotEmpty && result != currentValue) {
      try {
        final db = await DatabaseHelper.instance.database;
        final repository = BookRepository(db);
        await repository.updateLookupValue(_selectedTable, id, result);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.value_updated_successfully,
              ),
              backgroundColor: Colors.green,
            ),
          );
        }

        _loadValues();

        // Refresh book list in home screen
        if (mounted) {
          final provider = Provider.of<BookProvider?>(context, listen: false);
          await provider?.loadBooks();
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
      }
    }
  }

  Future<void> _deleteValue(int id, String value) async {
    // Prevent deletion of core values
    if (_isCoreValue(value)) {
      if (mounted) {
        String message;
        if (_isCoreStatusValue(value)) {
          message = AppLocalizations.of(context)!.core_status_cannot_delete;
        } else {
          message =
              AppLocalizations.of(context)!.core_format_saga_cannot_delete;
        }
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(AppLocalizations.of(context)!.cannot_delete),
                content: Text(message),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.ok),
                  ),
                ],
              ),
        );
      }
      return;
    }

    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);

      // Check if value is in use
      final idColumn =
          _selectedTable == 'format_saga'
              ? 'format_id'
              : '${_selectedTable}_id';
      // Column name in book table (format_saga uses format_saga_id in book table)
      final bookColumnName =
          _selectedTable == 'format_saga' ? 'format_saga_id' : idColumn;
      int usageCount;

      // For author and genre, check junction tables
      if (_selectedTable == 'author') {
        final booksUsingValue = await db.rawQuery(
          'SELECT COUNT(*) as count FROM books_by_author WHERE author_id = ?',
          [id],
        );
        usageCount = booksUsingValue.first['count'] as int;
      } else if (_selectedTable == 'genre') {
        final booksUsingValue = await db.rawQuery(
          'SELECT COUNT(*) as count FROM books_by_genre WHERE genre_id = ?',
          [id],
        );
        usageCount = booksUsingValue.first['count'] as int;
      } else if (_selectedTable == 'saga_universe') {
        // saga_universe is a text field in book table
        final booksUsingValue = await db.rawQuery(
          'SELECT COUNT(*) as count FROM book WHERE saga_universe = ?',
          [value],
        );
        usageCount = booksUsingValue.first['count'] as int;
      } else if (_selectedTable == 'saga') {
        // saga is a text field in book table
        final booksUsingValue = await db.rawQuery(
          'SELECT COUNT(*) as count FROM book WHERE saga = ?',
          [value],
        );
        usageCount = booksUsingValue.first['count'] as int;
      } else {
        // For other tables (status, format, language, place, editorial, format_saga)
        final booksUsingValue = await db.rawQuery(
          'SELECT COUNT(*) as count FROM book WHERE $bookColumnName = ?',
          [id],
        );
        usageCount = booksUsingValue.first['count'] as int;
      }

      if (usageCount > 0) {
        // Value is in use, show options dialog
        final action = await showDialog<String>(
          context: context,
          builder:
              (context) => _DeleteOptionsDialog(
                value: value,
                usageCount: usageCount,
                tableName: _selectedTable,
                currentId: id,
                allValues: _values,
              ),
        );

        if (action == null) return; // User cancelled

        if (action == 'delete') {
          // Delete completely (will fail if FK constraint)
          if (_selectedTable == 'author') {
            // Delete from junction table first
            await db.delete(
              'books_by_author',
              where: 'author_id = ?',
              whereArgs: [id],
            );
          } else if (_selectedTable == 'genre') {
            // Delete from junction table first
            await db.delete(
              'books_by_genre',
              where: 'genre_id = ?',
              whereArgs: [id],
            );
          }
          await repository.deleteLookupValue(_selectedTable, id);
        } else if (action.startsWith('replace:')) {
          // Replace with another value
          final newId = int.parse(action.split(':')[1]);
          if (_selectedTable == 'author') {
            // Update junction table
            await db.rawUpdate(
              'UPDATE books_by_author SET author_id = ? WHERE author_id = ?',
              [newId, id],
            );
          } else if (_selectedTable == 'genre') {
            // Update junction table
            await db.rawUpdate(
              'UPDATE books_by_genre SET genre_id = ? WHERE genre_id = ?',
              [newId, id],
            );
          } else if (_selectedTable == 'saga_universe' ||
              _selectedTable == 'saga') {
            // These are text fields, need special handling
            final newValueResult = await repository.getLookupValues(
              _selectedTable,
            );
            final newValueMap = newValueResult.firstWhere(
              (v) => v['${_selectedTable}_id'] == newId,
            );
            final newValue = newValueMap['name'] as String;
            await db.rawUpdate(
              'UPDATE book SET $_selectedTable = ? WHERE $_selectedTable = ?',
              [newValue, value],
            );
          } else {
            // Update book table directly
            await db.rawUpdate(
              'UPDATE book SET $bookColumnName = ? WHERE $bookColumnName = ?',
              [newId, id],
            );
          }
          // For saga and saga_universe, we don't delete from a lookup table
          if (_selectedTable != 'saga' && _selectedTable != 'saga_universe') {
            await repository.deleteLookupValue(_selectedTable, id);
          }
        } else if (action.startsWith('create:')) {
          // Create new value and replace
          final newValue = action.split(':')[1];
          if (_selectedTable == 'saga_universe' || _selectedTable == 'saga') {
            // These are text fields, update directly with new value
            await db.rawUpdate(
              'UPDATE book SET $_selectedTable = ? WHERE $_selectedTable = ?',
              [newValue, value],
            );
          } else {
            int? expectedBooks;

            // For format_saga, show helper modal to get expected books count
            if (_selectedTable == 'format_saga') {
              expectedBooks = await _showFormatSagaHelper(newValue);
              if (expectedBooks == null) {
                return; // User cancelled
              }
              // Convert -1 (unknown) to null for database
              if (expectedBooks == -1) {
                expectedBooks = null;
              }
            }

            final newId = await repository.addLookupValue(
              _selectedTable,
              newValue,
              expectedBooks: expectedBooks,
            );
            if (_selectedTable == 'author') {
              // Update junction table
              await db.rawUpdate(
                'UPDATE books_by_author SET author_id = ? WHERE author_id = ?',
                [newId, id],
              );
            } else if (_selectedTable == 'genre') {
              // Update junction table
              await db.rawUpdate(
                'UPDATE books_by_genre SET genre_id = ? WHERE genre_id = ?',
                [newId, id],
              );
            } else {
              // Update book table directly
              await db.rawUpdate(
                'UPDATE book SET $bookColumnName = ? WHERE $bookColumnName = ?',
                [newId, id],
              );
            }
            await repository.deleteLookupValue(_selectedTable, id);
          }
        }
      } else {
        // Value not in use, simple confirmation
        final confirmed = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(AppLocalizations.of(context)!.confirm_delete_title),
                content: Text(
                  AppLocalizations.of(context)!.confirm_delete_value(value),
                ),
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

        if (confirmed == true) {
          await repository.deleteLookupValue(_selectedTable, id);
        } else {
          return;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.value_deleted_successfully,
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      _loadValues();

      // Refresh book list in home screen
      if (mounted) {
        final provider = Provider.of<BookProvider?>(context, listen: false);
        await provider?.loadBooks();
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.manage_dropdown_values),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String>(
              value: _selectedTable,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.select_category,
                border: const OutlineInputBorder(),
              ),
              items:
                  _tableLabels.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedTable = value;
                  });
                  _loadValues();
                }
              },
            ),
          ),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _values.length,
                itemBuilder: (context, index) {
                  final item = _values[index];
                  final idColumn =
                      _selectedTable == 'format_saga'
                          ? 'format_id'
                          : '${_selectedTable}_id';
                  final valueColumn =
                      _selectedTable == 'status' ||
                              _selectedTable == 'format' ||
                              _selectedTable == 'format_saga'
                          ? 'value'
                          : 'name';

                  final id = item[idColumn] as int;
                  final value = item[valueColumn] as String;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: ListTile(
                      title: Text(value),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editValue(id, value),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete,
                              color:
                                  _isCoreValue(value)
                                      ? Colors.grey
                                      : Colors.red,
                            ),
                            onPressed:
                                _isCoreValue(value)
                                    ? null
                                    : () => _deleteValue(id, value),
                            tooltip:
                                _isCoreValue(value)
                                    ? AppLocalizations.of(
                                      context,
                                    )!.core_value_cannot_delete
                                    : AppLocalizations.of(context)!.delete,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addValue,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _DeleteOptionsDialog extends StatefulWidget {
  final String value;
  final int usageCount;
  final String tableName;
  final int currentId;
  final List<Map<String, dynamic>> allValues;

  const _DeleteOptionsDialog({
    required this.value,
    required this.usageCount,
    required this.tableName,
    required this.currentId,
    required this.allValues,
  });

  @override
  State<_DeleteOptionsDialog> createState() => _DeleteOptionsDialogState();
}

class _DeleteOptionsDialogState extends State<_DeleteOptionsDialog> {
  String _selectedOption = 'replace';
  int? _selectedReplacement;
  final TextEditingController _newValueController = TextEditingController();

  @override
  void dispose() {
    _newValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final valueColumn =
        widget.tableName == 'status' ||
                widget.tableName == 'format' ||
                widget.tableName == 'format_saga'
            ? 'value'
            : 'name';
    final idColumn =
        widget.tableName == 'format_saga'
            ? 'format_id'
            : '${widget.tableName}_id';

    // Get other values (excluding current)
    final otherValues =
        widget.allValues.where((v) => v[idColumn] != widget.currentId).toList();

    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.delete_value),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(
                context,
              )!.value_in_use(widget.value, widget.usageCount),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.what_would_you_like_to_do),
            const SizedBox(height: 12),

            // Option 1: Replace with existing
            if (otherValues.isNotEmpty)
              RadioListTile<String>(
                title: Text(
                  AppLocalizations.of(context)!.replace_with_existing,
                ),
                value: 'replace',
                groupValue: _selectedOption,
                onChanged: (value) {
                  setState(() {
                    _selectedOption = value!;
                  });
                },
              ),
            if (_selectedOption == 'replace' && otherValues.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 32, right: 16),
                child: DropdownButtonFormField<int>(
                  value: _selectedReplacement,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.select_replacement,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  isExpanded: true,
                  items:
                      otherValues.map((v) {
                        return DropdownMenuItem<int>(
                          value: v[idColumn] as int,
                          child: Text(
                            v[valueColumn] as String,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedReplacement = value;
                    });
                  },
                ),
              ),
            const SizedBox(height: 12),

            // Option 2: Create new
            RadioListTile<String>(
              title: Text(AppLocalizations.of(context)!.create_new_value),
              value: 'create',
              groupValue: _selectedOption,
              onChanged: (value) {
                setState(() {
                  _selectedOption = value!;
                });
              },
            ),
            if (_selectedOption == 'create')
              Padding(
                padding: const EdgeInsets.only(left: 32, right: 16),
                child: TextField(
                  controller: _newValueController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.new_value,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
              ),
            const SizedBox(height: 12),

            // Option 3: Delete completely
            RadioListTile<String>(
              title: Text(AppLocalizations.of(context)!.delete_completely),
              subtitle: Text(
                AppLocalizations.of(context)!.delete_may_fail,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              value: 'delete',
              groupValue: _selectedOption,
              onChanged: (value) {
                setState(() {
                  _selectedOption = value!;
                });
              },
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
            if (_selectedOption == 'replace') {
              if (_selectedReplacement == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.please_select_replacement,
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Navigator.pop(context, 'replace:$_selectedReplacement');
            } else if (_selectedOption == 'create') {
              final newValue = _newValueController.text.trim();
              if (newValue.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.please_enter_new_value,
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Navigator.pop(context, 'create:$newValue');
            } else {
              Navigator.pop(context, 'delete');
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Text(AppLocalizations.of(context)!.proceed),
        ),
      ],
    );
  }
}

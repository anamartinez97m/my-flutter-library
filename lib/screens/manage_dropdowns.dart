import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';

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
  };

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

  Future<void> _addValue() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Add ${_tableLabels[_selectedTable]}'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Value',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add'),
              ),
            ],
          ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        final db = await DatabaseHelper.instance.database;
        final repository = BookRepository(db);
        await repository.addLookupValue(_selectedTable, result);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Value added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }

        _loadValues();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding value: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editValue(int id, String currentValue) async {
    final controller = TextEditingController(text: currentValue);

    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Edit ${_tableLabels[_selectedTable]}'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Value',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save'),
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
            const SnackBar(
              content: Text('Value updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }

        _loadValues();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating value: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteValue(int id, String value) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);
      
      // Check if value is in use
      final idColumn = _selectedTable == 'format_saga' ? 'format_id' : '${_selectedTable}_id';
      final booksUsingValue = await db.rawQuery(
        'SELECT COUNT(*) as count FROM book WHERE $idColumn = ?',
        [id],
      );
      final usageCount = booksUsingValue.first['count'] as int;
      
      if (usageCount > 0) {
        // Value is in use, show options dialog
        final action = await showDialog<String>(
          context: context,
          builder: (context) => _DeleteOptionsDialog(
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
          await repository.deleteLookupValue(_selectedTable, id);
        } else if (action.startsWith('replace:')) {
          // Replace with another value
          final newId = int.parse(action.split(':')[1]);
          await db.rawUpdate(
            'UPDATE book SET $idColumn = ? WHERE $idColumn = ?',
            [newId, id],
          );
          await repository.deleteLookupValue(_selectedTable, id);
        } else if (action.startsWith('create:')) {
          // Create new value and replace
          final newValue = action.split(':')[1];
          final newId = await repository.addLookupValue(_selectedTable, newValue);
          await db.rawUpdate(
            'UPDATE book SET $idColumn = ? WHERE $idColumn = ?',
            [newId, id],
          );
          await repository.deleteLookupValue(_selectedTable, id);
        }
      } else {
        // Value not in use, simple confirmation
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: Text('Are you sure you want to delete "$value"?'),
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
        
        if (confirmed == true) {
          await repository.deleteLookupValue(_selectedTable, id);
        } else {
          return;
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Value deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      _loadValues();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting value: $e'),
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
        title: const Text('Manage Dropdown Values'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String>(
              value: _selectedTable,
              decoration: const InputDecoration(
                labelText: 'Select Category',
                border: OutlineInputBorder(),
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
                  // format_saga table uses 'format_id' not 'format_saga_id'
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
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteValue(id, value),
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
    final valueColumn = widget.tableName == 'status' ||
            widget.tableName == 'format' ||
            widget.tableName == 'format_saga'
        ? 'value'
        : 'name';
    final idColumn = widget.tableName == 'format_saga'
        ? 'format_id'
        : '${widget.tableName}_id';

    // Get other values (excluding current)
    final otherValues = widget.allValues
        .where((v) => v[idColumn] != widget.currentId)
        .toList();

    return AlertDialog(
      title: const Text('Delete Value'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The value "${widget.value}" is used by ${widget.usageCount} book(s).',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('What would you like to do?'),
            const SizedBox(height: 12),
            
            // Option 1: Replace with existing
            if (otherValues.isNotEmpty)
              RadioListTile<String>(
                title: const Text('Replace with existing value'),
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
                  decoration: const InputDecoration(
                    labelText: 'Select replacement',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: otherValues.map((v) {
                    return DropdownMenuItem<int>(
                      value: v[idColumn] as int,
                      child: Text(v[valueColumn] as String),
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
              title: const Text('Create new value'),
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
                  decoration: const InputDecoration(
                    labelText: 'New value',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
              ),
            const SizedBox(height: 12),
            
            // Option 3: Delete completely
            RadioListTile<String>(
              title: const Text('Delete completely (may fail)'),
              subtitle: const Text(
                'This will fail if database constraints prevent it',
                style: TextStyle(fontSize: 12, color: Colors.grey),
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
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_selectedOption == 'replace') {
              if (_selectedReplacement == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select a replacement value'),
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
                  const SnackBar(
                    content: Text('Please enter a new value'),
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
          child: const Text('Proceed'),
        ),
      ],
    );
  }
}

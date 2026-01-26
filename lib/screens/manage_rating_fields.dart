import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/repositories/book_rating_field_repository.dart';

class ManageRatingFieldsScreen extends StatefulWidget {
  const ManageRatingFieldsScreen({super.key});

  @override
  State<ManageRatingFieldsScreen> createState() => _ManageRatingFieldsScreenState();
}

class _ManageRatingFieldsScreenState extends State<ManageRatingFieldsScreen> {
  List<String> _fieldNames = [];
  bool _isLoading = true;
  final _defaultSuggestions = [
    'Plot',
    'Characters',
    'Writing Style',
    'Pacing',
    'World Building',
    'Dialogue',
    'Atmosphere',
  ];

  @override
  void initState() {
    super.initState();
    _loadFieldNames();
  }

  Future<void> _loadFieldNames() async {
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRatingFieldRepository(db);
      final names = await repository.getAllFieldNames();
      
      setState(() {
        _fieldNames = names;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading rating field names: $e');
      setState(() {
        _fieldNames = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _addFieldName() async {
    final controller = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Rating Field Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Field Name',
            hintText: 'e.g., Romance, Action, Suspense',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context, name);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      if (_fieldNames.contains(result)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Field name "$result" already exists'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      try {
        final db = await DatabaseHelper.instance.database;
        final repository = BookRatingFieldRepository(db);
        await repository.addFieldName(result);
        
        await _loadFieldNames();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added "$result"'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error adding field name: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding field name: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editFieldName(String oldName) async {
    final controller = TextEditingController(text: oldName);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Rating Field Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Field Name',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context, name);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != oldName) {
      if (_fieldNames.contains(result)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Field name "$result" already exists'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      try {
        final db = await DatabaseHelper.instance.database;
        final repository = BookRatingFieldRepository(db);
        await repository.updateFieldName(oldName, result);
        
        await _loadFieldNames();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Updated "$oldName" to "$result"'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error updating field name: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating field name: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteFieldName(String name) async {
    // Check if this field name is used in any books
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM book_rating_fields WHERE field_name = ?',
      [name],
    );
    final count = result.first['count'] as int;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Rating Field Name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "$name"?'),
            if (count > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This field is used in $count rating(s). They will be deleted.',
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
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
      try {
        final repository = BookRatingFieldRepository(db);
        await repository.deleteFieldName(name);
        
        await _loadFieldNames();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted "$name"'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error deleting field name: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting field name: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Rating Field Names'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Info card
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'About Rating Fields',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'These are the criterion names available when rating books. '
                          'You can add custom names or edit existing ones. '
                          'Changes will apply to all future ratings.',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),

                // List of field names
                Expanded(
                  child: _fieldNames.isEmpty
                      ? const Center(
                          child: Text('No rating field names yet'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _fieldNames.length,
                          itemBuilder: (context, index) {
                            final name = _fieldNames[index];
                            final isDefault = _defaultSuggestions.contains(name);
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Icon(
                                  isDefault ? Icons.star : Icons.star_border,
                                  color: isDefault
                                      ? Colors.amber
                                      : Theme.of(context).colorScheme.primary,
                                ),
                                title: Text(name),
                                subtitle: isDefault
                                    ? const Text('Default suggestion')
                                    : null,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _editFieldName(name),
                                      tooltip: 'Edit',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      color: Colors.red,
                                      onPressed: () => _deleteFieldName(name),
                                      tooltip: 'Delete',
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addFieldName,
        icon: const Icon(Icons.add),
        label: const Text('Add Field Name'),
      ),
    );
  }
}

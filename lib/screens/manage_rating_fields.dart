import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/repositories/book_rating_field_repository.dart';

class ManageRatingFieldsScreen extends StatefulWidget {
  const ManageRatingFieldsScreen({super.key});

  @override
  State<ManageRatingFieldsScreen> createState() =>
      _ManageRatingFieldsScreenState();
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
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;

    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.add_rating_field_name),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.field_name,
                hintText: AppLocalizations.of(context)!.field_name_hint,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = controller.text.trim();
                  if (name.isNotEmpty) {
                    Navigator.pop(context, name);
                  }
                },
                child: Text(AppLocalizations.of(context)!.add),
              ),
            ],
          ),
    );

    if (result != null && result.isNotEmpty) {
      if (_fieldNames.contains(result)) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.field_name_already_exists(result)),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      try {
        final db = await DatabaseHelper.instance.database;
        final repository = BookRatingFieldRepository(db);
        await repository.addFieldName(result);

        await _loadFieldNames();

        if (!context.mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.added_value(result)),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        debugPrint('Error adding field name: $e');
        messenger.showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editFieldName(String oldName) async {
    final controller = TextEditingController(text: oldName);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;

    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.edit_rating_field_name),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.field_name,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = controller.text.trim();
                  if (name.isNotEmpty) {
                    Navigator.pop(context, name);
                  }
                },
                child: Text(AppLocalizations.of(context)!.save),
              ),
            ],
          ),
    );

    if (result != null && result.isNotEmpty && result != oldName) {
      if (_fieldNames.contains(result)) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.field_name_already_exists(result)),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      try {
        final db = await DatabaseHelper.instance.database;
        final repository = BookRatingFieldRepository(db);
        await repository.updateFieldName(oldName, result);

        await _loadFieldNames();

        if (!context.mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.updated_field_name(oldName, result)),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        debugPrint('Error updating field name: $e');
        messenger.showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteFieldName(String name) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Check if this field name is used in any books
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM book_rating_fields WHERE field_name = ?',
      [name],
    );
    final count = result.first['count'] as int;

    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      // ignore: use_build_context_synchronously
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.delete_rating_field_name),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.confirm_delete_value(name)),
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
                            AppLocalizations.of(
                              context,
                            )!.field_used_in_ratings(count),
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
      try {
        final repository = BookRatingFieldRepository(db);
        await repository.deleteFieldName(name);

        await _loadFieldNames();

        if (!context.mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.deleted_value(name)),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        debugPrint('Error deleting field name: $e');
        messenger.showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
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
        title: Text(AppLocalizations.of(context)!.manage_rating_field_names),
        centerTitle: true,
      ),
      body:
          _isLoading
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
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.about_rating_fields,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.about_rating_fields_description,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // List of field names
                  Expanded(
                    child:
                        _fieldNames.isEmpty
                            ? Center(
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                )!.no_rating_field_names,
                              ),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: _fieldNames.length,
                              itemBuilder: (context, index) {
                                final name = _fieldNames[index];
                                final isDefault = _defaultSuggestions.contains(
                                  name,
                                );

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: Icon(
                                      isDefault
                                          ? Icons.star
                                          : Icons.star_border,
                                      color:
                                          isDefault
                                              ? Colors.amber
                                              : Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                    ),
                                    title: Text(name),
                                    subtitle:
                                        isDefault
                                            ? Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.default_suggestion,
                                            )
                                            : null,
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () => _editFieldName(name),
                                          tooltip:
                                              AppLocalizations.of(
                                                context,
                                              )!.edit,
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          color: Colors.red,
                                          onPressed:
                                              () => _deleteFieldName(name),
                                          tooltip:
                                              AppLocalizations.of(
                                                context,
                                              )!.delete,
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
        label: Text(AppLocalizations.of(context)!.add_field_name),
      ),
    );
  }
}

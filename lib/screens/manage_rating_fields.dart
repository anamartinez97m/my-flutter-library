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
  Map<String, int> _fieldWeights = {};
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
      final weights = await repository.getAllFieldNamesWithWeights();

      setState(() {
        _fieldNames = names;
        _fieldWeights = weights;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading rating field names: $e');
      setState(() {
        _fieldNames = [];
        _fieldWeights = {};
        _isLoading = false;
      });
    }
  }

  int get _totalWeight => _fieldWeights.values.fold(0, (s, v) => s + v);

  Future<void> _editFieldWeight(String name) async {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);
    final currentWeight = _fieldWeights[name] ?? 0;
    final controller = TextEditingController(text: currentWeight.toString());

    final result = await showDialog<int>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.edit_weight),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.rating_field_weight,
                    suffixText: '%',
                    border: const OutlineInputBorder(),
                    helperText: l10n.weight_range_hint,
                  ),
                  autofocus: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  final value = int.tryParse(controller.text.trim());
                  if (value != null && value >= 0 && value <= 100) {
                    Navigator.pop(context, value);
                  }
                },
                child: Text(l10n.save),
              ),
            ],
          ),
    );

    if (result != null) {
      try {
        final db = await DatabaseHelper.instance.database;
        final repository = BookRatingFieldRepository(db);
        await repository.updateFieldWeight(name, result);
        await _loadFieldNames();
        if (!context.mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.weight_saved),
            backgroundColor: colorScheme.primary,
          ),
        );
      } catch (e) {
        debugPrint('Error updating weight: $e');
      }
    }
  }

  Future<void> _addFieldName() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final controller = TextEditingController();

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
            backgroundColor: colorScheme.secondary,
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
            backgroundColor: colorScheme.primary,
          ),
        );
      } catch (e) {
        debugPrint('Error adding field name: $e');
        messenger.showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _editFieldName(String oldName) async {
    final controller = TextEditingController(text: oldName);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

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
            backgroundColor: colorScheme.error,
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
            backgroundColor: colorScheme.primary,
          ),
        );
      } catch (e) {
        debugPrint('Error updating field name: $e');
        messenger.showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteFieldName(String name) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

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
                      color: Theme.of(
                        context,
                      ).colorScheme.secondaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(
                              context,
                            )!.field_used_in_ratings(count),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
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
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
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
            backgroundColor: colorScheme.error,
          ),
        );
      } catch (e) {
        debugPrint('Error deleting field name: $e');
        messenger.showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: colorScheme.error,
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
                          if (_fieldNames.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Builder(
                              builder: (context) {
                                final total = _totalWeight;
                                final isValid = total == 100;
                                final hasWeights = total > 0;
                                final color =
                                    isValid
                                        ? Theme.of(context).colorScheme.primary
                                        : hasWeights
                                        ? Theme.of(context).colorScheme.error
                                        : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant;
                                return Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    Icon(Icons.percent, size: 16, color: color),
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.total_weight(total),
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (!isValid && hasWeights)
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.weight_must_sum_to_100,
                                        style: TextStyle(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.error,
                                          fontSize: 12,
                                        ),
                                      ),
                                    if (!hasWeights)
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.weights_not_configured,
                                        style: TextStyle(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ],
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

                                final weight = _fieldWeights[name] ?? 0;
                                final hasWeight = weight > 0;
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: Icon(
                                      isDefault
                                          ? Icons.star
                                          : Icons.star_border,
                                      color:
                                          isDefault
                                              ? Theme.of(
                                                context,
                                              ).colorScheme.tertiary
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
                                        // Weight badge
                                        GestureDetector(
                                          onTap: () => _editFieldWeight(name),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  hasWeight
                                                      ? Theme.of(context)
                                                          .colorScheme
                                                          .primaryContainer
                                                      : Theme.of(context)
                                                          .colorScheme
                                                          .surfaceContainerHighest,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color:
                                                    hasWeight
                                                        ? Theme.of(
                                                          context,
                                                        ).colorScheme.primary
                                                        : Theme.of(
                                                          context,
                                                        ).colorScheme.outline,
                                              ),
                                            ),
                                            child: Text(
                                              '$weight%',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    hasWeight
                                                        ? Theme.of(context)
                                                            .colorScheme
                                                            .onPrimaryContainer
                                                        : Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                        ),
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
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.error,
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

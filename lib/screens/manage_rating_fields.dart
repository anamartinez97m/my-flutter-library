import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/repositories/book_rating_field_repository.dart';

// ── v2 design tokens ─────────────────────────────────────────────────────────
const _kBg = Color(0xFFFDF8F6);
const _kPrimary = Color(0xFF43102B);
const _kSub = Color(0xFF514348);
const _kText = Color(0xFF1C1B1A);
const _kBorder = Color(0xFFD5C2C7);

class ManageRatingFieldsScreen extends StatefulWidget {
  final bool useNewUi;
  const ManageRatingFieldsScreen({super.key, this.useNewUi = false});

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

    final result =
        widget.useNewUi
            ? await _showV2WeightDialog(name, currentWeight)
            : await _showV1WeightDialog(name, currentWeight);

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
            backgroundColor: widget.useNewUi ? _kPrimary : colorScheme.primary,
          ),
        );
      } catch (e) {
        debugPrint('Error updating weight: $e');
      }
    }
  }

  Future<int?> _showV1WeightDialog(String name, int currentWeight) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: currentWeight.toString());

    return showDialog<int>(
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
  }

  Future<int?> _showV2WeightDialog(String name, int currentWeight) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: currentWeight.toString());

    return showDialog<int>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: _kBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 25,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 384),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.scale, color: _kPrimary, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            l10n.edit_weight,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: _kPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        name,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _kText,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 18,
                          color: _kText,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.rating_field_weight,
                          suffixText: '%',
                          helperText: l10n.weight_range_hint,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: _kSub),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: _kSub),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: _kPrimary,
                              width: 2,
                            ),
                          ),
                          labelStyle: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            color: _kPrimary,
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: const BoxDecoration(
                    color: _kBg,
                    border: Border(top: BorderSide(color: _kBorder)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: _kPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n.cancel,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final value = int.tryParse(controller.text.trim());
                          if (value != null && value >= 0 && value <= 100) {
                            Navigator.pop(context, value);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n.save,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _addFieldName() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final result =
        widget.useNewUi
            ? await _showV2AddFieldDialog()
            : await _showV1AddFieldDialog();

    if (result != null && result.isNotEmpty) {
      if (_fieldNames.contains(result)) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.field_name_already_exists(result)),
            backgroundColor:
                widget.useNewUi ? const Color(0xFFB3261E) : colorScheme.error,
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
            backgroundColor: widget.useNewUi ? _kPrimary : colorScheme.primary,
          ),
        );
      } catch (e) {
        debugPrint('Error adding field name: $e');
        messenger.showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor:
                widget.useNewUi ? const Color(0xFFB3261E) : colorScheme.error,
          ),
        );
      }
    }
  }

  Future<String?> _showV1AddFieldDialog() async {
    final controller = TextEditingController();

    return showDialog<String>(
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
  }

  Future<String?> _showV2AddFieldDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: _kBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 25,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 384),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.add_circle_outline,
                            color: _kPrimary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            l10n.add_rating_field_name,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: _kPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: controller,
                        textCapitalization: TextCapitalization.words,
                        autofocus: true,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 18,
                          color: _kText,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.field_name,
                          hintText: l10n.field_name_hint,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: _kSub),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: _kSub),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: _kPrimary,
                              width: 2,
                            ),
                          ),
                          labelStyle: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            color: _kPrimary,
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: const BoxDecoration(
                    color: _kBg,
                    border: Border(top: BorderSide(color: _kBorder)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: _kPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n.cancel,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final name = controller.text.trim();
                          if (name.isNotEmpty) {
                            Navigator.pop(context, name);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n.add,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _editFieldName(String oldName) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final result =
        widget.useNewUi
            ? await _showV2EditFieldDialog(oldName)
            : await _showV1EditFieldDialog(oldName);

    if (result != null && result.isNotEmpty && result != oldName) {
      if (_fieldNames.contains(result)) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.field_name_already_exists(result)),
            backgroundColor:
                widget.useNewUi ? const Color(0xFFB3261E) : colorScheme.error,
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
            backgroundColor: widget.useNewUi ? _kPrimary : colorScheme.primary,
          ),
        );
      } catch (e) {
        debugPrint('Error updating field name: $e');
        messenger.showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor:
                widget.useNewUi ? const Color(0xFFB3261E) : colorScheme.error,
          ),
        );
      }
    }
  }

  Future<String?> _showV1EditFieldDialog(String oldName) async {
    final controller = TextEditingController(text: oldName);

    return showDialog<String>(
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
  }

  Future<String?> _showV2EditFieldDialog(String oldName) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: oldName);

    return showDialog<String>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: _kBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 25,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 384),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.edit_outlined,
                            color: _kPrimary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            l10n.edit_rating_field_name,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: _kPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: controller,
                        textCapitalization: TextCapitalization.words,
                        autofocus: true,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 18,
                          color: _kText,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.field_name,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: _kSub),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: _kSub),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: _kPrimary,
                              width: 2,
                            ),
                          ),
                          labelStyle: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            color: _kPrimary,
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: const BoxDecoration(
                    color: _kBg,
                    border: Border(top: BorderSide(color: _kBorder)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: _kPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n.cancel,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final name = controller.text.trim();
                          if (name.isNotEmpty) {
                            Navigator.pop(context, name);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n.save,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
    final confirmed =
        widget.useNewUi
            ? await _showV2DeleteFieldDialog(name, count)
            : await _showV1DeleteFieldDialog(name, count);

    if (confirmed == true) {
      try {
        final repository = BookRatingFieldRepository(db);
        await repository.deleteFieldName(name);

        await _loadFieldNames();

        if (!context.mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.deleted_value(name)),
            backgroundColor:
                widget.useNewUi ? const Color(0xFFB3261E) : colorScheme.error,
          ),
        );
      } catch (e) {
        debugPrint('Error deleting field name: $e');
        messenger.showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor:
                widget.useNewUi ? const Color(0xFFB3261E) : colorScheme.error,
          ),
        );
      }
    }
  }

  Future<bool?> _showV1DeleteFieldDialog(String name, int count) async {
    return showDialog<bool>(
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
  }

  Future<bool?> _showV2DeleteFieldDialog(String name, int count) async {
    final l10n = AppLocalizations.of(context)!;

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: _kBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 25,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 384),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.delete_outline,
                            color: Color(0xFFB3261E),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            l10n.delete_rating_field_name,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFB3261E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.confirm_delete_value(name),
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 16,
                          color: _kText,
                          height: 1.4,
                        ),
                      ),
                      if (count > 0) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0x14B3261E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0x33B3261E)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xFFB3261E),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  l10n.field_used_in_ratings(count),
                                  style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 13,
                                    color: Color(0xFFB3261E),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: const BoxDecoration(
                    color: _kBg,
                    border: Border(top: BorderSide(color: _kBorder)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          foregroundColor: _kSub,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n.cancel,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB3261E),
                          foregroundColor: Colors.white,
                          elevation: 4,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n.delete,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.useNewUi) {
      return _buildV2(context);
    }
    return _buildV1(context);
  }

  Widget _buildV1(BuildContext context) {
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
                  _buildInfoCard(context),
                  _buildFieldList(context, isV2: false),
                ],
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addFieldName,
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)!.add_field_name),
      ),
    );
  }

  Widget _buildV2(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.manage_rating_field_names,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: _kPrimary,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder.withValues(alpha: 0.5)),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: _kPrimary))
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _buildInfoCard(context, isV2: true),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _buildFieldList(context, isV2: true),
                    ),
                  ),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        tooltip: l10n.add_field_name,
        onPressed: _addFieldName,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {bool isV2 = false}) {
    final l10n = AppLocalizations.of(context)!;
    if (isV2) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x1A27231E)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 6,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: _kPrimary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.about_rating_fields,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _kText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.about_rating_fields_description,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14,
                color: _kSub,
                height: 1.4,
              ),
            ),
            if (_fieldNames.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildWeightSummary(context, isV2: true),
            ],
          ],
        ),
      );
    }

    return Card(
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
                  l10n.about_rating_fields,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.about_rating_fields_description,
              style: const TextStyle(fontSize: 14),
            ),
            if (_fieldNames.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildWeightSummary(context, isV2: false),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeightSummary(BuildContext context, {bool isV2 = false}) {
    final l10n = AppLocalizations.of(context)!;
    final total = _totalWeight;
    final isValid = total == 100;
    final hasWeights = total > 0;
    final color =
        isValid
            ? (isV2 ? _kPrimary : Theme.of(context).colorScheme.primary)
            : hasWeights
            ? (isV2
                ? const Color(0xFFB3261E)
                : Theme.of(context).colorScheme.error)
            : (isV2 ? _kSub : Theme.of(context).colorScheme.onSurfaceVariant);

    final children = [
      Icon(Icons.percent, size: 16, color: color),
      const SizedBox(width: 6),
      Text(
        l10n.total_weight(total),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontFamily: isV2 ? 'Manrope' : null,
        ),
      ),
      if (!isValid && hasWeights)
        Text(
          l10n.weight_must_sum_to_100,
          style: TextStyle(
            color:
                isV2
                    ? const Color(0xFFB3261E)
                    : Theme.of(context).colorScheme.error,
            fontSize: 12,
            fontFamily: isV2 ? 'Manrope' : null,
          ),
        ),
      if (!hasWeights)
        Text(
          l10n.weights_not_configured,
          style: TextStyle(
            color:
                isV2 ? _kSub : Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontFamily: isV2 ? 'Manrope' : null,
          ),
        ),
    ];

    if (isV2) {
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 4,
        children: children,
      );
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: children,
    );
  }

  Widget _buildFieldList(BuildContext context, {bool isV2 = false}) {
    final l10n = AppLocalizations.of(context)!;
    if (_fieldNames.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.no_rating_field_names,
          style: TextStyle(
            fontFamily: isV2 ? 'Manrope' : null,
            color: isV2 ? _kSub : null,
          ),
        ),
      );
    }

    return ListView.builder(
      padding:
          isV2 ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _fieldNames.length,
      itemBuilder: (context, index) {
        final name = _fieldNames[index];
        final isDefault = _defaultSuggestions.contains(name);
        final weight = _fieldWeights[name] ?? 0;
        final hasWeight = weight > 0;

        if (isV2) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x1A27231E)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 6,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDefault ? Icons.star : Icons.star_border,
                    color: isDefault ? const Color(0xFFD4A017) : _kPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _kText,
                        ),
                      ),
                      if (isDefault)
                        Text(
                          l10n.default_suggestion,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            color: _kSub,
                          ),
                        ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _editFieldWeight(name),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          hasWeight
                              ? _kPrimary.withValues(alpha: 0.08)
                              : const Color(0xFFF2EDEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasWeight ? _kPrimary : _kBorder,
                      ),
                    ),
                    child: Text(
                      '$weight%',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: hasWeight ? _kPrimary : _kSub,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  color: _kSub,
                  onPressed: () => _editFieldName(name),
                  tooltip: l10n.edit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: const Color(0xFFB3261E),
                  onPressed: () => _deleteFieldName(name),
                  tooltip: l10n.delete,
                ),
              ],
            ),
          );
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              isDefault ? Icons.star : Icons.star_border,
              color:
                  isDefault
                      ? Theme.of(context).colorScheme.tertiary
                      : Theme.of(context).colorScheme.primary,
            ),
            title: Text(name),
            subtitle: isDefault ? Text(l10n.default_suggestion) : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            hasWeight
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    child: Text(
                      '$weight%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color:
                            hasWeight
                                ? Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer
                                : Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editFieldName(name),
                  tooltip: l10n.edit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  color: Theme.of(context).colorScheme.error,
                  onPressed: () => _deleteFieldName(name),
                  tooltip: l10n.delete,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

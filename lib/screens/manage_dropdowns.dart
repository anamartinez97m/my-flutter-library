import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:provider/provider.dart';

// ── v2 design tokens ─────────────────────────────────────────────────────────
const _kBg = Color(0xFFFDF8F6);
const _kPrimary = Color(0xFF43102B);
const _kSub = Color(0xFF514348);
const _kText = Color(0xFF1C1B1A);
const _kBorder = Color(0xFFD5C2C7);

class ManageDropdownsScreen extends StatefulWidget {
  final bool useNewUi;
  const ManageDropdownsScreen({super.key, this.useNewUi = false});

  @override
  State<ManageDropdownsScreen> createState() => _ManageDropdownsScreenState();
}

class _ManageDropdownsScreenState extends State<ManageDropdownsScreen> {
  String _selectedTable = 'status';
  List<Map<String, dynamic>> _values = [];
  bool _isLoading = false;

  static const List<String> _tableKeys = [
    'status',
    'format_saga',
    'language',
    'place',
    'format',
    'author',
    'genre',
    'editorial',
    'saga',
    'saga_universe',
  ];

  String _getTableLabel(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'status':
        return l10n.dropdown_status;
      case 'format_saga':
        return l10n.dropdown_format_saga;
      case 'language':
        return l10n.dropdown_language;
      case 'place':
        return l10n.dropdown_place;
      case 'format':
        return l10n.dropdown_format;
      case 'author':
        return l10n.dropdown_authors;
      case 'genre':
        return l10n.dropdown_genres;
      case 'editorial':
        return l10n.dropdown_editorials;
      case 'saga':
        return l10n.dropdown_saga;
      case 'saga_universe':
        return l10n.dropdown_saga_universe;
      default:
        return key;
    }
  }

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
    if (widget.useNewUi) {
      return _showFormatSagaHelperV2(formatSagaName);
    }
    return _showFormatSagaHelperV1(formatSagaName);
  }

  Future<int?> _showFormatSagaHelperV1(String formatSagaName) async {
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
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
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
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.3),
                            ),
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
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.saga_completion_explanation,
                                style: TextStyle(
                                  fontSize: 13,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
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
                                backgroundColor:
                                    Theme.of(context).colorScheme.secondary,
                              ),
                            );
                            return;
                          }
                          Navigator.pop(context, value);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                      ),
                      child: Text(AppLocalizations.of(context)!.continue_label),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<int?> _showFormatSagaHelperV2(String formatSagaName) async {
    final controller = TextEditingController();
    String? selectedOption = 'number';

    const kBg = Color(0xFFFDF8F6);
    const kPrimary = Color(0xFF5D2641);
    const kText = Color(0xFF1C1B1B);
    const kSub = Color(0xFF49454F);
    const kBorder = Color(0xFFDDD9D7);
    const kInfoBg = Color(0x1A5D2641);
    const kInfoBorder = Color(0x335D2641);

    return await showDialog<int?>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              final l10n = AppLocalizations.of(context)!;
              return Dialog(
                backgroundColor: kBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 25,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 384),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Row(
                                children: [
                                  Icon(
                                    Icons.auto_stories,
                                    color: kPrimary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    l10n.saga_completion_setup,
                                    style: const TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: kPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              // Action text
                              Text(
                                l10n.you_are_adding(formatSagaName),
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: kText,
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Info box
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(17),
                                decoration: BoxDecoration(
                                  color: kInfoBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: kInfoBorder),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.how_many_books_saga,
                                      style: const TextStyle(
                                        fontFamily: 'Manrope',
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: kPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      l10n.saga_completion_explanation,
                                      style: const TextStyle(
                                        fontFamily: 'Manrope',
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                        color: kSub,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),
                              // Option 1: Specific number
                              GestureDetector(
                                onTap:
                                    () => setState(
                                      () => selectedOption = 'number',
                                    ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: _buildV2Radio(
                                        selectedOption == 'number',
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l10n.specific_number_of_books,
                                            style: const TextStyle(
                                              fontFamily: 'Manrope',
                                              fontSize: 16,
                                              fontWeight: FontWeight.normal,
                                              color: kText,
                                            ),
                                          ),
                                          if (selectedOption == 'number') ...[
                                            const SizedBox(height: 16),
                                            // Floating label input
                                            Stack(
                                              clipBehavior: Clip.none,
                                              children: [
                                                TextField(
                                                  controller: controller,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  autofocus: true,
                                                  style: const TextStyle(
                                                    fontFamily: 'Manrope',
                                                    fontSize: 18,
                                                    color: kText,
                                                  ),
                                                  decoration: InputDecoration(
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 17,
                                                          vertical: 13,
                                                        ),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      borderSide:
                                                          const BorderSide(
                                                            color: kSub,
                                                          ),
                                                    ),
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          borderSide:
                                                              const BorderSide(
                                                                color: kSub,
                                                              ),
                                                        ),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          borderSide:
                                                              const BorderSide(
                                                                color: kPrimary,
                                                                width: 2,
                                                              ),
                                                        ),
                                                    labelText:
                                                        l10n.number_of_books,
                                                    labelStyle: const TextStyle(
                                                      fontFamily: 'Manrope',
                                                      fontSize: 12,
                                                      color: kPrimary,
                                                    ),
                                                    floatingLabelBehavior:
                                                        FloatingLabelBehavior
                                                            .always,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Option 2: Unknown
                              GestureDetector(
                                onTap:
                                    () => setState(
                                      () => selectedOption = 'unknown',
                                    ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: _buildV2Radio(
                                        selectedOption == 'unknown',
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.unknown_show_as_question,
                                          style: const TextStyle(
                                            fontFamily: 'Manrope',
                                            fontSize: 16,
                                            fontWeight: FontWeight.normal,
                                            color: kText,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          l10n.for_sagas_unknown_length,
                                          style: const TextStyle(
                                            fontFamily: 'Manrope',
                                            fontSize: 14,
                                            fontWeight: FontWeight.normal,
                                            color: kSub,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Examples
                              Text(
                                '${l10n.examples}:',
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: kText,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.only(left: 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildV2Example('Trilogy:', ' 3 books'),
                                    const SizedBox(height: 8),
                                    _buildV2Example('Heptalogy:', ' 7 books'),
                                    const SizedBox(height: 8),
                                    _buildV2Example('Saga:', ' ? (unknown)'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Sticky footer
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: const BoxDecoration(
                          color: kBg,
                          border: Border(top: BorderSide(color: kBorder)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, null),
                              style: TextButton.styleFrom(
                                foregroundColor: kPrimary,
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
                                if (selectedOption == 'unknown') {
                                  Navigator.pop(context, -1);
                                } else {
                                  final value = int.tryParse(
                                    controller.text.trim(),
                                  );
                                  if (value == null || value < 1) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(l10n.enter_valid_number),
                                        backgroundColor:
                                            Theme.of(
                                              context,
                                            ).colorScheme.secondary,
                                      ),
                                    );
                                    return;
                                  }
                                  Navigator.pop(context, value);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimary,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shadowColor: const Color(0x1A000000),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                l10n.continue_label,
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
          ),
    );
  }

  Widget _buildV2Radio(bool selected) {
    if (selected) {
      return Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 12, color: Colors.white),
      );
    }
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF6B7280)),
      ),
    );
  }

  Widget _buildV2Example(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 14,
          color: Color(0xFF49454F),
        ),
        children: [
          TextSpan(
            text: label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }

  Widget _buildFormatExample(String format, String total) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 6,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            '$format: ',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          ),
          Text(
            total,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addValue() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<BookProvider?>(context, listen: false);
    final colorScheme = Theme.of(context).colorScheme;

    final result =
        widget.useNewUi
            ? await _showV2AddValueDialog()
            : await _showV1AddValueDialog();

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

        if (!context.mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.value_added_successfully),
            backgroundColor: widget.useNewUi ? _kPrimary : colorScheme.primary,
          ),
        );

        _loadValues();

        // Refresh book list in home screen
        if (!context.mounted) return;
        await provider?.loadBooks();
      } catch (e) {
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

  Future<String?> _showV1AddValueDialog() async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              '${AppLocalizations.of(context)!.add} ${_getTableLabel(context, _selectedTable)}',
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
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: Text(AppLocalizations.of(context)!.add),
              ),
            ],
          ),
    );
  }

  Future<String?> _showV2AddValueDialog() async {
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
                            '${l10n.add} ${_getTableLabel(context, _selectedTable)}',
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
                        autofocus: true,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 18,
                          color: _kText,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.value_label,
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
                        onPressed:
                            () =>
                                Navigator.pop(context, controller.text.trim()),
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

  Future<void> _editValue(int id, String currentValue) async {
    final isCoreStatus = _isCoreStatusValue(currentValue);
    final isCoreFormatSaga = _isCoreFormatSagaValue(currentValue);
    final isCoreValue = isCoreStatus || isCoreFormatSaga;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<BookProvider?>(context, listen: false);
    final colorScheme = Theme.of(context).colorScheme;

    final result =
        widget.useNewUi
            ? await _showV2EditValueDialog(
              id,
              currentValue,
              isCoreValue,
              isCoreStatus,
            )
            : await _showV1EditValueDialog(
              id,
              currentValue,
              isCoreValue,
              isCoreStatus,
            );

    if (result != null && result.isNotEmpty && result != currentValue) {
      try {
        final db = await DatabaseHelper.instance.database;
        final repository = BookRepository(db);
        await repository.updateLookupValue(_selectedTable, id, result);

        if (!context.mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.value_updated_successfully),
            backgroundColor: widget.useNewUi ? _kPrimary : colorScheme.primary,
          ),
        );

        _loadValues();

        // Refresh book list in home screen
        if (!context.mounted) return;
        await provider?.loadBooks();
      } catch (e) {
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

  Future<String?> _showV1EditValueDialog(
    int id,
    String currentValue,
    bool isCoreValue,
    bool isCoreStatus,
  ) async {
    final controller = TextEditingController(text: currentValue);

    return showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              '${AppLocalizations.of(context)!.edit} ${_getTableLabel(context, _selectedTable)}',
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
                      color: Theme.of(
                        context,
                      ).colorScheme.secondaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.secondary.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: Theme.of(context).colorScheme.secondary,
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
                              color: Theme.of(context).colorScheme.onSurface,
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
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: Text(AppLocalizations.of(context)!.save),
              ),
            ],
          ),
    );
  }

  Future<String?> _showV2EditValueDialog(
    int id,
    String currentValue,
    bool isCoreValue,
    bool isCoreStatus,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: currentValue);

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
                Flexible(
                  child: SingleChildScrollView(
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
                              '${l10n.edit} ${_getTableLabel(context, _selectedTable)}',
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: _kPrimary,
                              ),
                            ),
                          ],
                        ),
                        if (isCoreValue) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0x14B3261E),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0x33B3261E),
                              ),
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
                                    isCoreStatus
                                        ? l10n.core_status_warning
                                        : l10n.core_format_saga_warning,
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
                        const SizedBox(height: 24),
                        TextField(
                          controller: controller,
                          autofocus: true,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 18,
                            color: _kText,
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.value_label,
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
                        onPressed:
                            () =>
                                Navigator.pop(context, controller.text.trim()),
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

  Future<void> _deleteValue(int id, String value) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<BookProvider?>(context, listen: false);
    final colorScheme = Theme.of(context).colorScheme;

    // Prevent deletion of core values
    if (_isCoreValue(value)) {
      String message;
      if (_isCoreStatusValue(value)) {
        message = l10n.core_status_cannot_delete;
      } else {
        message = l10n.core_format_saga_cannot_delete;
      }
      if (widget.useNewUi) {
        _showV2CoreDeleteWarning(message);
      } else {
        _showV1CoreDeleteWarning(message);
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

      if (!context.mounted) return;

      if (usageCount > 0) {
        // Value is in use, show options dialog
        final action = await showDialog<String>(
          // ignore: use_build_context_synchronously
          context: context,
          builder:
              (context) => _DeleteOptionsDialog(
                value: value,
                usageCount: usageCount,
                tableName: _selectedTable,
                currentId: id,
                allValues: _values,
                useNewUi: widget.useNewUi,
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
        final confirmed =
            widget.useNewUi
                ? await _showV2ConfirmDeleteDialog(value)
                : await _showV1ConfirmDeleteDialog(value);

        if (confirmed == true) {
          await repository.deleteLookupValue(_selectedTable, id);
        } else {
          return;
        }
      }

      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.value_deleted_successfully),
          backgroundColor: widget.useNewUi ? _kPrimary : colorScheme.primary,
        ),
      );

      _loadValues();

      // Refresh book list in home screen
      if (!context.mounted) return;
      await provider?.loadBooks();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('${l10n.error}: $e'),
          backgroundColor:
              widget.useNewUi ? const Color(0xFFB3261E) : colorScheme.error,
        ),
      );
    }
  }

  void _showV1CoreDeleteWarning(String message) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.cannot_delete),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.ok),
              ),
            ],
          ),
    );
  }

  void _showV2CoreDeleteWarning(String message) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
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
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: _kPrimary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.cannot_delete,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 16,
                      color: _kText,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
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
                        l10n.ok,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _showV1ConfirmDeleteDialog(String value) async {
    return showDialog<bool>(
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
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                child: Text(AppLocalizations.of(context)!.delete),
              ),
            ],
          ),
    );
  }

  Future<bool?> _showV2ConfirmDeleteDialog(String value) async {
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
                            l10n.confirm_delete_title,
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
                        l10n.confirm_delete_value(value),
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 16,
                          color: _kText,
                          height: 1.4,
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
        title: Text(AppLocalizations.of(context)!.manage_dropdown_values),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: _buildBody(context, isV2: false),
      floatingActionButton: FloatingActionButton(
        onPressed: _addValue,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: const Icon(Icons.add),
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
          l10n.manage_dropdown_values,
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
      body: _buildBody(context, isV2: true),
      floatingActionButton: FloatingActionButton(
        onPressed: _addValue,
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(BuildContext context, {required bool isV2}) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Padding(
          padding:
              isV2
                  ? const EdgeInsets.fromLTRB(20, 20, 20, 0)
                  : const EdgeInsets.all(16.0),
          child:
              isV2
                  ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
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
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedTable,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: l10n.select_category,
                          labelStyle: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            color: _kPrimary,
                          ),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 16,
                          color: _kText,
                        ),
                        icon: const Icon(Icons.expand_more, color: _kPrimary),
                        items: _buildDropdownItems(context, isV2: true),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedTable = value);
                            _loadValues();
                          }
                        },
                      ),
                    ),
                  )
                  : DropdownButtonFormField<String>(
                    initialValue: _selectedTable,
                    decoration: InputDecoration(
                      labelText: l10n.select_category,
                      border: const OutlineInputBorder(),
                    ),
                    items: _buildDropdownItems(context, isV2: false),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedTable = value);
                        _loadValues();
                      }
                    },
                  ),
        ),
        if (_isLoading)
          const Expanded(
            child: Center(child: CircularProgressIndicator(color: _kPrimary)),
          )
        else
          Expanded(child: _buildValuesList(context, isV2: isV2)),
      ],
    );
  }

  List<DropdownMenuItem<String>> _buildDropdownItems(
    BuildContext context, {
    required bool isV2,
  }) {
    return _tableKeys.map((key) {
      return DropdownMenuItem(
        value: key,
        child: Text(
          _getTableLabel(context, key),
          style: TextStyle(
            fontFamily: isV2 ? 'Manrope' : null,
            fontSize: isV2 ? 16 : null,
            color: isV2 ? _kText : null,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildValuesList(BuildContext context, {required bool isV2}) {
    final l10n = AppLocalizations.of(context)!;

    return ListView.builder(
      padding:
          isV2
              ? const EdgeInsets.fromLTRB(20, 16, 20, 80)
              : const EdgeInsets.symmetric(horizontal: 16),
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
        final isCore = _isCoreValue(value);

        if (isV2) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
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
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _kText,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    color: isCore ? _kSub : _kPrimary,
                  ),
                  onPressed: isCore ? null : () => _editValue(id, value),
                  tooltip: isCore ? l10n.core_value_cannot_delete : l10n.edit,
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: isCore ? _kSub : const Color(0xFFB3261E),
                  ),
                  onPressed: isCore ? null : () => _deleteValue(id, value),
                  tooltip: isCore ? l10n.core_value_cannot_delete : l10n.delete,
                ),
              ],
            ),
          );
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            title: Text(value),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () => _editValue(id, value),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    color:
                        _isCoreValue(value)
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : Theme.of(context).colorScheme.error,
                  ),
                  onPressed:
                      _isCoreValue(value)
                          ? null
                          : () => _deleteValue(id, value),
                  tooltip:
                      _isCoreValue(value)
                          ? l10n.core_value_cannot_delete
                          : l10n.delete,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DeleteOptionsDialog extends StatefulWidget {
  final String value;
  final int usageCount;
  final String tableName;
  final int currentId;
  final List<Map<String, dynamic>> allValues;
  final bool useNewUi;

  const _DeleteOptionsDialog({
    required this.value,
    required this.usageCount,
    required this.tableName,
    required this.currentId,
    required this.allValues,
    this.useNewUi = false,
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

    if (widget.useNewUi) {
      return _buildV2(context, valueColumn, idColumn, otherValues);
    }
    return _buildV1(context, valueColumn, idColumn, otherValues);
  }

  Widget _buildV1(
    BuildContext context,
    String valueColumn,
    String idColumn,
    List<Map<String, dynamic>> otherValues,
  ) {
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
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
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
          onPressed: () => _onProceed(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          child: Text(AppLocalizations.of(context)!.proceed),
        ),
      ],
    );
  }

  Widget _buildV2(
    BuildContext context,
    String valueColumn,
    String idColumn,
    List<Map<String, dynamic>> otherValues,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: _kBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 25,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
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
                          l10n.delete_value,
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
                      l10n.value_in_use(widget.value, widget.usageCount),
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _kText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.what_would_you_like_to_do,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 14,
                        color: _kSub,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Option 1: Replace with existing
                    if (otherValues.isNotEmpty) ...[
                      _buildV2RadioOption(
                        value: 'replace',
                        title: l10n.replace_with_existing,
                        onTap:
                            () => setState(() => _selectedOption = 'replace'),
                      ),
                      if (_selectedOption == 'replace')
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 34,
                            right: 4,
                            top: 8,
                          ),
                          child: DropdownButtonFormField<int>(
                            value: _selectedReplacement,
                            decoration: InputDecoration(
                              labelText: l10n.select_replacement,
                              labelStyle: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 12,
                                color: _kPrimary,
                              ),
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
                              isDense: true,
                            ),
                            isExpanded: true,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 15,
                              color: _kText,
                            ),
                            icon: const Icon(
                              Icons.expand_more,
                              color: _kPrimary,
                            ),
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
                      const SizedBox(height: 16),
                    ],

                    // Option 2: Create new
                    _buildV2RadioOption(
                      value: 'create',
                      title: l10n.create_new_value,
                      onTap: () => setState(() => _selectedOption = 'create'),
                    ),
                    if (_selectedOption == 'create')
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 34,
                          right: 4,
                          top: 8,
                        ),
                        child: TextField(
                          controller: _newValueController,
                          textCapitalization: TextCapitalization.words,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 16,
                            color: _kText,
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.new_value,
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
                            isDense: true,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Option 3: Delete completely
                    _buildV2RadioOption(
                      value: 'delete',
                      title: l10n.delete_completely,
                      subtitle: l10n.delete_may_fail,
                      onTap: () => setState(() => _selectedOption = 'delete'),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                    onPressed: () => _onProceed(context),
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
                      l10n.proceed,
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
  }

  Widget _buildV2RadioOption({
    required String value,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final selected = _selectedOption == value;
    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Container(
              width: selected ? 18 : 16,
              height: selected ? 18 : 16,
              decoration: BoxDecoration(
                color: selected ? _kPrimary : Colors.white,
                shape: BoxShape.circle,
                border:
                    selected
                        ? null
                        : Border.all(color: const Color(0xFF6B7280)),
              ),
              child:
                  selected
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 16,
                    color: _kText,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      color: _kSub,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onProceed(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    if (_selectedOption == 'replace') {
      if (_selectedReplacement == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.please_select_replacement),
            backgroundColor:
                widget.useNewUi
                    ? const Color(0xFFB3261E)
                    : colorScheme.secondary,
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
            content: Text(l10n.please_enter_new_value),
            backgroundColor:
                widget.useNewUi
                    ? const Color(0xFFB3261E)
                    : colorScheme.secondary,
          ),
        );
        return;
      }
      Navigator.pop(context, 'create:$newValue');
    } else {
      Navigator.pop(context, 'delete');
    }
  }
}

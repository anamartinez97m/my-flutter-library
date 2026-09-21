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
  const ManageDropdownsScreen({super.key});

  @override
  State<ManageDropdownsScreen> createState() => _ManageDropdownsScreenState();
}

class _ManageDropdownsScreenState extends State<ManageDropdownsScreen> {
  String _selectedTable = 'status';
  List<Map<String, dynamic>> _values = [];
  bool _isLoading = false;

  // Search state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadValues() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);
      final values = await repository.getLookupValues(_selectedTable);

      // Compute how many books use each dropdown option
      final idColumn =
          _selectedTable == 'format_saga'
              ? 'format_id'
              : '${_selectedTable}_id';
      final bookColumnName =
          _selectedTable == 'format_saga' ? 'format_saga_id' : idColumn;

      for (final item in values) {
        final id = item[idColumn] as int;
        final value = _extractValue(item);
        int usageCount;

        if (_selectedTable == 'author') {
          final result = await db.rawQuery(
            'SELECT COUNT(*) as count FROM books_by_author WHERE author_id = ?',
            [id],
          );
          usageCount = result.first['count'] as int;
        } else if (_selectedTable == 'genre') {
          final result = await db.rawQuery(
            'SELECT COUNT(*) as count FROM books_by_genre WHERE genre_id = ?',
            [id],
          );
          usageCount = result.first['count'] as int;
        } else if (_selectedTable == 'saga_universe') {
          final result = await db.rawQuery(
            'SELECT COUNT(*) as count FROM book WHERE saga_universe = ?',
            [value],
          );
          usageCount = result.first['count'] as int;
        } else if (_selectedTable == 'saga') {
          final result = await db.rawQuery(
            'SELECT COUNT(*) as count FROM book WHERE saga = ?',
            [value],
          );
          usageCount = result.first['count'] as int;
        } else {
          final result = await db.rawQuery(
            'SELECT COUNT(*) as count FROM book WHERE $bookColumnName = ?',
            [id],
          );
          usageCount = result.first['count'] as int;
        }

        item['_usageCount'] = usageCount;
      }

      setState(() {
        _values = values;
        _searchQuery = '';
        _searchController.clear();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading values: $e');
      setState(() {
        // Clear stale values from a different category so the UI doesn't try
        // to render them with the wrong column keys.
        _values = [];
        _isLoading = false;
      });
    }
  }

  /// Shows a dialog to ask for expected books count for format_saga values
  Future<int?> _showFormatSagaHelper(String formatSagaName) async {
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
                clipBehavior: Clip.antiAlias,
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
                                  Expanded(
                                    child: Text(
                                      l10n.saga_completion_setup,
                                      style: const TextStyle(
                                        fontFamily: 'Manrope',
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: kPrimary,
                                      ),
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
                                    Expanded(
                                      child: Column(
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
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 8,
                          runSpacing: 8,
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

  Future<void> _addValue() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<BookProvider?>(context, listen: false);

    final result = await _showV2AddValueDialog();

    if (result != null && result.value.isNotEmpty) {
      int? expectedBooks;

      // For format_saga, show helper modal to get expected books count
      if (_selectedTable == 'format_saga') {
        expectedBooks = await _showFormatSagaHelper(result.value);
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
          result.value,
          expectedBooks: expectedBooks,
          subtitle: result.subtitle,
        );

        if (!context.mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.value_added_successfully),
            backgroundColor: _kPrimary,
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
            backgroundColor: const Color(0xFFB3261E),
          ),
        );
      }
    }
  }

  Future<({String value, String? subtitle})?> _showV2AddValueDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final valueController = TextEditingController();
    final subtitleController = TextEditingController();

    return showDialog<({String value, String? subtitle})>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: _kBg,
          clipBehavior: Clip.antiAlias,
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
                        controller: valueController,
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
                      const SizedBox(height: 16),
                      TextField(
                        controller: subtitleController,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 16,
                          color: _kText,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.subtitle_label,
                          hintText: l10n.optional,
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
                          final value = valueController.text.trim();
                          if (value.isEmpty) return;
                          Navigator.pop(context, (
                            value: value,
                            subtitle:
                                subtitleController.text.trim().isEmpty
                                    ? null
                                    : subtitleController.text.trim(),
                          ));
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

  Future<void> _editValue(
    int id,
    String currentValue, {
    String? currentSubtitle,
  }) async {
    final isCoreStatus = _isCoreStatusValue(currentValue);
    final isCoreFormatSaga = _isCoreFormatSagaValue(currentValue);
    final isCoreValue = isCoreStatus || isCoreFormatSaga;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<BookProvider?>(context, listen: false);

    final result = await _showV2EditValueDialog(
      id,
      currentValue,
      currentSubtitle,
      isCoreValue,
      isCoreStatus,
    );

    final newValue = result?.value ?? '';
    final newSubtitle = result?.subtitle ?? '';
    final hasValueChange = newValue.isNotEmpty && newValue != currentValue;
    final hasSubtitleChange = newSubtitle != (currentSubtitle ?? '');

    if (newValue.isNotEmpty && (hasValueChange || hasSubtitleChange)) {
      try {
        final db = await DatabaseHelper.instance.database;
        final repository = BookRepository(db);
        await repository.updateLookupValue(
          _selectedTable,
          id,
          newValue,
          subtitle: newSubtitle.isEmpty ? null : newSubtitle,
        );

        if (!context.mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.value_updated_successfully),
            backgroundColor: _kPrimary,
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
            backgroundColor: const Color(0xFFB3261E),
          ),
        );
      }
    }
  }

  Future<({String value, String? subtitle})?> _showV2EditValueDialog(
    int id,
    String currentValue,
    String? currentSubtitle,
    bool isCoreValue,
    bool isCoreStatus,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final valueController = TextEditingController(text: currentValue);
    final subtitleController = TextEditingController(
      text: currentSubtitle ?? '',
    );

    return showDialog<({String value, String? subtitle})>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: _kBg,
          clipBehavior: Clip.antiAlias,
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
                          controller: valueController,
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
                        const SizedBox(height: 16),
                        TextField(
                          controller: subtitleController,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 16,
                            color: _kText,
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.subtitle_label,
                            hintText: l10n.optional,
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
                        onPressed: () {
                          final value = valueController.text.trim();
                          if (value.isEmpty) return;
                          Navigator.pop(context, (
                            value: value,
                            subtitle:
                                subtitleController.text.trim().isEmpty
                                    ? null
                                    : subtitleController.text.trim(),
                          ));
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

  Future<void> _deleteValue(int id, String value) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<BookProvider?>(context, listen: false);

    // Prevent deletion of core values
    if (_isCoreValue(value)) {
      String message;
      if (_isCoreStatusValue(value)) {
        message = l10n.core_status_cannot_delete;
      } else {
        message = l10n.core_format_saga_cannot_delete;
      }

      _showV2CoreDeleteWarning(message);

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
        final confirmed = await _showV2ConfirmDeleteDialog(value);

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
          backgroundColor: _kPrimary,
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
          backgroundColor: const Color(0xFFB3261E),
        ),
      );
    }
  }

  void _showV2CoreDeleteWarning(String message) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: _kBg,
          clipBehavior: Clip.antiAlias,
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

  Future<bool?> _showV2ConfirmDeleteDialog(String value) async {
    final l10n = AppLocalizations.of(context)!;

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: _kBg,
          clipBehavior: Clip.antiAlias,
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
    return _buildV2(context);
  }

  Widget _buildV2(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildV2AppBar(context),
      body: Material(
        type: MaterialType.transparency,
        child: _buildV2Body(context),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addValue,
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
    );
  }

  PreferredSizeWidget _buildV2AppBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppBar(
      backgroundColor: _kBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      toolbarHeight: 72,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: _kPrimary, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                shape: const CircleBorder(),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                l10n.manage_dropdown_values,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4A1E34),
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFF3E9E6)),
      ),
    );
  }

  List<Map<String, dynamic>> get _displayValues {
    if (_searchQuery.trim().isEmpty) return _values;
    final query = _searchQuery.toLowerCase();
    return _values.where((item) {
      final value = _extractValue(item).toLowerCase();
      return value.contains(query);
    }).toList();
  }

  String _extractValue(Map<String, dynamic> item) {
    final valueColumn =
        _selectedTable == 'status' ||
                _selectedTable == 'format' ||
                _selectedTable == 'format_saga'
            ? 'value'
            : 'name';
    return item[valueColumn] as String? ?? '';
  }

  Widget _buildV2Body(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        const SizedBox(height: 16),
        SizedBox(
          height: 38,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildCategoryChips(context),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _getEntityDescription(context, _selectedTable),
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF80717B),
                height: 1.5,
              ),
            ),
          ),
        ),
        if (_isLoading)
          const Expanded(
            child: Center(child: CircularProgressIndicator(color: _kPrimary)),
          )
        else
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: _buildConfiguredValuesHeader(context, l10n),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = _displayValues[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildValueCardV2(context, item),
                      );
                    }, childCount: _displayValues.length),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryChips(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _tableKeys.length,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final key = _tableKeys[index];
        final isSelected = _selectedTable == key;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(_getTableLabel(context, key)),
            selected: isSelected,
            onSelected: (_) {
              setState(() => _selectedTable = key);
              _loadValues();
            },
            labelStyle: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF57534E),
            ),
            selectedColor: const Color(0xFF5D2641),
            backgroundColor: Colors.white,
            side: BorderSide(
              color:
                  isSelected
                      ? const Color(0xFF5D2641)
                      : const Color(0xFFE8DEDA),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9999),
            ),
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          ),
        );
      },
    );
  }

  Widget _buildConfiguredValuesHeader(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Configured Values',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4A1E34),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFFF2E7EB),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${_displayValues.length}',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5D2641),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 16,
            color: _kText,
          ),
          decoration: InputDecoration(
            hintText: l10n.search,
            hintStyle: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              color: _kSub,
            ),
            prefixIcon: const Icon(Icons.search, color: _kSub, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildValueCardV2(BuildContext context, Map<String, dynamic> item) {
    final idColumn =
        _selectedTable == 'format_saga' ? 'format_id' : '${_selectedTable}_id';
    final id = item[idColumn] as int? ?? 0;
    final value = _extractValue(item);
    if (id == 0) return const SizedBox.shrink();
    final isCore = _isCoreValue(value);
    final color = _getValueColor(value);
    final subtitle = _getValueSubtitle(context, item);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1E8E6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0A5D2641),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 0,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2B1B24),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF80717B),
                  ),
                ),
              ],
            ),
          ),
          _buildIconButton(
            icon: Icons.edit_outlined,
            color: isCore ? const Color(0xFF80717B) : _kPrimary,
            onPressed:
                isCore
                    ? null
                    : () => _editValue(
                      id,
                      value,
                      currentSubtitle: item['subtitle'] as String?,
                    ),
          ),
          const SizedBox(width: 4),
          _buildIconButton(
            icon: Icons.delete_outline,
            color: isCore ? const Color(0xFF80717B) : const Color(0xFFB3261E),
            onPressed: isCore ? null : () => _deleteValue(id, value),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        icon: Icon(icon, size: 18, color: color),
        onPressed: onPressed,
      ),
    );
  }

  String _getEntityDescription(BuildContext context, String table) {
    switch (table) {
      case 'status':
        return 'Categorizes reading progress across your books, shelves, and reading targets.';
      case 'format':
        return 'Tracks the physical or digital format of each book in your library.';
      case 'format_saga':
        return 'Defines saga length categories for series completion tracking.';
      case 'language':
        return 'Lists languages used for the books in your collection.';
      case 'place':
        return 'Keeps track of where each book is stored or located.';
      case 'author':
        return 'Manages the authors linked to your books.';
      case 'genre':
        return 'Organizes books by literary genre and topic.';
      case 'editorial':
        return 'Stores publishers and editorial imprints for your editions.';
      case 'saga':
        return 'Holds the names of series or sagas in your library.';
      case 'saga_universe':
        return 'Groups related sagas into shared fictional universes.';
      default:
        return '';
    }
  }

  Color _getValueColor(String value) {
    if (_selectedTable == 'status') {
      switch (value.toLowerCase()) {
        case 'abandoned':
        case 'dnf':
          return const Color(0xFFF43F5E);
        case 'no':
          return const Color(0xFF94A3B8);
        case 'repeated':
          return const Color(0xFFF59E0B);
        case 'standby':
          return const Color(0xFF6366F1);
        case 'started':
          return const Color(0xFF0D9488);
        case 'tbreleased':
          return const Color(0xFFA855F7);
        case 'yes':
          return const Color(0xFF10B981);
      }
    }
    return _kPrimary;
  }

  String _getValueSubtitle(BuildContext context, Map<String, dynamic> item) {
    final l10n = AppLocalizations.of(context)!;
    final value = _extractValue(item);

    // Prefer a user-defined subtitle if provided
    final customSubtitle = (item['subtitle'] as String?)?.trim();
    if (customSubtitle != null && customSubtitle.isNotEmpty) {
      return customSubtitle;
    }

    if (_selectedTable == 'status') {
      switch (value.toLowerCase()) {
        case 'abandoned':
        case 'dnf':
          return 'Abandoned / DNF status';
        case 'no':
          return 'Used for unread flags';
        case 'repeated':
          return 'Re-read queue';
        case 'standby':
          return 'Paused reading';
        case 'started':
          return 'Currently reading';
        case 'tbreleased':
          return 'Anticipated pre-orders';
        case 'yes':
          return 'Completed status';
      }
    }

    const targetTables = {
      'format_saga',
      'language',
      'place',
      'format',
      'author',
      'genre',
      'editorial',
      'saga',
      'saga_universe',
    };
    if (targetTables.contains(_selectedTable)) {
      final count = (item['_usageCount'] as int?) ?? 0;
      return l10n.dropdown_usage_subtitle(count);
    }

    if (_selectedTable == 'format_saga') {
      return 'Saga format category';
    }
    return 'Configured value';
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

    return _buildV2(context, valueColumn, idColumn, otherValues);
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
      clipBehavior: Clip.antiAlias,
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
    if (_selectedOption == 'replace') {
      if (_selectedReplacement == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.please_select_replacement),
            backgroundColor: const Color(0xFFB3261E),
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
            backgroundColor: const Color(0xFFB3261E),
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

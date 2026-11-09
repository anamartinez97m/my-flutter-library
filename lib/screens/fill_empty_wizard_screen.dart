import 'package:flutter/material.dart';
import 'package:myrandomlibrary/config/v2_design_system.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/helpers/library_tool_fields.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/providers/role_provider.dart';
import 'package:myrandomlibrary/widgets/library_tool_value_input.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';

class FillEmptyWizardScreen extends StatefulWidget {
  const FillEmptyWizardScreen({super.key});

  @override
  State<FillEmptyWizardScreen> createState() => _FillEmptyWizardScreenState();
}

class _FillEmptyWizardScreenState extends State<FillEmptyWizardScreen> {
  static Color get _kBg => V2Colors.background;
  static Color get _kPrimary => V2Colors.primary;
  static Color get _kSecondary => V2Colors.secondary;
  static Color get _kText => V2Colors.textPrimary;
  static Color get _kSubText => V2Colors.textSubtle;
  static Color get _kIconBg => V2Colors.chip;
  static Color get _kBorder => V2Colors.border;

  String? _selectedField;
  bool _isLoading = false;
  bool _isApplying = false;

  // Groups of books: key = group name (author/saga), value = list of books
  List<_BookGroup> _groups = [];
  int _currentGroupIndex = 0;

  // Available values for the selected field
  List<FieldOption> _fieldValues = [];

  // Fields typed book by book instead of in groups
  bool _perBook = false;

  // Per-group selected value
  String? _groupSelectedValue;

  // Per-group selected book IDs
  final Set<int> _groupSelectedBookIds = {};

  final List<Map<String, String>> _availableFields = [
    for (final key in LibraryToolFields.fillGroupFields) {'key': key},
  ];

  String _getFieldLabel(String key) =>
      LibraryToolFields.label(AppLocalizations.of(context)!, key);

  IconData _getFieldIcon(String key) => LibraryToolFields.icon(key);

  /// Author and saga universe are shared by a saga, so those books are
  /// grouped by saga instead of by author.
  bool get _groupBySaga =>
      _selectedField == 'author' || _selectedField == 'saga_universe';

  Future<void> _loadEmptyBooks() async {
    if (_selectedField == null) return;

    final l10n = AppLocalizations.of(context)!;
    final ungroupedLabel = l10n.ungrouped;
    final field = _selectedField!;
    setState(() => _isLoading = true);

    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);

      // Load books with empty field
      final books = await repository.getBooksWithEmptyField(field);

      // Load available values for the field
      final values = await LibraryToolFields.loadOptions(db, field, l10n);

      final clubsByBook = <int, List<String>>{};
      if (field == 'reading_club') {
        for (final row in await db.rawQuery(
          'SELECT book_id, club_name FROM reading_clubs',
        )) {
          clubsByBook
              .putIfAbsent(row['book_id'] as int, () => [])
              .add(row['club_name'] as String);
        }
      }

      // Load ALL books to find peer suggestions
      final allBooks = await repository.getAllBooks();

      // Group books by author (primary grouping) or by saga
      final Map<String, List<Book>> authorGroups = {};
      for (final book in books) {
        if (_groupBySaga) {
          authorGroups.putIfAbsent(book.saga?.trim() ?? '', () => []).add(book);
          continue;
        }
        final authors =
            book.author?.split(',').map((a) => a.trim()).toList() ?? [];
        if (authors.isEmpty || authors.first.isEmpty) {
          authorGroups.putIfAbsent('', () => []).add(book);
        } else {
          // Put book in the first author's group
          authorGroups.putIfAbsent(authors.first, () => []).add(book);
        }
      }

      // Build groups with suggestions
      if (!context.mounted) return;
      final groups = <_BookGroup>[];
      for (final entry in authorGroups.entries) {
        final groupName = entry.key.isEmpty ? ungroupedLabel : entry.key;

        // Find suggestions from peer books (same author, different books that HAVE the field)
        final suggestions = <String>{};
        if (entry.key.isNotEmpty) {
          for (final allBook in allBooks) {
            final isPeer =
                _groupBySaga
                    ? allBook.saga?.trim() == entry.key
                    : allBook.author?.contains(entry.key) == true;
            if (!isPeer) continue;
            if (field == 'reading_club') {
              suggestions.addAll(clubsByBook[allBook.bookId] ?? const []);
              continue;
            }
            final peerValue = LibraryToolFields.bookValue(allBook, field);
            if (peerValue.isEmpty) continue;
            if (field == 'genre' || field == 'author') {
              suggestions.addAll(
                peerValue
                    .split(',')
                    .map((g) => g.trim())
                    .where((g) => g.isNotEmpty),
              );
            } else {
              suggestions.add(peerValue);
            }
          }
        }

        groups.add(
          _BookGroup(
            name: groupName,
            books: entry.value,
            suggestions: suggestions.toList(),
            isSaga: _groupBySaga && entry.key.isNotEmpty,
          ),
        );
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

    final provider = Provider.of<BookProvider?>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    setState(() => _isApplying = true);

    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);
      final count = await repository.updateBooksField(
        _groupSelectedBookIds.toList(),
        _selectedField!,
        _groupSelectedValue!,
      );

      await provider?.loadBooks();

      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.bulk_updated_books(count)),
          backgroundColor: AppTheme.notificationColor,
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
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('${l10n.error}: $e'),
          backgroundColor: colorScheme.error,
        ),
      );
    }

    if (mounted) setState(() => _isApplying = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!context.watch<RoleProvider>().isAdmin) return const Scaffold();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(
          l10n.fill_empty_fields,
          style: TextStyle(
            fontFamily: V2Typography.family,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _kText,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child:
            _selectedField == null
                ? _buildFieldPicker()
                : _perBook
                ? _PerBookFill(
                  key: ValueKey(_selectedField),
                  field: _selectedField!,
                  onBack: () => setState(() => _selectedField = null),
                )
                : _buildWizard(),
      ),
    );
  }

  Widget _buildFieldPicker() {
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Text(
          l10n.select_field_to_fill,
          style: TextStyle(
            fontFamily: V2Typography.family,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _kText,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.fill_empty_fields_hint,
          style: TextStyle(
            fontFamily: V2Typography.family,
            fontSize: 13,
            color: _kSubText,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        ..._availableFields.map((field) => _buildFieldTile(field['key']!)),
        const SizedBox(height: 12),
        Text(
          l10n.fill_per_book_section,
          style: TextStyle(
            fontFamily: V2Typography.family,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _kText,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.fill_per_book_hint,
          style: TextStyle(
            fontFamily: V2Typography.family,
            fontSize: 13,
            color: _kSubText,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        ...LibraryToolFields.fillPerBookFields.map(
          (key) => _buildFieldTile(key, perBook: true),
        ),
      ],
    );
  }

  Widget _buildFieldTile(String key, {bool perBook = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedField = key;
            _perBook = perBook;
          });
          if (!perBook) _loadEmptyBooks();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBorder.withValues(alpha: 0.55)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 12,
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
                  color: _kIconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(_getFieldIcon(key), color: _kPrimary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _getFieldLabel(key),
                  style: TextStyle(
                    fontFamily: V2Typography.family,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kText,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: _kSubText, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWizard() {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: _kPrimary,
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.fill_empty_fields_hint,
              style: TextStyle(
                fontFamily: V2Typography.family,
                fontSize: 14,
                color: _kSubText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _kIconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded, size: 36, color: _kPrimary),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.no_books_with_empty_field,
                style: TextStyle(
                  fontFamily: V2Typography.family,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _kText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedField = null;
                    _groups = [];
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kPrimary,
                  side: BorderSide(color: _kBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: Text(
                  l10n.back,
                  style: const TextStyle(
                    fontFamily: V2Typography.family,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final group = _groups[_currentGroupIndex];
    final totalEmpty = _groups.fold<int>(0, (sum, g) => sum + g.books.length);

    return Column(
      children: [
        // Progress header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorder.withValues(alpha: 0.55)),
            ),
            child: Row(
              children: [
                IconButton(
                  color: _kPrimary,
                  icon: const Icon(Icons.arrow_back, size: 20),
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
                        style: TextStyle(
                          fontFamily: V2Typography.family,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: _kText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.books_without_field(
                          totalEmpty,
                          _getFieldLabel(_selectedField!),
                        ),
                        style: TextStyle(
                          fontFamily: V2Typography.family,
                          fontSize: 11,
                          color: _kSubText,
                        ),
                      ),
                    ],
                  ),
                ),
                // Nav buttons
                IconButton(
                  color: _kPrimary,
                  onPressed:
                      _currentGroupIndex > 0
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
                  color: _kPrimary,
                  onPressed:
                      _currentGroupIndex < _groups.length - 1
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
        ),

        // Progress bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 5,
              value:
                  _groups.isEmpty
                      ? 0
                      : (_currentGroupIndex + 1) / _groups.length,
              backgroundColor: _kIconBg,
              valueColor: AlwaysStoppedAnimation<Color>(_kPrimary),
            ),
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kBorder.withValues(alpha: 0.65)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 12,
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
                          color: _kIconBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          group.isSaga
                              ? Icons.auto_stories_outlined
                              : Icons.person_outline,
                          color: _kPrimary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.name,
                              style: TextStyle(
                                fontFamily: V2Typography.family,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: _kText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.books_in_group(group.books.length),
                              style: TextStyle(
                                fontFamily: V2Typography.family,
                                fontSize: 11,
                                color: _kSubText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Suggestions from peers
                if (group.suggestions.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _kSecondary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _kSecondary.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: _kSecondary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                group.isSaga
                                    ? l10n.other_books_in_saga_have(
                                      group.suggestions.join(', '),
                                    )
                                    : l10n.other_books_have(
                                      group.suggestions.join(', '),
                                    ),
                                style: TextStyle(
                                  fontFamily: V2Typography.family,
                                  fontSize: 12,
                                  color: _kText,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children:
                              group.suggestions.map((s) {
                                final isSelected = _groupSelectedValue == s;
                                return ActionChip(
                                  label: Text(s),
                                  labelStyle: TextStyle(
                                    fontFamily: V2Typography.family,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isSelected
                                            ? V2Colors.onPrimary
                                            : _kText,
                                  ),
                                  backgroundColor: V2Colors.surface,
                                  color: WidgetStatePropertyAll(
                                    isSelected ? _kPrimary : Colors.white,
                                  ),
                                  side: BorderSide(
                                    color: isSelected ? _kPrimary : _kBorder,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
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

                // Value picker
                LibraryToolValueInput(
                  key: ValueKey(
                    '$_currentGroupIndex-${group.name}-$_groupSelectedValue',
                  ),
                  field: _selectedField!,
                  options: _fieldValues,
                  value: _groupSelectedValue,
                  label: l10n.select_value_to_apply,
                  onChanged:
                      (value) => setState(() => _groupSelectedValue = value),
                ),
                const SizedBox(height: 12),

                // Book list with checkboxes
                ...group.books.map((book) {
                  final isSelected = _groupSelectedBookIds.contains(
                    book.bookId,
                  );
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? _kPrimary.withValues(alpha: 0.04)
                              : Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            isSelected
                                ? _kPrimary.withValues(alpha: 0.22)
                                : _kBorder.withValues(alpha: 0.55),
                      ),
                    ),
                    child: CheckboxListTile(
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
                        style: TextStyle(
                          fontFamily: V2Typography.family,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: _kText,
                        ),
                      ),
                      subtitle:
                          book.author != null
                              ? Text(
                                book.author!,
                                style: TextStyle(
                                  fontFamily: V2Typography.family,
                                  fontSize: 11,
                                  color: _kSubText,
                                ),
                              )
                              : null,
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: _kPrimary,
                      checkColor: V2Colors.onPrimary,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  );
                }),
                const SizedBox(height: 16),

                // Apply button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed:
                        (_groupSelectedBookIds.isNotEmpty &&
                                _groupSelectedValue != null &&
                                !_isApplying)
                            ? _applyToGroup
                            : null,
                    icon:
                        _isApplying
                            ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: V2Colors.onPrimary,
                              ),
                            )
                            : const Icon(Icons.check, size: 18),
                    label: Text(l10n.apply_to_group),
                    style: FilledButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: V2Colors.onPrimary,
                      disabledBackgroundColor: _kBorder,
                      disabledForegroundColor: _kSubText,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                        fontFamily: V2Typography.family,
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
  final bool isSaga;

  _BookGroup({
    required this.name,
    required this.books,
    required this.suggestions,
    this.isSaga = false,
  });
}

/// Lists the books with [field] empty and lets the user type the value of
/// each one (pages, ISBN... differ for every book).
class _PerBookFill extends StatefulWidget {
  final String field;
  final VoidCallback onBack;

  const _PerBookFill({super.key, required this.field, required this.onBack});

  @override
  State<_PerBookFill> createState() => _PerBookFillState();
}

class _PerBookFillState extends State<_PerBookFill> {
  List<Book> _books = [];
  final Map<int, TextEditingController> _controllers = {};
  final Set<int> _invalidIds = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final books = await BookRepository(
        db,
      ).getBooksWithEmptyField(widget.field);
      if (!mounted) return;
      setState(() {
        _books = books.where((b) => b.bookId != null).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading books for per-book fill: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  TextEditingController _controllerFor(int bookId) =>
      _controllers.putIfAbsent(bookId, () => TextEditingController());

  int get _filledCount =>
      _controllers.values.where((c) => c.text.trim().isNotEmpty).length;

  List<Book> get _visibleBooks {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _books;
    return _books.where((book) {
      return (book.name?.toLowerCase().contains(query) ?? false) ||
          (book.author?.toLowerCase().contains(query) ?? false) ||
          (book.saga?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  TextInputType get _keyboardType {
    switch (widget.field) {
      case 'pages':
      case 'original_publication_year':
        return TextInputType.number;
      case 'price':
        return const TextInputType.numberWithOptions(decimal: true);
      case 'acquired_date':
        return TextInputType.datetime;
      default:
        return TextInputType.text;
    }
  }

  Future<void> _pickDate(int bookId) async {
    final controller = _controllerFor(bookId);
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(controller.text.trim()) ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (picked == null) return;
    setState(() {
      controller.text = formatIsoDate(picked);
      _invalidIds.remove(bookId);
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<BookProvider?>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    final values = <int, Object>{};
    final invalid = <int>{};
    for (final entry in _controllers.entries) {
      final text = entry.value.text.trim();
      if (text.isEmpty) continue;
      final value = LibraryToolFields.parsePerBookValue(widget.field, text);
      if (value == null) {
        invalid.add(entry.key);
      } else {
        values[entry.key] = value;
      }
    }

    setState(() {
      _invalidIds
        ..clear()
        ..addAll(invalid);
    });
    if (values.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final db = await DatabaseHelper.instance.database;
      final count = await BookRepository(
        db,
      ).updateBookValues(widget.field, values);
      await provider?.loadBooks();
      if (!mounted) return;
      setState(() {
        _books.removeWhere((b) => values.containsKey(b.bookId));
        for (final id in values.keys) {
          _controllers.remove(id)?.dispose();
        }
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.bulk_updated_books(count)),
          backgroundColor: AppTheme.notificationColor,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('${l10n.error}: $e'),
          backgroundColor: colorScheme.error,
        ),
      );
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = LibraryToolFields.label(l10n, widget.field);

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: V2Colors.primary));
    }

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: V2Colors.border.withValues(alpha: 0.55)),
        ),
        child: Row(
          children: [
            IconButton(
              color: V2Colors.primary,
              icon: const Icon(Icons.arrow_back, size: 20),
              onPressed: widget.onBack,
              tooltip: l10n.back,
            ),
            Expanded(
              child: Text(
                l10n.books_without_field(_books.length, label),
                style: TextStyle(
                  fontFamily: V2Typography.family,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: V2Colors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (_books.isEmpty) {
      return Column(
        children: [
          header,
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: V2Colors.chip,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 36,
                        color: V2Colors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.no_books_with_empty_field,
                      style: TextStyle(
                        fontFamily: V2Typography.family,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: V2Colors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    final books = _visibleBooks;
    final filled = _filledCount;

    return Column(
      children: [
        header,
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: TextField(
            style: TextStyle(
              fontFamily: V2Typography.family,
              fontSize: 14,
              color: V2Colors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: l10n.search_books_by_title,
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: V2Colors.surface,
              isDense: true,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: V2Colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: V2Colors.primary, width: 1.5),
              ),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              final bookId = book.bookId!;
              final saga =
                  (book.saga?.isNotEmpty ?? false)
                      ? '${book.saga}${(book.nSaga?.isNotEmpty ?? false) ? ' #${book.nSaga}' : ''}'
                      : '';
              final subtitle = [
                if (book.author?.isNotEmpty ?? false) book.author!,
                if (saga.isNotEmpty) saga,
              ].join(' · ');
              return Container(
                key: ValueKey('per_book_$bookId'),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: V2Colors.border.withValues(alpha: 0.55),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.name ?? '',
                      style: TextStyle(
                        fontFamily: V2Typography.family,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: V2Colors.textPrimary,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: V2Typography.family,
                          fontSize: 11,
                          color: V2Colors.textSubtle,
                        ),
                      ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _controllerFor(bookId),
                      keyboardType: _keyboardType,
                      textCapitalization:
                          widget.field == 'asin'
                              ? TextCapitalization.characters
                              : TextCapitalization.none,
                      style: TextStyle(
                        fontFamily: V2Typography.family,
                        fontSize: 14,
                        color: V2Colors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: label,
                        hintText:
                            widget.field == 'acquired_date'
                                ? l10n.acquired_date_format_hint
                                : null,
                        errorText:
                            _invalidIds.contains(bookId)
                                ? l10n.invalid_value
                                : null,
                        isDense: true,
                        filled: true,
                        fillColor: V2Colors.surface,
                        suffixIcon:
                            widget.field == 'acquired_date'
                                ? IconButton(
                                  icon: Icon(
                                    Icons.calendar_month_outlined,
                                    color: V2Colors.primary,
                                  ),
                                  onPressed: () => _pickDate(bookId),
                                )
                                : null,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: V2Colors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: V2Colors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged:
                          (_) => setState(() => _invalidIds.remove(bookId)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: (filled > 0 && !_isSaving) ? _save : null,
              icon:
                  _isSaving
                      ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: V2Colors.onPrimary,
                        ),
                      )
                      : const Icon(Icons.check, size: 18),
              label: Text(l10n.save_n_books(filled)),
              style: FilledButton.styleFrom(
                backgroundColor: V2Colors.primary,
                foregroundColor: V2Colors.onPrimary,
                disabledBackgroundColor: V2Colors.border,
                disabledForegroundColor: V2Colors.textSubtle,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                  fontFamily: V2Typography.family,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

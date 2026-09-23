import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/providers/role_provider.dart';
import 'package:provider/provider.dart';

class ReverseAssignScreen extends StatefulWidget {
  const ReverseAssignScreen({super.key});

  @override
  State<ReverseAssignScreen> createState() => _ReverseAssignScreenState();
}

class _ReverseAssignScreenState extends State<ReverseAssignScreen> {
  static const _kBg = Color(0xFFFDF8F6);
  static const _kPrimary = Color(0xFF43102B);
  static const _kSecondary = Color(0xFF894B67);
  static const _kText = Color(0xFF1C1B1A);
  static const _kSubText = Color(0xFF5F5E5C);
  static const _kIconBg = Color(0xFFF2EDEB);
  static const _kBorder = Color(0xFFD5C2C7);

  int _currentStep = 0;
  String? _selectedField;
  String? _selectedValue;
  List<Map<String, dynamic>> _fieldValues = [];
  List<Book> _candidateBooks = [];
  final Set<int> _selectedBookIds = {};
  bool _isLoading = false;
  bool _isApplying = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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

  String _getCurrentFieldValue(Book book) {
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

  Future<void> _loadFieldValues() async {
    if (_selectedField == null) return;

    setState(() => _isLoading = true);

    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);
      final values = await repository.getLookupValues(_selectedField!);

      setState(() {
        _fieldValues = values;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading field values: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCandidateBooks() async {
    if (_selectedField == null || _selectedValue == null) return;

    setState(() => _isLoading = true);

    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);
      final books = await repository.getBooksWithoutFieldValue(
        _selectedField!,
        _selectedValue!,
      );

      setState(() {
        _candidateBooks = books;
        _selectedBookIds.clear();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading candidate books: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _applyToSelected() async {
    if (_selectedBookIds.isEmpty ||
        _selectedField == null ||
        _selectedValue == null) {
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
        _selectedBookIds.toList(),
        _selectedField!,
        _selectedValue!,
      );

      await provider?.loadBooks();

      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.bulk_updated_books(count)),
          backgroundColor: colorScheme.primary,
        ),
      );

      await _loadCandidateBooks();
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

  List<Book> get _filteredBooks {
    if (_searchQuery.isEmpty) return _candidateBooks;
    final query = _searchQuery.toLowerCase();
    return _candidateBooks.where((book) {
      return (book.name?.toLowerCase().contains(query) ?? false) ||
          (book.author?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          l10n.assign_books_to_value,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _kText,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildStepHeader(l10n),
            Expanded(
              child:
                  _isLoading
                      ? _buildLoadingState(l10n)
                      : _currentStep == 0
                      ? _buildFieldSelector(l10n)
                      : _currentStep == 1
                      ? _buildValueSelector(l10n)
                      : _buildBookSelector(l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepHeader(AppLocalizations l10n) {
    final labels = [l10n.select_field, l10n.select_value, l10n.select_books];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder.withValues(alpha: 0.55)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    labels[_currentStep],
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _kText,
                    ),
                  ),
                ),
                Text(
                  '${_currentStep + 1} / 3',
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _kSubText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 5,
                value: (_currentStep + 1) / 3,
                backgroundColor: _kIconBg,
                valueColor: const AlwaysStoppedAnimation<Color>(_kPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              color: _kPrimary,
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.loading,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              color: _kSubText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldSelector(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text(
          l10n.select_field,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _kText,
          ),
        ),
        const SizedBox(height: 20),
        ..._availableFields.map((field) {
          final key = field['key']!;
          final isSelected = _selectedField == key;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedField = key;
                  _selectedValue = null;
                  _fieldValues = [];
                  _candidateBooks = [];
                  _selectedBookIds.clear();
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? _kPrimary.withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isSelected
                            ? _kPrimary
                            : _kBorder.withValues(alpha: 0.55),
                  ),
                  boxShadow:
                      isSelected
                          ? null
                          : const [
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
                        color:
                            isSelected
                                ? _kPrimary.withValues(alpha: 0.12)
                                : _kIconBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getFieldIcon(key),
                        color: _kPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _getFieldLabel(key),
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: _kText,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: _kPrimary,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
        _buildContinueButton(l10n),
      ],
    );
  }

  Widget _buildValueSelector(AppLocalizations l10n) {
    if (_fieldValues.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(
            l10n.no_values_available,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _kText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildBackButton(l10n),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text(
          l10n.select_value,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _kText,
          ),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          key: ValueKey('selected_value_$_selectedValue'),
          initialValue: _selectedValue,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            color: _kText,
          ),
          dropdownColor: _kBg,
          iconEnabledColor: _kPrimary,
          decoration: InputDecoration(
            labelText: l10n.select_value,
            labelStyle: const TextStyle(
              fontFamily: 'Manrope',
              color: _kSubText,
            ),
            prefixIcon: const Icon(Icons.label_outline, color: _kSecondary),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kPrimary, width: 1.5),
            ),
          ),
          items:
              _fieldValues.map((item) {
                final name = _getValueName(item);
                return DropdownMenuItem(value: name, child: Text(name));
              }).toList(),
          onChanged: (value) {
            setState(() => _selectedValue = value);
          },
        ),
        const SizedBox(height: 24),
        _buildContinueButton(l10n),
        const SizedBox(height: 8),
        _buildBackButton(l10n),
      ],
    );
  }

  Widget _buildBookSelector(AppLocalizations l10n) {
    final books = _filteredBooks;

    if (books.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          _buildInfoBar(l10n),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorder.withValues(alpha: 0.55)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: _kIconBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 36,
                    color: _kPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.all_books_already_have_value,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _kText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildBackButton(l10n),
        ],
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: _buildInfoBar(l10n),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    color: _kText,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.search_books_by_title,
                    hintStyle: const TextStyle(
                      fontFamily: 'Manrope',
                      color: _kSubText,
                    ),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _kBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: _kPrimary,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    if (_selectedBookIds.length == books.length) {
                      _selectedBookIds.clear();
                    } else {
                      _selectedBookIds.clear();
                      for (final book in books) {
                        if (book.bookId != null) {
                          _selectedBookIds.add(book.bookId!);
                        }
                      }
                    }
                  });
                },
                icon: Icon(
                  _selectedBookIds.length == books.length
                      ? Icons.deselect
                      : Icons.select_all,
                  size: 18,
                  color: _kPrimary,
                ),
                label: Text(
                  _selectedBookIds.length == books.length
                      ? l10n.deselect_all
                      : l10n.select_all,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${books.length} ${l10n.books_available}',
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12,
                color: _kSubText,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              final isSelected = _selectedBookIds.contains(book.bookId);
              final currentValue = _getCurrentFieldValue(book);

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
                        _selectedBookIds.add(book.bookId!);
                      } else {
                        _selectedBookIds.remove(book.bookId);
                      }
                    });
                  },
                  title: Text(
                    book.name ?? '',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: _kText,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (book.author != null && book.author!.isNotEmpty)
                        Text(
                          book.author!,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            color: _kSubText,
                          ),
                        ),
                      if (currentValue.isNotEmpty)
                        Text(
                          '${_getFieldLabel(_selectedField!)}: $currentValue',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 11,
                            color: _kSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                  dense: true,
                  activeColor: _kPrimary,
                  checkColor: Colors.white,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed:
                  (_selectedBookIds.isNotEmpty && !_isApplying)
                      ? _applyToSelected
                      : null,
              icon:
                  _isApplying
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.check, size: 18),
              label: Text(l10n.apply_to_n_books(_selectedBookIds.length)),
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _kBorder,
                disabledForegroundColor: _kSubText,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: _buildBackButton(l10n),
        ),
      ],
    );
  }

  Widget _buildInfoBar(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: _kPrimary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.reverse_assign_info(
                _selectedValue ?? '',
                _getFieldLabel(_selectedField ?? ''),
              ),
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                color: _kText,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _canContinue() ? _onStepContinue : null,
        icon: const Icon(Icons.arrow_forward, size: 18),
        label: Text(l10n.continue_label),
        style: FilledButton.styleFrom(
          backgroundColor: _kPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _kBorder,
          disabledForegroundColor: _kSubText,
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildBackButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _onStepCancel,
        style: OutlinedButton.styleFrom(
          foregroundColor: _kSecondary,
          side: const BorderSide(color: _kBorder),
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(l10n.back),
      ),
    );
  }

  bool _canContinue() {
    switch (_currentStep) {
      case 0:
        return _selectedField != null;
      case 1:
        return _selectedValue != null;
      default:
        return false;
    }
  }

  void _onStepContinue() {
    if (_currentStep == 0 && _selectedField != null) {
      _loadFieldValues();
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1 && _selectedValue != null) {
      _loadCandidateBooks();
      setState(() => _currentStep = 2);
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        if (_currentStep == 0) {
          _selectedValue = null;
          _fieldValues = [];
        }
        if (_currentStep <= 1) {
          _candidateBooks = [];
          _selectedBookIds.clear();
          _searchQuery = '';
          _searchController.clear();
        }
      });
    }
  }
}

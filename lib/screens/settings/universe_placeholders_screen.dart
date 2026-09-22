import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/model/universe_placeholder.dart';
import 'package:myrandomlibrary/providers/role_provider.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/screens/add_book.dart';
import 'package:myrandomlibrary/services/book_metadata_service.dart';
import 'package:myrandomlibrary/widgets/autocomplete_text_field.dart';
import 'package:myrandomlibrary/widgets/chip_autocomplete_field.dart';
import 'package:provider/provider.dart';

const _kBg = Color(0xFFFDF8F6);
const _kPrimary = Color(0xFF43102B);
const _kSecondary = Color(0xFF894B67);
const _kText = Color(0xFF1C1B1A);
const _kSub = Color(0xFF514348);
const _kBorder = Color(0xFFD5C2C7);
const _kSurface = Color(0xFFFFFBFA);

class UniversePlaceholdersScreen extends StatefulWidget {
  final String? initialUniverse;
  final UniversePlaceholder? editPlaceholder;
  final bool returnAfterEdit;
  final bool openAddForm;

  const UniversePlaceholdersScreen({
    super.key,
    this.initialUniverse,
    this.editPlaceholder,
    this.returnAfterEdit = false,
    this.openAddForm = false,
  });

  @override
  State<UniversePlaceholdersScreen> createState() =>
      _UniversePlaceholdersScreenState();
}

class _UniversePlaceholdersScreenState
    extends State<UniversePlaceholdersScreen> {
  BookRepository? _repository;
  List<String> _universes = [];
  List<String> _authors = [];
  List<String> _sagas = [];
  List<Book> _books = [];
  List<UniversePlaceholder> _placeholders = [];
  String? _selectedUniverse;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selectedUniverse = widget.initialUniverse;
    if (widget.editPlaceholder != null && widget.returnAfterEdit) {
      // Opened only to edit a placeholder from another screen; load data then
      // show the form and return once it closes.
      _load().then((_) {
        if (!mounted) return;
        _showPlaceholderForm(widget.editPlaceholder).then((_) {
          if (mounted) Navigator.pop(context);
        });
      });
    } else if (widget.openAddForm) {
      // Opened to add a placeholder from another screen.
      _load().then((_) {
        if (!mounted) return;
        _showPlaceholderForm().then((_) {
          if (mounted) Navigator.pop(context);
        });
      });
    } else {
      _load(openEditor: widget.editPlaceholder != null);
    }
  }

  Future<void> _load({bool openEditor = false}) async {
    final db = await DatabaseHelper.instance.database;
    _repository ??= BookRepository(db);
    final selectorResults = await Future.wait([
      _repository!.getUniversesWithPlaceholders(),
      _repository!.getLookupValues('author'),
      _repository!.getUniqueSagas(),
    ]);
    final universes = selectorResults[0] as List<String>;
    final authors =
        (selectorResults[1] as List<Map<String, dynamic>>)
            .map((author) => author['name'] as String)
            .toList();
    final sagas = selectorResults[2] as List<String>;
    _selectedUniverse ??= universes.isEmpty ? null : universes.first;
    final universe = _selectedUniverse;
    final results =
        universe == null
            ? <Object>[<Book>[], <UniversePlaceholder>[]]
            : await Future.wait([
              _repository!.getBooksByUniverse(universe),
              _repository!.getPlaceholdersByUniverse(universe),
            ]);
    if (!mounted) return;
    setState(() {
      _universes = universes;
      _authors = authors;
      _sagas = sagas;
      _books = results[0] as List<Book>;
      _placeholders = results[1] as List<UniversePlaceholder>;
      _loading = false;
    });
    if (openEditor && widget.editPlaceholder != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showPlaceholderForm(widget.editPlaceholder);
      });
    }
  }

  double? _seriesNumber(String? value) {
    if (value == null) return null;
    return double.tryParse(
      RegExp(r'\d+(?:\.\d+)?').firstMatch(value)?.group(0) ?? '',
    );
  }

  Set<String> get _sagasWithMissingEarlierEntries {
    final numbers = <String, Set<int>>{};
    for (final entry in <Object>[..._books, ..._placeholders]) {
      final saga =
          entry is Book ? entry.saga : (entry as UniversePlaceholder).saga;
      final nSaga =
          entry is Book ? entry.nSaga : (entry as UniversePlaceholder).nSaga;
      final number = _seriesNumber(nSaga);
      if (saga != null &&
          saga.isNotEmpty &&
          number != null &&
          number == number.round()) {
        numbers.putIfAbsent(saga, () => {}).add(number.toInt());
      }
    }
    return {
      for (final entry in numbers.entries)
        if (entry.value.isNotEmpty &&
            entry.value.reduce((a, b) => a > b ? a : b) > 1 &&
            !entry.value.contains(1))
          entry.key,
    };
  }

  InputDecoration _fieldDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontFamily: 'Manrope', color: _kSub),
      prefixIcon:
          icon == null ? null : Icon(icon, color: _kSecondary, size: 20),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  Widget _formSectionLabel(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 17, color: _kSecondary),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: _kSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPlaceholderForm([UniversePlaceholder? placeholder]) async {
    final l10n = AppLocalizations.of(context)!;
    final title = TextEditingController(text: placeholder?.title);
    final author = TextEditingController(text: placeholder?.author);
    final saga = TextEditingController(text: placeholder?.saga);
    final nSaga = TextEditingController(text: placeholder?.nSaga);
    final universe = TextEditingController(
      text: placeholder?.sagaUniverse ?? _selectedUniverse,
    );
    final order = TextEditingController(
      text: placeholder?.orderWithinUniverse?.toString(),
    );
    final notes = TextEditingController(text: placeholder?.notes);
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder:
          (context) => _withManropeFont(
            context,
            Dialog(
              backgroundColor: _kBg,
              surfaceTintColor: Colors.transparent,
              clipBehavior: Clip.antiAlias,
              elevation: 24,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 560,
                  maxHeight: 760,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: MediaQuery.sizeOf(context).height * 0.86,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 12, 16),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _kPrimary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(
                                placeholder == null
                                    ? Icons.add
                                    : Icons.edit_outlined,
                                color: _kPrimary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    placeholder == null
                                        ? l10n.add_placeholder
                                        : l10n.edit_placeholder,
                                    style: const TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: _kPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    l10n.universe_placeholders_subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 12,
                                      color: _kSub,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context, false),
                              icon: const Icon(Icons.close, color: _kSub),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: _kBorder),
                      Expanded(
                        child: Form(
                          key: formKey,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 12,
                              children: [
                                _formSectionLabel(
                                  Icons.menu_book_outlined,
                                  l10n.placeholder_book,
                                ),
                                TextFormField(
                                  controller: title,
                                  autofocus: placeholder == null,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  decoration: _fieldDecoration(
                                    l10n.filter_title,
                                    icon: Icons.menu_book_outlined,
                                  ),
                                  validator:
                                      (value) =>
                                          value == null || value.trim().isEmpty
                                              ? l10n.placeholder_title_required
                                              : null,
                                ),
                                ChipAutocompleteField(
                                  labelText: l10n.author,
                                  suggestions: _authors,
                                  initialValues:
                                      author.text.isEmpty ? [] : [author.text],
                                  hintText: l10n.search_or_add_author,
                                  maxSelections: 1,
                                  onChanged:
                                      (values) =>
                                          author.text =
                                              values.isNotEmpty
                                                  ? values.first
                                                  : '',
                                  decoration: _fieldDecoration(
                                    l10n.author,
                                    icon: Icons.person_outline,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _formSectionLabel(
                                  Icons.auto_awesome_outlined,
                                  l10n.saga_universe,
                                ),
                                AutocompleteTextField(
                                  controller: universe,
                                  labelText: l10n.saga_universe,
                                  suggestions: _universes,
                                  textCapitalization: TextCapitalization.words,
                                  onChanged: (_) => setState(() {}),
                                  onSelected: (_) => setState(() {}),
                                  validator:
                                      (value) =>
                                          value == null || value.trim().isEmpty
                                              ? l10n.required_field
                                              : null,
                                  decoration: _fieldDecoration(
                                    l10n.saga_universe,
                                    icon: Icons.auto_awesome_outlined,
                                  ),
                                ),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final sagaField = AutocompleteTextField(
                                      controller: saga,
                                      labelText: l10n.saga,
                                      suggestions: _sagas,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      onChanged: (_) => setState(() {}),
                                      onSelected: (_) => setState(() {}),
                                      decoration: _fieldDecoration(
                                        l10n.saga,
                                        icon:
                                            Icons.collections_bookmark_outlined,
                                      ),
                                    );
                                    final numberField = TextFormField(
                                      controller: nSaga,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: _fieldDecoration(
                                        l10n.saga_number,
                                        icon: Icons.tag,
                                      ),
                                    );
                                    if (constraints.maxWidth < 430) {
                                      return Column(
                                        spacing: 12,
                                        children: [sagaField, numberField],
                                      );
                                    }
                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      spacing: 12,
                                      children: [
                                        Expanded(child: sagaField),
                                        SizedBox(
                                          width: 150,
                                          child: numberField,
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                TextFormField(
                                  controller: order,
                                  keyboardType: TextInputType.number,
                                  decoration: _fieldDecoration(
                                    l10n.reading_order_position,
                                    icon: Icons.format_list_numbered,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _formSectionLabel(
                                  Icons.more_horiz,
                                  l10n.optional,
                                ),
                                TextFormField(
                                  controller: notes,
                                  minLines: 3,
                                  maxLines: 5,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  decoration: _fieldDecoration(
                                    l10n.notes,
                                    icon: Icons.notes_outlined,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          14,
                          20,
                          14 + MediaQuery.paddingOf(context).bottom,
                        ),
                        decoration: const BoxDecoration(
                          color: _kSurface,
                          border: Border(top: BorderSide(color: _kBorder)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                style: TextButton.styleFrom(
                                  foregroundColor: _kPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  l10n.cancel,
                                  style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  if (formKey.currentState!.validate()) {
                                    Navigator.pop(context, true);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _kPrimary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.check, size: 18),
                                label: Text(
                                  l10n.save,
                                  style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
    if (saved != true) return;
    if (mounted) setState(() => _loading = true);
    var coverUrl = placeholder?.coverUrl;
    try {
      final fetchedCover = await BookMetadataService().fetchCoverOnly(
        title: title.text.trim(),
        author: author.text.trim().isEmpty ? null : author.text.trim(),
      );
      if (fetchedCover?.trim().isNotEmpty == true) coverUrl = fetchedCover;
    } catch (error) {
      debugPrint('Error fetching placeholder cover: $error');
    }
    final value = UniversePlaceholder(
      placeholderId: placeholder?.placeholderId,
      sagaUniverse: universe.text.trim(),
      title: title.text.trim(),
      author: author.text.trim().isEmpty ? null : author.text.trim(),
      saga: saga.text.trim().isEmpty ? null : saga.text.trim(),
      nSaga: nSaga.text.trim().isEmpty ? null : nSaga.text.trim(),
      orderWithinUniverse: int.tryParse(order.text.trim()),
      coverUrl: coverUrl,
      notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
      createdAt: placeholder?.createdAt,
    );
    if (placeholder == null) {
      await _repository!.insertPlaceholder(value);
    } else {
      await _repository!.updatePlaceholder(value);
    }
    _selectedUniverse = value.sagaUniverse;
    await _load();
  }

  Future<void> _delete(UniversePlaceholder placeholder) async {
    await _repository!.deletePlaceholder(placeholder.placeholderId!);
    await _load();
  }

  Future<void> _promote(UniversePlaceholder placeholder) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => AddBookScreen(
              initialPlaceholder: placeholder,
              onBookSaved:
                  (bookId) => _repository!.promotePlaceholderToBook(
                    placeholder.placeholderId!,
                    bookId,
                  ),
            ),
      ),
    );
    await _load();
  }

  Widget _withManropeFont(BuildContext context, Widget child) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.apply(fontFamily: 'Manrope'),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!context.watch<RoleProvider>().isAdmin) {
      return const Scaffold(backgroundColor: _kBg);
    }
    final l10n = AppLocalizations.of(context)!;
    final entries = <({int? order, String title, String? saga, Object value})>[
      for (final book in _books)
        (
          order: book.orderWithinUniverse,
          title: book.name ?? l10n.unknown_title,
          saga: book.saga,
          value: book,
        ),
      for (final placeholder in _placeholders)
        (
          order: placeholder.orderWithinUniverse,
          title: placeholder.title,
          saga: placeholder.saga,
          value: placeholder,
        ),
    ]..sort((a, b) => (a.order ?? 999999).compareTo(b.order ?? 999999));
    final missing = _sagasWithMissingEarlierEntries;
    return _withManropeFont(
      context,
      Scaffold(
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
            l10n.universe_placeholders,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _kPrimary,
              letterSpacing: -0.5,
            ),
          ),
          centerTitle: true,
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: _kBorder),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showPlaceholderForm,
          backgroundColor: _kPrimary,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: const Icon(Icons.add),
          label: Text(
            l10n.add_placeholder,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body:
            _loading
                ? const Center(
                  child: CircularProgressIndicator(color: _kPrimary),
                )
                : SafeArea(
                  top: false,
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.universe_placeholders_subtitle,
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 14,
                                  color: _kSub,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 20),
                              DropdownButtonFormField<String>(
                                initialValue:
                                    _universes.contains(_selectedUniverse)
                                        ? _selectedUniverse
                                        : null,
                                isExpanded: true,
                                dropdownColor: _kSurface,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: _kPrimary,
                                ),
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _kText,
                                ),
                                decoration: _fieldDecoration(
                                  l10n.saga_universe,
                                  icon: Icons.auto_awesome_outlined,
                                ),
                                items: [
                                  for (final universe in _universes)
                                    DropdownMenuItem(
                                      value: universe,
                                      child: Text(
                                        universe,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                                onChanged: (value) {
                                  _selectedUniverse = value;
                                  _load();
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildSummaryCard(l10n),
                              if (missing.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _buildWarningCard(l10n, missing),
                              ],
                              const SizedBox(height: 24),
                              Text(
                                _selectedUniverse ?? l10n.saga_universe,
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: _kText,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                      if (entries.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(l10n),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 104),
                          sliver: SliverList.separated(
                            itemCount: entries.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(height: 10),
                            itemBuilder:
                                (context, index) =>
                                    _buildEntryCard(entries[index], l10n),
                          ),
                        ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildSummaryCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          _summaryValue('${_books.length}', l10n.in_library),
          Container(
            width: 1,
            height: 38,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: _kBorder,
          ),
          _summaryValue('${_placeholders.length}', l10n.not_in_library),
        ],
      ),
    );
  }

  Widget _summaryValue(String value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              color: _kSub,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard(AppLocalizations l10n, Set<String> missing) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7B86B)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFF8A5700)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.missing_earlier_entries(missing.join(', ')),
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B4608),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 8, 32, 120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _kPrimary.withValues(alpha: 0.1)),
              ),
              child: const Icon(
                Icons.auto_stories_outlined,
                size: 36,
                color: _kPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.no_books_in_universe,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _kText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.universe_placeholders_subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                color: _kSub,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryCard(
    ({int? order, String title, String? saga, Object value}) entry,
    AppLocalizations l10n,
  ) {
    final placeholder =
        entry.value is UniversePlaceholder
            ? entry.value as UniversePlaceholder
            : null;
    final isOwned = placeholder == null;
    return Opacity(
      opacity: isOwned ? 0.52 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOwned ? _kBorder : _kSecondary.withValues(alpha: 0.45),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
          leading: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color:
                  isOwned
                      ? _kSub.withValues(alpha: 0.08)
                      : _kPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isOwned ? _kBorder : _kPrimary.withValues(alpha: 0.18),
              ),
            ),
            child: Text(
              '${entry.order ?? '—'}',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isOwned ? _kSub : _kPrimary,
              ),
            ),
          ),
          title: Text(
            entry.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _kText,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (entry.saga?.isNotEmpty == true)
                  Text(
                    entry.saga!,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      color: _kSub,
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isOwned
                            ? _kSub.withValues(alpha: 0.08)
                            : _kSecondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isOwned ? l10n.in_library : l10n.not_in_library,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isOwned ? _kSub : _kSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          trailing:
              isOwned
                  ? const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Icon(Icons.check_circle_outline, color: _kSub),
                  )
                  : PopupMenuButton<String>(
                    color: _kSurface,
                    iconColor: _kPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    onSelected: (action) {
                      if (action == 'edit') {
                        _showPlaceholderForm(placeholder);
                      }
                      if (action == 'promote') {
                        _promote(placeholder);
                      }
                      if (action == 'delete') {
                        _delete(placeholder);
                      }
                    },
                    itemBuilder:
                        (_) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: _menuItem(
                              Icons.edit_outlined,
                              l10n.edit_placeholder,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'promote',
                            child: _menuItem(
                              Icons.library_add_outlined,
                              l10n.promote_to_library,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: _menuItem(
                              Icons.delete_outline,
                              l10n.delete_placeholder,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                  ),
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, {Color color = _kText}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:myrandomlibrary/config/v2_design_system.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/helpers/library_tool_fields.dart';
import 'package:myrandomlibrary/helpers/suggestion_engine.dart';
import 'package:myrandomlibrary/screens/new_ui/new_book_detail.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/providers/role_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_theme.dart';

class SmartSuggestionsScreen extends StatefulWidget {
  const SmartSuggestionsScreen({super.key});

  @override
  State<SmartSuggestionsScreen> createState() => _SmartSuggestionsScreenState();
}

class _SmartSuggestionsScreenState extends State<SmartSuggestionsScreen> {
  static const _rejectedSuggestionsKey = 'rejected_smart_suggestions';
  static Color get _kBg => V2Colors.background;
  static Color get _kPrimary => V2Colors.primary;
  static Color get _kSecondary => V2Colors.secondary;
  static Color get _kText => V2Colors.textPrimary;
  static Color get _kSubText => V2Colors.textSubtle;
  static Color get _kIconBg => V2Colors.chip;
  static Color get _kBorder => V2Colors.border;

  List<Suggestion> _suggestions = [];
  bool _isLoading = true;
  final Set<int> _expandedIndices = {};
  final Set<String> _rejectedIds = {};

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadRejectedSuggestions();
    await _generateSuggestions();
  }

  Future<void> _loadRejectedSuggestions() async {
    final prefs = await SharedPreferences.getInstance();
    _rejectedIds.addAll(prefs.getStringList(_rejectedSuggestionsKey) ?? []);
  }

  Future<void> _saveRejectedSuggestions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_rejectedSuggestionsKey, _rejectedIds.toList());
  }

  String _getFieldLabel(String key) =>
      LibraryToolFields.label(AppLocalizations.of(context)!, key);

  IconData _getFieldIcon(Suggestion suggestion) {
    switch (suggestion.kind) {
      case SuggestionKind.merge:
        return Icons.merge_type;
      case SuggestionKind.sagaNumbering:
        return Icons.format_list_numbered;
      case SuggestionKind.assign:
        return LibraryToolFields.icon(suggestion.field);
    }
  }

  String _title(Suggestion suggestion, AppLocalizations l10n) {
    final field = _getFieldLabel(suggestion.field);
    switch (suggestion.kind) {
      case SuggestionKind.merge:
        return l10n.merge_variants_title(
          suggestion.mergeFrom.map((v) => '"$v"').join(', '),
          suggestion.value,
          field,
        );
      case SuggestionKind.sagaNumbering:
        if (suggestion.value == SuggestionEngine.numberingMissing) {
          return l10n.saga_missing_number_title(
            suggestion.groupName,
            suggestion.bookIds.length,
          );
        }
        return l10n.saga_duplicate_number_title(
          suggestion.groupName,
          suggestion.value.substring(
            SuggestionEngine.numberingDuplicate.length + 1,
          ),
          suggestion.bookIds.length,
        );
      case SuggestionKind.assign:
        return l10n.apply_value_to_books(
          suggestion.value,
          field,
          suggestion.bookIds.length,
        );
    }
  }

  String _description(Suggestion suggestion, AppLocalizations l10n) {
    switch (suggestion.kind) {
      case SuggestionKind.merge:
        return l10n.suggestion_merge_desc(suggestion.bookIds.length);
      case SuggestionKind.sagaNumbering:
        return suggestion.value == SuggestionEngine.numberingMissing
            ? l10n.suggestion_saga_numbering_desc
            : l10n.suggestion_saga_duplicate_desc;
      case SuggestionKind.assign:
        if (suggestion.groupName.isEmpty) return suggestion.description;
        final field = _getFieldLabel(suggestion.field);
        return suggestion.groupIsSaga
            ? l10n.suggestion_saga_peers_desc(
              suggestion.dominantCount,
              suggestion.groupSize,
              suggestion.groupName,
              suggestion.value,
              field,
            )
            : l10n.suggestion_author_peers_desc(
              suggestion.dominantCount,
              suggestion.groupSize,
              suggestion.groupName,
              suggestion.value,
              field,
            );
    }
  }

  void _openBook(int bookId) {
    final provider = Provider.of<BookProvider?>(context, listen: false);
    final matches = provider?.allBooks.where((b) => b.bookId == bookId);
    if (matches == null || matches.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewBookDetailScreen(book: matches.first),
      ),
    ).then((_) {
      if (mounted) _generateSuggestions();
    });
  }

  Future<void> _generateSuggestions() async {
    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<BookProvider?>(context, listen: false);
      if (provider != null) {
        final suggestions = SuggestionEngine.generateSuggestions(
          provider.allBooks,
        );
        setState(() {
          _suggestions =
              suggestions.where((s) => !_rejectedIds.contains(s.id)).toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error generating suggestions: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _applySuggestion(int index) async {
    final suggestion = _suggestions[index];
    if (suggestion.isWarning) return;
    final provider = Provider.of<BookProvider?>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);
      if (suggestion.kind == SuggestionKind.merge) {
        await repository.mergeFieldValues(
          suggestion.field,
          suggestion.mergeFrom,
          suggestion.value,
        );
      } else {
        await repository.updateBooksField(
          suggestion.bookIds,
          suggestion.field,
          suggestion.value,
        );
      }

      await provider?.loadBooks();

      if (_rejectedIds.remove(suggestion.id)) {
        await _saveRejectedSuggestions();
      }

      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.suggestion_applied),
          backgroundColor: AppTheme.notificationColor,
        ),
      );
      setState(() {
        suggestion.isApplied = true;
      });
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('${l10n.error}: $e'),
          backgroundColor: colorScheme.error,
        ),
      );
    }
  }

  Future<void> _rejectSuggestion(int index) async {
    final suggestion = _suggestions[index];

    setState(() {
      _suggestions.removeAt(index);
      _expandedIndices.clear();
    });

    _rejectedIds.add(suggestion.id);
    await _saveRejectedSuggestions();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.suggestion_rejected),
        backgroundColor: AppTheme.notificationColor,
      ),
    );
  }

  Future<void> _acceptAll() async {
    final pending = _suggestions.where(_isPending).toList();

    if (pending.isEmpty) return;

    for (int i = 0; i < _suggestions.length; i++) {
      if (_isPending(_suggestions[i])) {
        await _applySuggestion(i);
      }
    }
  }

  bool _isPending(Suggestion s) =>
      !s.isWarning && !s.isApplied && !s.isRejected;

  @override
  Widget build(BuildContext context) {
    if (!context.watch<RoleProvider>().isAdmin) return const Scaffold();
    final l10n = AppLocalizations.of(context)!;

    final pendingCount = _suggestions.where(_isPending).length;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(
          l10n.smart_suggestions,
          style: TextStyle(
            fontFamily: V2Typography.family,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _kText,
          ),
        ),
        actions: [
          if (pendingCount > 1)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: _acceptAll,
                style: TextButton.styleFrom(foregroundColor: _kPrimary),
                icon: const Icon(Icons.done_all, size: 18),
                label: Text(
                  l10n.accept_all,
                  style: const TextStyle(
                    fontFamily: V2Typography.family,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child:
            _isLoading
                ? _buildLoadingState(l10n)
                : _suggestions.isEmpty
                ? _buildEmptyState(l10n)
                : _buildSuggestionsList(),
      ),
    );
  }

  Widget _buildLoadingState(AppLocalizations l10n) {
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
            l10n.generating_suggestions,
            style: TextStyle(
              fontFamily: V2Typography.family,
              fontSize: 14,
              color: _kSubText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
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
              l10n.no_suggestions,
              style: TextStyle(
                fontFamily: V2Typography.family,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _kText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    final l10n = AppLocalizations.of(context)!;

    final pendingCount = _suggestions.where(_isPending).length;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorder.withValues(alpha: 0.55)),
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
                  child: Icon(Icons.auto_fix_high, color: _kPrimary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.n_suggestions_found(_suggestions.length),
                    style: TextStyle(
                      fontFamily: V2Typography.family,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _kText,
                    ),
                  ),
                ),
                if (pendingCount == 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      l10n.all_suggestions_processed,
                      style: TextStyle(
                        fontFamily: V2Typography.family,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Suggestions list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            itemCount: _suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = _suggestions[index];
              final isExpanded = _expandedIndices.contains(index);

              return _buildSuggestionCard(suggestion, index, isExpanded);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionCard(
    Suggestion suggestion,
    int index,
    bool isExpanded,
  ) {
    final l10n = AppLocalizations.of(context)!;

    final statusColor = suggestion.isApplied ? _kPrimary : _kSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:
            suggestion.isApplied
                ? _kPrimary.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              suggestion.isApplied
                  ? _kPrimary.withValues(alpha: 0.18)
                  : _kBorder.withValues(alpha: 0.65),
        ),
        boxShadow:
            suggestion.isApplied
                ? null
                : const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    suggestion.isApplied
                        ? Icons.check_rounded
                        : _getFieldIcon(suggestion),
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _title(suggestion, l10n),
                        style: TextStyle(
                          fontFamily: V2Typography.family,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: _kText,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _badgeColor(suggestion).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          suggestion.kind == SuggestionKind.merge
                              ? l10n.spelling_variants
                              : suggestion.isWarning
                              ? l10n.needs_review
                              : l10n.suggestion_confidence(
                                suggestion.confidence,
                              ),
                          style: TextStyle(
                            fontFamily: V2Typography.family,
                            fontSize: 10,
                            color: _badgeColor(suggestion),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  color: _kSubText,
                  icon: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  onPressed: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedIndices.remove(index);
                      } else {
                        _expandedIndices.add(index);
                      }
                    });
                  },
                ),
              ],
            ),
          ),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _description(suggestion, l10n),
              style: TextStyle(
                fontFamily: V2Typography.family,
                fontSize: 12,
                color: _kSubText,
                height: 1.45,
              ),
            ),
          ),

          // Expanded: show affected books
          if (isExpanded)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kIconBg.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.affected_books.toUpperCase(),
                    style: TextStyle(
                      fontFamily: V2Typography.family,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 0.7,
                      color: _kSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < suggestion.bookNames.length; i++)
                    InkWell(
                      onTap:
                          i < suggestion.bookIds.length
                              ? () => _openBook(suggestion.bookIds[i])
                              : null,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.menu_book_outlined,
                              size: 14,
                              color: _kSecondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                suggestion.bookNames[i],
                                style: TextStyle(
                                  fontFamily: V2Typography.family,
                                  fontSize: 12,
                                  color: _kText,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: _kSubText,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Action buttons
          if (!suggestion.isApplied && !suggestion.isRejected)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => _rejectSuggestion(index),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kSecondary,
                      side: BorderSide(color: _kBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      suggestion.isWarning ? l10n.dismiss : l10n.reject,
                      style: const TextStyle(
                        fontFamily: V2Typography.family,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (suggestion.isWarning)
                    FilledButton.icon(
                      onPressed: () {
                        setState(() => _expandedIndices.add(index));
                        if (suggestion.bookIds.length == 1) {
                          _openBook(suggestion.bookIds.first);
                        }
                      },
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: Text(l10n.review_books),
                      style: FilledButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: V2Colors.onPrimary,
                        textStyle: const TextStyle(
                          fontFamily: V2Typography.family,
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    )
                  else
                    FilledButton.icon(
                      onPressed: () => _applySuggestion(index),
                      icon: const Icon(Icons.check, size: 16),
                      label: Text(l10n.accept),
                      style: FilledButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: V2Colors.onPrimary,
                        textStyle: const TextStyle(
                          fontFamily: V2Typography.family,
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                ],
              ),
            ),

          if (suggestion.isApplied)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: _kPrimary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    l10n.suggestion_applied,
                    style: TextStyle(
                      fontFamily: V2Typography.family,
                      fontSize: 12,
                      color: _kPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _badgeColor(Suggestion suggestion) {
    if (suggestion.isWarning) return const Color(0xFF8A5A22);
    return _confidenceColor(suggestion.confidence);
  }

  Color _confidenceColor(int confidence) {
    if (confidence >= 90) return _kPrimary;
    if (confidence >= 80) return _kSecondary;
    if (confidence >= 70) return const Color(0xFF8A5A22);
    return const Color(0xFFA13A3A);
  }
}

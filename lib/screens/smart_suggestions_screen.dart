import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/helpers/suggestion_engine.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/providers/role_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SmartSuggestionsScreen extends StatefulWidget {
  const SmartSuggestionsScreen({super.key});

  @override
  State<SmartSuggestionsScreen> createState() => _SmartSuggestionsScreenState();
}

class _SmartSuggestionsScreenState extends State<SmartSuggestionsScreen> {
  static const _rejectedSuggestionsKey = 'rejected_smart_suggestions';
  static const _kBg = Color(0xFFFDF8F6);
  static const _kPrimary = Color(0xFF43102B);
  static const _kSecondary = Color(0xFF894B67);
  static const _kText = Color(0xFF1C1B1A);
  static const _kSubText = Color(0xFF5F5E5C);
  static const _kIconBg = Color(0xFFF2EDEB);
  static const _kBorder = Color(0xFFD5C2C7);

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
    final provider = Provider.of<BookProvider?>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);
      await repository.updateBooksField(
        suggestion.bookIds,
        suggestion.field,
        suggestion.value,
      );

      await provider?.loadBooks();

      if (_rejectedIds.remove(suggestion.id)) {
        await _saveRejectedSuggestions();
      }

      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.suggestion_applied),
          backgroundColor: colorScheme.primary,
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
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  Future<void> _acceptAll() async {
    final pending =
        _suggestions.where((s) => !s.isApplied && !s.isRejected).toList();

    if (pending.isEmpty) return;

    for (int i = 0; i < _suggestions.length; i++) {
      if (!_suggestions[i].isApplied && !_suggestions[i].isRejected) {
        await _applySuggestion(i);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!context.watch<RoleProvider>().isAdmin) return const Scaffold();
    final l10n = AppLocalizations.of(context)!;

    final pendingCount =
        _suggestions.where((s) => !s.isApplied && !s.isRejected).length;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(
          l10n.smart_suggestions,
          style: const TextStyle(
            fontFamily: 'Manrope',
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
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
      body:
          _isLoading
              ? _buildLoadingState(l10n)
              : _suggestions.isEmpty
              ? _buildEmptyState(l10n)
              : _buildSuggestionsList(),
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
            l10n.generating_suggestions,
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
              l10n.no_suggestions,
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
    );
  }

  Widget _buildSuggestionsList() {
    final l10n = AppLocalizations.of(context)!;

    final pendingCount =
        _suggestions.where((s) => !s.isApplied && !s.isRejected).length;

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
                  decoration: const BoxDecoration(
                    color: _kIconBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_fix_high,
                    color: _kPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.n_suggestions_found(_suggestions.length),
                    style: const TextStyle(
                      fontFamily: 'Manrope',
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
                      style: const TextStyle(
                        fontFamily: 'Manrope',
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
                        : _getFieldIcon(suggestion.field),
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
                        l10n.apply_value_to_books(
                          suggestion.value,
                          _getFieldLabel(suggestion.field),
                          suggestion.bookIds.length,
                        ),
                        style: const TextStyle(
                          fontFamily: 'Manrope',
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
                          color: _confidenceColor(
                            suggestion.confidence,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          l10n.suggestion_confidence(suggestion.confidence),
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 10,
                            color: _confidenceColor(suggestion.confidence),
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
              suggestion.description,
              style: const TextStyle(
                fontFamily: 'Manrope',
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
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 0.7,
                      color: _kSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...suggestion.bookNames.map(
                    (name) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.menu_book_outlined,
                            size: 14,
                            color: _kSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 12,
                                color: _kText,
                              ),
                            ),
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
                      side: const BorderSide(color: _kBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      l10n.reject,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _applySuggestion(index),
                    icon: const Icon(Icons.check, size: 16),
                    label: Text(l10n.accept),
                    style: FilledButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontFamily: 'Manrope',
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
                  const Icon(Icons.check_circle, color: _kPrimary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    l10n.suggestion_applied,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
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

  Color _confidenceColor(int confidence) {
    if (confidence >= 90) return _kPrimary;
    if (confidence >= 80) return _kSecondary;
    if (confidence >= 70) return const Color(0xFF8A5A22);
    return const Color(0xFFA13A3A);
  }
}

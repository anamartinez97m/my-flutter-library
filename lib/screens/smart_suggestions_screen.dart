import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/helpers/suggestion_engine.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:provider/provider.dart';

class SmartSuggestionsScreen extends StatefulWidget {
  const SmartSuggestionsScreen({super.key});

  @override
  State<SmartSuggestionsScreen> createState() => _SmartSuggestionsScreenState();
}

class _SmartSuggestionsScreenState extends State<SmartSuggestionsScreen> {
  List<Suggestion> _suggestions = [];
  bool _isLoading = true;
  final Set<int> _expandedIndices = {};

  @override
  void initState() {
    super.initState();
    _generateSuggestions();
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
          _suggestions = suggestions;
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

  void _rejectSuggestion(int index) {
    setState(() {
      _suggestions[index].isRejected = true;
    });

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
    final l10n = AppLocalizations.of(context)!;

    final pendingCount =
        _suggestions.where((s) => !s.isApplied && !s.isRejected).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.smart_suggestions),
        actions: [
          if (pendingCount > 1)
            TextButton.icon(
              onPressed: _acceptAll,
              icon: const Icon(Icons.done_all),
              label: Text(l10n.accept_all),
            ),
        ],
      ),
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      l10n.generating_suggestions,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
              : _suggestions.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        l10n.no_suggestions,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              )
              : _buildSuggestionsList(),
    );
  }

  Widget _buildSuggestionsList() {
    final l10n = AppLocalizations.of(context)!;

    final pendingCount =
        _suggestions.where((s) => !s.isApplied && !s.isRejected).length;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(
            context,
          ).colorScheme.primaryContainer.withValues(alpha: 0.3),
          child: Row(
            children: [
              Icon(
                Icons.auto_fix_high,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.n_suggestions_found(_suggestions.length),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              if (pendingCount == 0)
                Chip(
                  label: Text(
                    l10n.all_suggestions_processed,
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.5),
                ),
            ],
          ),
        ),

        // Suggestions list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
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

    Color cardColor;
    if (suggestion.isApplied) {
      cardColor = Theme.of(
        context,
      ).colorScheme.primaryContainer.withValues(alpha: 0.2);
    } else if (suggestion.isRejected) {
      cardColor = Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    } else {
      cardColor = Theme.of(context).colorScheme.surface;
    }

    return Card(
      elevation: suggestion.isApplied || suggestion.isRejected ? 0 : 2,
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  suggestion.isApplied
                      ? Theme.of(context).colorScheme.primary
                      : suggestion.isRejected
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : Theme.of(context).colorScheme.primary,
              child: Icon(
                suggestion.isApplied
                    ? Icons.check
                    : suggestion.isRejected
                    ? Icons.close
                    : _getFieldIcon(suggestion.field),
                color: Theme.of(context).colorScheme.onPrimary,
                size: 20,
              ),
            ),
            title: Text(
              l10n.apply_value_to_books(
                suggestion.value,
                _getFieldLabel(suggestion.field),
                suggestion.bookIds.length,
              ),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                decoration:
                    suggestion.isRejected ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _confidenceColor(
                      suggestion.confidence,
                    ).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l10n.suggestion_confidence(suggestion.confidence),
                    style: TextStyle(
                      fontSize: 11,
                      color: _confidenceColor(suggestion.confidence),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
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
          ),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              suggestion.description,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

          // Expanded: show affected books
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.affected_books,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...suggestion.bookNames.map(
                    (name) => Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 2),
                      child: Row(
                        children: [
                          Icon(
                            Icons.book,
                            size: 14,
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(fontSize: 13),
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _rejectSuggestion(index),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    child: Text(l10n.reject),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _applySuggestion(index),
                    icon: const Icon(Icons.check, size: 16),
                    label: Text(l10n.accept),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),

          if (suggestion.isApplied)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.suggestion_applied,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
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
    final cs = Theme.of(context).colorScheme;
    if (confidence >= 90) return cs.primary;
    if (confidence >= 80) return cs.primary.withValues(alpha: 0.8);
    if (confidence >= 70) return cs.secondary;
    return cs.error;
  }
}

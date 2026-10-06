import 'dart:async';

import 'package:flutter/material.dart';
import 'package:myrandomlibrary/config/v2_design_system.dart';
import 'package:myrandomlibrary/discovery/book_discovery_service.dart';
import 'package:myrandomlibrary/discovery/catalog/concept_catalog.dart';
import 'package:myrandomlibrary/discovery/model/discovery_result.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/widgets/discovery_result_card.dart';
import 'package:provider/provider.dart';

const _kPrimary = V2Colors.primary;
const _kSub = V2Colors.textSecondary;
const _kBorder = V2Colors.border;
final _kChipBg = V2Colors.chip.withValues(alpha: 0.5);
final _kChipBorder = V2Colors.border.withValues(alpha: 0.5);

/// "What are you in the mood for?" — free-text theme search over the user's
/// own library, rendered inline as a card.
class ThemeDiscoveryCard extends StatefulWidget {
  final BookDiscoveryService? service;

  /// Narrows the library before searching (e.g. saga reading order).
  final List<Book> Function(List<Book> books)? bookFilter;

  const ThemeDiscoveryCard({super.key, this.service, this.bookFilter});

  @override
  State<ThemeDiscoveryCard> createState() => _ThemeDiscoveryCardState();
}

class _ThemeDiscoveryCardState extends State<ThemeDiscoveryCard> {
  static const _debounce = Duration(milliseconds: 300);
  static const _pageSize = 5;

  late final BookDiscoveryService _service =
      widget.service ?? BookDiscoveryService();
  final TextEditingController _controller = TextEditingController();
  Timer? _debounceTimer;
  String _query = '';
  int _visibleCount = _pageSize;
  bool _showLoose = false;

  String? _cachedQuery;
  List<Book>? _cachedBooks;
  DiscoveryResults _cachedResults = DiscoveryResults.empty;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () => _setQuery(value));
    setState(() {});
  }

  void _setQuery(String value) {
    if (!mounted) return;
    setState(() {
      _query = value.trim();
      _visibleCount = _pageSize;
      _showLoose = false;
    });
  }

  void _fill(String text) {
    _debounceTimer?.cancel();
    _controller.text = text;
    _controller.selection = TextSelection.collapsed(offset: text.length);
    _setQuery(text);
  }

  DiscoveryResults _results(List<Book> books) {
    if (_query != _cachedQuery || !identical(books, _cachedBooks)) {
      _cachedQuery = _query;
      _cachedBooks = books;
      _cachedResults = _service.search(
        _query,
        widget.bookFilter?.call(books) ?? books,
      );
    }
    return _cachedResults;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final books = context.watch<BookProvider>().allBooks;
    final results = _results(books);
    final searched =
        _query.length >= BookDiscoveryService.minQueryLength &&
        _controller.text.trim() == _query;

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: _kPrimary, size: 34),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.theme_discovery_title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              l10n.theme_discovery_subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _kSub, height: 1.4),
            ),
          ),
          const SizedBox(height: 28),
          _buildField(l10n),
          const SizedBox(height: 12),
          if (!searched) ...[
            Text(
              l10n.theme_discovery_helper,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: _kSub),
            ),
            const SizedBox(height: 12),
            _buildSuggestions(l10n),
          ] else if (results.isEmpty) ...[
            Text(
              l10n.theme_discovery_no_results(_query),
              style: const TextStyle(fontSize: 14, color: _kPrimary),
            ),
            const SizedBox(height: 12),
            _buildSuggestions(l10n),
          ] else
            ..._buildResults(l10n, results),
        ],
      ),
    );
  }

  Widget _buildField(AppLocalizations l10n) {
    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      onSubmitted: (value) {
        _debounceTimer?.cancel();
        _setQuery(value);
      },
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        labelText: l10n.theme_discovery_title,
        hintText: l10n.theme_discovery_hint,
        prefixIcon: const Icon(Icons.search, color: _kPrimary),
        suffixIcon:
            _controller.text.isEmpty
                ? null
                : IconButton(
                  icon: const Icon(Icons.clear, color: _kPrimary),
                  tooltip:
                      MaterialLocalizations.of(context).deleteButtonTooltip,
                  onPressed: () => _fill(''),
                ),
        filled: true,
        fillColor: V2Colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kPrimary),
        ),
      ),
    );
  }

  Widget _buildSuggestions(AppLocalizations l10n) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final suggestions = ConceptCatalog.instance.suggestions;
    return Column(
      children: [
        Text(
          l10n.theme_discovery_suggestions,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: _kSub),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final concept in suggestions)
              ActionChip(
                label: Text(
                  '${concept.emoji} ${concept.localizedName(languageCode)}',
                  style: const TextStyle(fontSize: 13, color: _kPrimary),
                ),
                backgroundColor: _kChipBg,
                side: BorderSide(color: _kChipBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(V2Radii.cardLarge),
                ),
                onPressed: () => _fill(concept.localizedName(languageCode)),
              ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildResults(AppLocalizations l10n, DiscoveryResults results) {
    final visible = results.main.take(_visibleCount).toList();
    return [
      if (results.main.isNotEmpty) ...[
        Text(
          l10n.theme_discovery_results_count(results.main.length),
          style: const TextStyle(fontSize: 12, color: _kSub),
        ),
        const SizedBox(height: 12),
        for (final result in visible) DiscoveryResultCard(result: result),
        if (visible.length < results.main.length)
          Center(
            child: TextButton(
              onPressed: () => setState(() => _visibleCount += _pageSize),
              child: Text(
                l10n.theme_discovery_show_more,
                style: const TextStyle(color: _kPrimary),
              ),
            ),
          ),
      ],
      if (results.looselyRelated.isNotEmpty) ...[
        InkWell(
          onTap: () => setState(() => _showLoose = !_showLoose),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.theme_discovery_loosely_related(
                      results.looselyRelated.length,
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                  ),
                ),
                Icon(
                  _showLoose ? Icons.expand_less : Icons.expand_more,
                  color: _kPrimary,
                ),
              ],
            ),
          ),
        ),
        if (_showLoose)
          for (final result in results.looselyRelated)
            DiscoveryResultCard(result: result),
      ],
    ];
  }
}

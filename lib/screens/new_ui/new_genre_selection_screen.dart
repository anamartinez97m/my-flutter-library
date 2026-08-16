import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';

const _kBg = Color(0xFFFDF8F6);
const _kPrimary = Color(0xFF43102B);
const _kSub = Color(0xFF514348);
const _kBorder = Color(0xFFD5C2C7);
const _kChipBg = Color(0xFFF2EDEB);
const _kChipBorder = Color(0x80D5C2C7);
const _kChipSelected = Color(0xE643102B);

/// Result returned by [NewGenreSelectionScreen] when the user taps Apply.
class GenreSelectionResult {
  final List<String> selected;
  final bool useAndLogic;
  const GenreSelectionResult({
    required this.selected,
    required this.useAndLogic,
  });
}

class NewGenreSelectionScreen extends StatefulWidget {
  final List<String> allGenres;
  final List<String> popularGenres;
  final List<String> initialSelected;
  final bool initialUseAndLogic;

  const NewGenreSelectionScreen({
    super.key,
    required this.allGenres,
    required this.popularGenres,
    required this.initialSelected,
    required this.initialUseAndLogic,
  });

  @override
  State<NewGenreSelectionScreen> createState() =>
      _NewGenreSelectionScreenState();
}

class _NewGenreSelectionScreenState extends State<NewGenreSelectionScreen> {
  late List<String> _selected;
  late bool _useAndLogic;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.initialSelected);
    _useAndLogic = widget.initialUseAndLogic;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggle(String genre) {
    setState(() {
      if (_selected.contains(genre)) {
        _selected.remove(genre);
      } else {
        _selected.add(genre);
      }
    });
  }

  Map<String, List<String>> _groupedGenres(List<String> genres) {
    final sorted = List<String>.from(genres)..sort();
    final groups = <String, List<String>>{};
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    for (int i = 0; i < letters.length; i += 3) {
      final end = (i + 3 > letters.length) ? letters.length : i + 3;
      final rangeLetters = letters.substring(i, end);
      final label =
          rangeLetters.length > 1
              ? '${rangeLetters[0]} - ${rangeLetters[rangeLetters.length - 1]}'
              : rangeLetters;
      final items =
          sorted.where((g) {
            final first = g.isNotEmpty ? g[0].toUpperCase() : '';
            return rangeLetters.contains(first);
          }).toList();
      if (items.isNotEmpty) groups[label] = items;
    }
    final other =
        sorted.where((g) {
          final first = g.isNotEmpty ? g[0].toUpperCase() : '';
          return !letters.contains(first);
        }).toList();
    if (other.isNotEmpty) groups['#'] = other;
    return groups;
  }

  Widget _chip(String label) {
    final selected = _selected.contains(label);
    return GestureDetector(
      onTap: () => _toggle(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _kChipSelected : _kChipBg,
          borderRadius: BorderRadius.circular(9999),
          border: selected ? null : Border.all(color: _kChipBorder),
          boxShadow:
              selected
                  ? const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 1,
                      offset: Offset(0, 1),
                    ),
                  ]
                  : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.26,
                color: selected ? Colors.white : _kSub,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 4),
              const Icon(Icons.check, size: 12, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionHeading(String text) => Container(
    padding: const EdgeInsets.only(bottom: 9),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0x1A27231E))),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: _kPrimary,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filteredPopular =
        widget.popularGenres
            .where((g) => g.toLowerCase().contains(_query.toLowerCase()))
            .toList();
    final filteredAll =
        widget.allGenres
            .where((g) => g.toLowerCase().contains(_query.toLowerCase()))
            .toList();
    final grouped = _groupedGenres(filteredAll);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: const BoxDecoration(
                color: _kBg,
                border: Border(bottom: BorderSide(color: _kBorder)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: _kPrimary,
                      size: 18,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    l10n.select_genres,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _kPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed:
                        () => Navigator.pop(
                          context,
                          GenreSelectionResult(
                            selected: _selected,
                            useAndLogic: _useAndLogic,
                          ),
                        ),
                    child: Text(
                      l10n.apply,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                        letterSpacing: 0.26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: l10n.search_genres,
                      hintStyle: const TextStyle(color: Color(0xFF5F5E5C)),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: _kSub,
                        size: 18,
                      ),
                      suffixIcon:
                          _query.isNotEmpty
                              ? IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: _kSub,
                                ),
                                onPressed:
                                    () => setState(() {
                                      _searchController.clear();
                                      _query = '';
                                    }),
                              )
                              : null,
                      filled: true,
                      fillColor: const Color(0xFFE2DFDC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                    ),
                  ),
                  if (filteredPopular.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _sectionHeading(l10n.popular_genres),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: filteredPopular.map(_chip).toList(),
                    ),
                  ],
                  if (grouped.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _sectionHeading(l10n.all_genres),
                    const SizedBox(height: 16),
                    for (final entry in grouped.entries) ...[
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary,
                          letterSpacing: 0.65,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: entry.value.map(_chip).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                  if (filteredPopular.isEmpty && grouped.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          l10n.no_books_match_filters,
                          style: const TextStyle(color: _kSub),
                        ),
                      ),
                    ),
                  if (_selected.length > 1) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _useAndLogic
                                ? l10n.and_all_genres
                                : l10n.or_any_genre,
                            style: const TextStyle(
                              fontSize: 11,
                              color: _kSub,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: _kBorder),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ToggleButtons(
                            isSelected: [_useAndLogic, !_useAndLogic],
                            onPressed:
                                (i) =>
                                    setState(() => _useAndLogic = i == 0),
                            borderRadius: BorderRadius.circular(8),
                            constraints: const BoxConstraints(
                              minHeight: 32,
                              minWidth: 40,
                            ),
                            children: const [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  'AND',
                                  style: TextStyle(fontSize: 10),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  'OR',
                                  style: TextStyle(fontSize: 10),
                                ),
                              ),
                            ],
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
    );
  }
}

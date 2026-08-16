import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';

const _kBg = Color(0xFFFDF8F6);
const _kPrimary = Color(0xFF43102B);
const _kSub = Color(0xFF514348);
const _kBorder = Color(0xFFD5C2C7);
const _kChipBg = Color(0xFFF2EDEB);
const _kChipBorder = Color(0x80D5C2C7);
const _kChipSelected = Color(0xE643102B);

/// Result returned by [NewOptionSelectionScreen] when the user taps Apply.
class OptionSelectionResult {
  final List<String> selected;
  const OptionSelectionResult({required this.selected});
}

/// Generic full-list picker used by the "See all" links on the random
/// screen filters (Format, Place, Editorial, Publication year, Author...).
class NewOptionSelectionScreen extends StatefulWidget {
  final String title;
  final String searchHint;
  final String popularLabel;
  final String allLabel;
  final String anyLabel;
  final List<String> allOptions;
  final List<String> popularOptions;
  final List<String> initialSelected;
  final bool multiSelect;
  final String Function(String)? labelBuilder;

  const NewOptionSelectionScreen({
    super.key,
    required this.title,
    required this.searchHint,
    required this.popularLabel,
    required this.allLabel,
    required this.anyLabel,
    required this.allOptions,
    required this.popularOptions,
    required this.initialSelected,
    this.multiSelect = false,
    this.labelBuilder,
  });

  @override
  State<NewOptionSelectionScreen> createState() =>
      _NewOptionSelectionScreenState();
}

class _NewOptionSelectionScreenState extends State<NewOptionSelectionScreen> {
  static const int _maxGroupSize = 10;

  late List<String> _selected;
  final _searchController = TextEditingController();
  String _query = '';
  final Set<String> _collapsedGroups = {};

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.initialSelected);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggle(String option) {
    setState(() {
      if (widget.multiSelect) {
        if (_selected.contains(option)) {
          _selected.remove(option);
        } else {
          _selected.add(option);
        }
      } else {
        _selected = _selected.contains(option) ? [] : [option];
      }
    });
  }

  String _labelOf(String option) =>
      widget.labelBuilder != null ? widget.labelBuilder!(option) : option;

  Map<String, List<String>> _groupedOptions(List<String> options) {
    final sorted = List<String>.from(options)
      ..sort((a, b) => _labelOf(a).compareTo(_labelOf(b)));
    final groups = <String, List<String>>{};
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    for (int i = 0; i < letters.length; i += 3) {
      final end = (i + 3 > letters.length) ? letters.length : i + 3;
      final rangeLetters = letters.substring(i, end);
      final items =
          sorted.where((o) {
            final label = _labelOf(o);
            final first = label.isNotEmpty ? label[0].toUpperCase() : '';
            return rangeLetters.contains(first);
          }).toList();
      if (items.isEmpty) continue;
      if (rangeLetters.length > 1 && items.length > _maxGroupSize) {
        for (final letter in rangeLetters.split('')) {
          final letterItems =
              items
                  .where((o) => _labelOf(o)[0].toUpperCase() == letter)
                  .toList();
          if (letterItems.isNotEmpty) groups[letter] = letterItems;
        }
      } else {
        final label =
            rangeLetters.length > 1
                ? '${rangeLetters[0]} - ${rangeLetters[rangeLetters.length - 1]}'
                : rangeLetters;
        groups[label] = items;
      }
    }
    final other =
        sorted.where((o) {
          final label = _labelOf(o);
          final first = label.isNotEmpty ? label[0].toUpperCase() : '';
          return !letters.contains(first);
        }).toList();
    if (other.isNotEmpty) groups['#'] = other;
    return groups;
  }

  Widget _groupHeader(String label) {
    final collapsed = _collapsedGroups.contains(label);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap:
          () => setState(() {
            if (collapsed) {
              _collapsedGroups.remove(label);
            } else {
              _collapsedGroups.add(label);
            }
          }),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kPrimary,
              letterSpacing: 0.65,
            ),
          ),
          Icon(
            collapsed ? Icons.keyboard_arrow_right : Icons.keyboard_arrow_down,
            size: 18,
            color: _kPrimary,
          ),
        ],
      ),
    );
  }

  Widget _chip(String option) {
    final selected = _selected.contains(option);
    return GestureDetector(
      onTap: () => _toggle(option),
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
              _labelOf(option),
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
        widget.popularOptions
            .where(
              (o) => _labelOf(o).toLowerCase().contains(_query.toLowerCase()),
            )
            .toList();
    final filteredAll =
        widget.allOptions
            .where(
              (o) => _labelOf(o).toLowerCase().contains(_query.toLowerCase()),
            )
            .toList();
    final grouped = _groupedOptions(filteredAll);

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
                  Expanded(
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _kPrimary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed:
                        () => Navigator.pop(
                          context,
                          OptionSelectionResult(selected: _selected),
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
                      hintText: widget.searchHint,
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
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _selected = []),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color:
                                _selected.isEmpty ? _kChipSelected : _kChipBg,
                            borderRadius: BorderRadius.circular(9999),
                            border:
                                _selected.isEmpty
                                    ? null
                                    : Border.all(color: _kChipBorder),
                          ),
                          child: Text(
                            widget.anyLabel,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.26,
                              color: _selected.isEmpty ? Colors.white : _kSub,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (filteredPopular.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _sectionHeading(widget.popularLabel),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: filteredPopular.map(_chip).toList(),
                    ),
                  ],
                  if (grouped.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _sectionHeading(widget.allLabel),
                    const SizedBox(height: 16),
                    for (final entry in grouped.entries) ...[
                      _groupHeader(entry.key),
                      if (!_collapsedGroups.contains(entry.key)) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: entry.value.map(_chip).toList(),
                        ),
                      ],
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

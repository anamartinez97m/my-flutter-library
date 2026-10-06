import 'dart:math';

import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/utils/saga_order_filter.dart';
import 'package:myrandomlibrary/widgets/chip_autocomplete_field.dart';
import 'package:myrandomlibrary/widgets/random_pick_scaffold.dart';
import 'package:provider/provider.dart';

const _kPrimary = Color(0xFF43102B);
const _kSub = Color(0xFF514348);

/// Book titles picked on [NewRandomBooksScreen], kept by the random tab so
/// they survive closing and reopening the screen.
class RandomBookSelection {
  List<String> titles = [];
}

/// Picks a random book from a list of specific books chosen by the user.
class NewRandomBooksScreen extends StatefulWidget {
  final RandomBookSelection selection;

  const NewRandomBooksScreen({super.key, required this.selection});

  @override
  State<NewRandomBooksScreen> createState() => _NewRandomBooksScreenState();
}

class _NewRandomBooksScreenState extends State<NewRandomBooksScreen> {
  final _scrollController = ScrollController();
  Book? _randomBook;
  int _fieldKey = 0;

  List<String> get _titles => widget.selection.titles;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _getRandomBook() {
    final provider = Provider.of<BookProvider?>(context, listen: false);
    if (provider == null) return;
    final selected =
        provider.allBooks.where((b) => _titles.contains(b.name)).toList();
    final candidates = filterBySagaOrder(selected, provider.allBooks);
    if (candidates.isEmpty) {
      setState(() => _randomBook = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.no_books_match_filters),
        ),
      );
      return;
    }
    setState(
      () => _randomBook = candidates[Random().nextInt(candidates.length)],
    );
    scrollToRandomResult(_scrollController);
  }

  void _clear() {
    setState(() {
      widget.selection.titles = [];
      _randomBook = null;
      _fieldKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return RandomPickScaffold(
      title: l10n.select_books,
      scrollController: _scrollController,
      randomBook: _randomBook,
      onPick: _titles.isEmpty ? null : _getRandomBook,
      pickLabel:
          _titles.isEmpty
              ? l10n.get_random_book
              : l10n.random_from_selected(_titles.length.toString()),
      onClear: _clear,
      clearLabel: l10n.clear_all,
      children: [_buildContent(l10n)],
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
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
              child: const Icon(
                Icons.library_books,
                color: _kPrimary,
                size: 34,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              l10n.search_select_books_description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _kSub, height: 1.4),
            ),
          ),
          const SizedBox(height: 28),
          Consumer<BookProvider>(
            builder: (context, provider, _) {
              final titles =
                  provider.allBooks
                      .map((b) => b.name ?? '')
                      .where((n) => n.isNotEmpty)
                      .toList()
                    ..sort();
              return ChipAutocompleteField(
                key: ValueKey(_fieldKey),
                labelText: l10n.select_books,
                prefixIcon: Icons.search,
                suggestions: titles,
                initialValues: _titles,
                hintText: l10n.type_to_search_books,
                onChanged:
                    (values) => setState(() {
                      widget.selection.titles = values;
                      if (values.isEmpty) _randomBook = null;
                    }),
                selectedBuilder:
                    (context, values, onRemove) => Column(
                      children: [
                        for (final title in values)
                          _SelectedBookTile(
                            title: title,
                            onRemove: () => onRemove(title),
                          ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// One row per selected book: leading book icon, title, trailing remove icon.
class _SelectedBookTile extends StatelessWidget {
  final String title;
  final VoidCallback onRemove;

  const _SelectedBookTile({required this.title, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x1A27231E)),
      ),
      child: Row(
        children: [
          const Icon(Icons.menu_book, size: 18, color: _kPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 18, color: _kSub),
          ),
        ],
      ),
    );
  }
}

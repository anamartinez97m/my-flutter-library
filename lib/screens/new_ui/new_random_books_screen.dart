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
const _kBorder = Color(0xFFD5C2C7);
const _kCardBg = Color(0xB3FDF8F6);
const _kCardBorder = Color(0x4DD5C2C7);
const _kCardShadow = [
  BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
];

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
      children: [_buildSelectBooksCard(l10n)],
    );
  }

  Widget _buildSelectBooksCard(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _kCardBg,
        border: Border.all(color: _kCardBorder),
        borderRadius: BorderRadius.circular(12),
        boxShadow: _kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: _kPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.library_books,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.select_books,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.random_books_card_subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: _kPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: _kBorder, height: 1),
          const SizedBox(height: 16),
          Text(
            l10n.search_select_books_description,
            style: const TextStyle(fontSize: 12, color: _kSub),
          ),
          const SizedBox(height: 12),
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
                prefixIcon: Icons.library_books,
                suggestions: titles,
                initialValues: _titles,
                hintText: l10n.type_to_search_books,
                onChanged:
                    (values) => setState(() {
                      widget.selection.titles = values;
                      if (values.isEmpty) _randomBook = null;
                    }),
              );
            },
          ),
        ],
      ),
    );
  }
}

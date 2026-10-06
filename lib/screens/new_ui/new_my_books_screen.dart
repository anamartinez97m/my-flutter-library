import 'package:flutter/material.dart';
import 'package:myrandomlibrary/config/v2_design_system.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/repositories/reading_club_repository.dart';
import 'package:myrandomlibrary/screens/new_ui/new_book_detail.dart';
import 'package:provider/provider.dart';
import 'package:myrandomlibrary/widgets/shimmer_loading.dart';

Widget _cover(dynamic book) {
  final letter =
      (book.name?.isNotEmpty ?? false) ? book.name![0].toUpperCase() : '?';
  final ph = Container(
    width: 64,
    height: 80,
    decoration: BoxDecoration(
      color: V2Colors.primaryAlt,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Center(
      child: Text(
        letter,
        style: const TextStyle(
          color: V2Colors.buttonText,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
  final url = book.coverUrl as String?;
  if (url == null || url.isEmpty) return ph;
  return ClipRRect(
    borderRadius: BorderRadius.circular(6),
    child: Image.network(
      url,
      width: 64,
      height: 80,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => ph,
    ),
  );
}

Widget _prog(dynamic book) {
  final p = (book.readingProgress ?? 0) as num;
  final pages = book.pages as int?;
  final double val;
  final String lbl;
  if (book.progressType == 'pages' && pages != null && pages > 0) {
    val = (p / pages).clamp(0.0, 1.0);
    lbl = '${(val * 100).round()}%';
  } else {
    val = (p / 100).clamp(0.0, 1.0);
    lbl = '$p%';
  }
  return Row(
    children: [
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9999),
          child: LinearProgressIndicator(
            value: val,
            minHeight: 6,
            backgroundColor: V2Colors.divider,
            valueColor: const AlwaysStoppedAnimation<Color>(V2Colors.primary),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        lbl,
        style: const TextStyle(fontSize: 12, color: V2Colors.textSecondary),
      ),
    ],
  );
}

Widget _bookTile(BuildContext context, dynamic book, VoidCallback onTap) {
  final showProg =
      book.statusValue?.toLowerCase() == 'started' ||
      book.statusValue?.toLowerCase() == 'standby';
  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: V2Colors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: V2Colors.border),
      ),
      child: Row(
        children: [
          _cover(book),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.name ?? AppLocalizations.of(context)!.unknown,
                  style: const TextStyle(fontSize: 16, color: V2Colors.primary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (book.author != null &&
                    (book.author as String).isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    book.author as String,
                    style: const TextStyle(
                      fontSize: 12,
                      color: V2Colors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (showProg) ...[const SizedBox(height: 6), _prog(book)],
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.arrow_forward_ios,
            size: 12,
            color: V2Colors.textSecondary,
          ),
        ],
      ),
    ),
  );
}

class NewMyBooksScreen extends StatefulWidget {
  const NewMyBooksScreen({super.key});
  @override
  State<NewMyBooksScreen> createState() => _NewMyBooksScreenState();
}

class _NewMyBooksScreenState extends State<NewMyBooksScreen> {
  bool _reading = true;
  bool _exp = true;
  final _clubsKey = GlobalKey<_ClubsCardState>();

  Widget _tab(String lbl, bool active, VoidCallback tap) => GestureDetector(
    onTap: tap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: active ? V2Colors.control : V2Colors.background,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        lbl,
        style: TextStyle(
          fontSize: 14,
          fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          color: active ? V2Colors.textPrimary : V2Colors.textSecondary,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<BookProvider?>(context);
    if (provider == null || provider.isLoading) {
      return Scaffold(
        backgroundColor: V2Colors.background,
        body: ShimmerLoading(),
      );
    }

    final reading =
        provider.allBooks.where((b) {
          final s = b.statusValue?.toLowerCase();
          return s == 'started' ||
              (s == 'no' &&
                  b.dateReadInitial != null &&
                  b.dateReadFinal == null);
        }).toList();
    final standby =
        provider.allBooks
            .where((b) => b.statusValue?.toLowerCase() == 'standby')
            .toList();
    final books = _reading ? reading : standby;
    final empty =
        _reading ? l10n.no_books_currently_reading : l10n.no_books_on_standby;

    return Scaffold(
      backgroundColor: V2Colors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Reading / Standby ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(
                        Icons.bookmark_outline,
                        color: V2Colors.primaryAlt,
                        size: 20,
                      ),
                      Container(
                        padding: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          border: Border.all(color: V2Colors.border),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _tab(
                              l10n.reading_label,
                              _reading,
                              () => setState(() => _reading = true),
                            ),
                            _tab(
                              l10n.standby_label,
                              !_reading,
                              () => setState(() => _reading = false),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _exp = !_exp),
                        child: Icon(
                          _exp
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: V2Colors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  if (_exp) ...[
                    const SizedBox(height: 16),
                    if (books.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                _reading
                                    ? Icons.menu_book_outlined
                                    : Icons.pause_circle_outline,
                                size: 48,
                                color: V2Colors.textSecondary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                empty,
                                style: const TextStyle(
                                  color: V2Colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Column(
                        children:
                            books
                                .map(
                                  (b) => _bookTile(
                                    context,
                                    b,
                                    () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => NewBookDetailScreen(book: b),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                  ],
                ],
              ),
            ),
            const Divider(
              color: V2Colors.border,
              height: 1,
              thickness: 1,
              indent: 40,
              endIndent: 40,
            ),
            _ClubsCard(key: _clubsKey),
            const Divider(
              color: V2Colors.border,
              height: 1,
              thickness: 1,
              indent: 40,
              endIndent: 40,
            ),
            _TBRCard(provider: provider),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _TBRCard extends StatefulWidget {
  final BookProvider? provider;
  const _TBRCard({required this.provider});
  @override
  State<_TBRCard> createState() => _TBRCardState();
}

class _TBRCardState extends State<_TBRCard> with WidgetsBindingObserver {
  List<dynamic> _books = [];
  bool _loading = true, _exp = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    try {
      final books =
          await BookRepository(
            await DatabaseHelper.instance.database,
          ).getTBRBooks();
      if (mounted) {
        setState(() {
          _books = books;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _remove(dynamic book) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'book',
        {'tbr': 0},
        where: 'book_id = ?',
        whereArgs: [book.bookId],
      );
      await widget.provider?.loadBooks();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.books_removed_from_tbr(book.name ?? ''),
            ),
            backgroundColor: V2Colors.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.bookmark_outline,
                    color: V2Colors.primaryAlt,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.tbr_title,
                    style: const TextStyle(
                      fontSize: 18,
                      color: V2Colors.primary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: V2Colors.chip,
                      border: Border.all(color: V2Colors.border),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${_books.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: V2Colors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => setState(() => _exp = !_exp),
                    child: Icon(
                      _exp
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: V2Colors.textSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_exp) ...[
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_books.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.bookmark_border,
                        size: 48,
                        color: V2Colors.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.no_books_in_tbr,
                        style: const TextStyle(color: V2Colors.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children:
                    _books
                        .map<Widget>(
                          (book) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: V2Colors.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: V2Colors.border),
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) =>
                                                NewBookDetailScreen(book: book),
                                      ),
                                    );
                                    _load();
                                  },
                                  child: _cover(book),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => NewBookDetailScreen(
                                                book: book,
                                              ),
                                        ),
                                      );
                                      _load();
                                    },
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          book.name ?? l10n.unknown,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: V2Colors.primary,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (book.author != null &&
                                            (book.author as String)
                                                .isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            book.author as String,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: V2Colors.textSecondary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: V2Colors.primaryAlt,
                                  ),
                                  onPressed: () => _remove(book),
                                  tooltip: l10n.remove_from_tbr,
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
              ),
          ],
        ],
      ),
    );
  }
}

class _ClubsCard extends StatefulWidget {
  const _ClubsCard({super.key});
  @override
  State<_ClubsCard> createState() => _ClubsCardState();
}

class _ClubsCardState extends State<_ClubsCard> with WidgetsBindingObserver {
  List<Map<String, dynamic>> _clubs = [];
  bool _loading = true, _exp = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    try {
      final all =
          await ReadingClubRepository(
            await DatabaseHelper.instance.database,
          ).getAllClubsWithBooks();
      if (mounted) {
        setState(() {
          _clubs = all;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('clubs: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openBook(int? bookId) async {
    if (bookId == null) return;
    try {
      final book = await BookRepository(
        await DatabaseHelper.instance.database,
      ).getBookById(bookId);
      if (!mounted || book == null) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => NewBookDetailScreen(book: book)),
      );
      _load();
    } catch (e) {
      debugPrint('open club book: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.groups_outlined,
                    color: V2Colors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.clubs,
                    style: const TextStyle(
                      fontSize: 18,
                      color: V2Colors.primary,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => setState(() => _exp = !_exp),
                child: Icon(
                  _exp ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: V2Colors.textSecondary,
                  size: 20,
                ),
              ),
            ],
          ),
          if (_exp) ...[
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_clubs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.groups_outlined,
                        size: 48,
                        color: V2Colors.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.no_clubs_yet,
                        style: const TextStyle(
                          fontSize: 16,
                          color: V2Colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.add_books_to_clubs,
                        style: const TextStyle(
                          fontSize: 14,
                          color: V2Colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 144,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: _clubs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (ctx, i) {
                    final item = _clubs[i];
                    final clubName =
                        item['club_name'] as String? ?? l10n.unknown;
                    final bookName =
                        item['book_name'] as String? ?? l10n.unknown;
                    final author = item['author'] as String?;
                    final prog = (item['reading_progress'] as int?) ?? 0;
                    final target = item['target_date'] as String?;
                    return GestureDetector(
                      onTap:
                          () => _openBook((item['book_id'] as num?)?.toInt()),
                      child: Container(
                        width: 256,
                        padding: const EdgeInsets.all(17),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F3F0),
                          border: Border.all(color: V2Colors.border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.groups,
                                  color: V2Colors.primary,
                                  size: 14,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    clubName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: V2Colors.primary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bookName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: V2Colors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                if (author != null && author.isNotEmpty)
                                  Text(
                                    author,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: V2Colors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (target != null)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 9,
                                        color: V2Colors.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        target,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: V2Colors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  const SizedBox.shrink(),
                                Text(
                                  '$prog%',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: V2Colors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }
}

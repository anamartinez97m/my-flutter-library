import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/repositories/reading_club_repository.dart';
import 'package:myrandomlibrary/screens/new_ui/new_book_detail.dart';
import 'package:provider/provider.dart';
import 'package:myrandomlibrary/widgets/shimmer_loading.dart';

const _kBg = Color(0xFFFDF8F6);
const _kDark = Color(0xFF5D2641);
const _kPrimary = Color(0xFF43102B);
const _kBorder = Color(0xFFD5C2C7);
const _kActive = Color(0xFFECE7E5);
const _kProgBg = Color(0xFFE6E2DF);
const _kBadge = Color(0xFFF2EDEB);
const _kSub = Color(0xFF514348);
const _kLetter = Color(0xFFD68DAC);

Widget _cover(dynamic book) {
  final letter =
      (book.name?.isNotEmpty ?? false) ? book.name![0].toUpperCase() : '?';
  final ph = Container(
    width: 64,
    height: 80,
    decoration: BoxDecoration(
      color: _kDark,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Center(
      child: Text(
        letter,
        style: const TextStyle(
          color: _kLetter,
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
            backgroundColor: _kProgBg,
            valueColor: const AlwaysStoppedAnimation<Color>(_kPrimary),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Text(lbl, style: const TextStyle(fontSize: 12, color: _kSub)),
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
        color: _kBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
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
                  style: const TextStyle(fontSize: 16, color: _kPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (book.author != null &&
                    (book.author as String).isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    book.author as String,
                    style: const TextStyle(fontSize: 12, color: _kSub),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (showProg) ...[const SizedBox(height: 6), _prog(book)],
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, size: 12, color: _kSub),
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
        color: active ? _kActive : _kBg,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        lbl,
        style: TextStyle(
          fontSize: 14,
          fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          color: active ? const Color(0xFF1C1B1A) : _kSub,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<BookProvider?>(context);
    if (provider == null || provider.isLoading) {
      return Scaffold(backgroundColor: _kBg, body: ShimmerLoading());
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
      backgroundColor: _kBg,
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
                        color: _kDark,
                        size: 20,
                      ),
                      Container(
                        padding: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          border: Border.all(color: _kBorder),
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
                          color: _kSub,
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
                                color: _kSub,
                              ),
                              const SizedBox(height: 12),
                              Text(empty, style: const TextStyle(color: _kSub)),
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
              color: _kBorder,
              height: 1,
              thickness: 1,
              indent: 40,
              endIndent: 40,
            ),
            _ClubsCard(key: _clubsKey),
            const Divider(
              color: _kBorder,
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
            backgroundColor: _kPrimary,
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
                  const Icon(Icons.bookmark_outline, color: _kDark, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    l10n.tbr_title,
                    style: const TextStyle(fontSize: 18, color: _kPrimary),
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
                      color: _kBadge,
                      border: Border.all(color: _kBorder),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${_books.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1C1B1A),
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
                      color: _kSub,
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
                      const Icon(Icons.bookmark_border, size: 48, color: _kSub),
                      const SizedBox(height: 12),
                      Text(
                        l10n.no_books_in_tbr,
                        style: const TextStyle(color: _kSub),
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
                              color: _kBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _kBorder),
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
                                            color: _kPrimary,
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
                                              color: _kSub,
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
                                    color: _kDark,
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
  Map<String, List<Map<String, dynamic>>> _clubs = {};
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
      final Map<String, List<Map<String, dynamic>>> g = {};
      for (final c in all) {
        final n = c['club_name'] as String;
        g.putIfAbsent(n, () => []).add(c);
      }
      if (mounted) {
        setState(() {
          _clubs = g;
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
                  const Icon(Icons.groups_outlined, color: _kPrimary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    l10n.clubs,
                    style: const TextStyle(fontSize: 18, color: _kPrimary),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => setState(() => _exp = !_exp),
                child: Icon(
                  _exp ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: _kSub,
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
                      const Icon(Icons.groups_outlined, size: 48, color: _kSub),
                      const SizedBox(height: 12),
                      Text(
                        l10n.no_clubs_yet,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1C1B1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.add_books_to_clubs,
                        style: const TextStyle(fontSize: 14, color: _kSub),
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
                    final entry = _clubs.entries.elementAt(i);
                    final clubName = entry.key;
                    final books = entry.value;
                    final firstBook = books.isNotEmpty ? books.first : null;
                    final prog = (firstBook?['reading_progress'] as int?) ?? 0;
                    final target = firstBook?['target_date'] as String?;
                    return GestureDetector(
                      onTap:
                          () => _openBook(
                            (firstBook?['book_id'] as num?)?.toInt(),
                          ),
                      child: Container(
                        width: 256,
                        padding: const EdgeInsets.all(17),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F3F0),
                          border: Border.all(color: _kBorder),
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
                                  color: _kPrimary,
                                  size: 14,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    clubName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: _kPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEB0D0),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${books.length}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: _kPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (firstBook != null) ...[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    firstBook['book_name'] as String? ??
                                        l10n.unknown,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF1C1B1A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  if (firstBook['author'] != null &&
                                      (firstBook['author'] as String)
                                          .isNotEmpty)
                                    Text(
                                      firstBook['author'] as String,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: _kSub,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  if (target != null)
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today,
                                          size: 9,
                                          color: _kSub,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          target,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: _kSub,
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
                                      color: _kPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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

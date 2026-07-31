import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/repositories/reading_club_repository.dart';
import 'package:myrandomlibrary/screens/book_detail.dart';
import 'package:provider/provider.dart';

const _kBg = Color(0xFFFDF8F6);
const _kDark = Color(0xFF5D2641);
const _kPrimary = Color(0xFF43102B);
const _kBorder = Color(0xFFD5C2C7);
const _kActive = Color(0xFFECE7E5);
const _kProgBg = Color(0xFFE6E2DF);
const _kBadge = Color(0xFFF2EDEB);
const _kSub = Color(0xFF514348);
const _kLetter = Color(0xFFD68DAC);

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _kBorder),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D000000),
          blurRadius: 1,
          offset: Offset(0, 1),
        ),
      ],
    ),
    child: child,
  );
}

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
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(child: CircularProgressIndicator()),
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
      backgroundColor: _kBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Card(
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
                                            (_) => BookDetailScreen(book: b),
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
            const SizedBox(height: 24),
            _ClubsCard(key: _clubsKey),
            const SizedBox(height: 24),
            _TBRCard(provider: provider),
            const SizedBox(height: 16),
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
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bookmark_outline, color: _kDark, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.tbr_title,
                  style: const TextStyle(fontSize: 18, color: _kDark),
                ),
              ),
              if (_books.isNotEmpty) ...[
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
              ],
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
                                            (_) => BookDetailScreen(book: book),
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
                                              (_) =>
                                                  BookDetailScreen(book: book),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups_outlined, color: _kDark, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.clubs,
                  style: const TextStyle(fontSize: 18, color: _kDark),
                ),
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
                padding: const EdgeInsets.symmetric(vertical: 24),
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
              Column(
                children:
                    _clubs.entries.map<Widget>((e) {
                      final books = e.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: _kBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _kBorder),
                        ),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          title: Row(
                            children: [
                              const Icon(Icons.group, color: _kDark, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  e.key,
                                  style: const TextStyle(
                                    color: _kDark,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _kBadge,
                                  border: Border.all(color: _kBorder),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${books.length}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF1C1B1A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          children:
                              books.map((book) {
                                final prog =
                                    book['reading_progress'] as int? ?? 0;
                                final target = book['target_date'] as String?;
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: _kBorder),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        book['book_name'] as String? ??
                                            l10n.unknown,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: _kPrimary,
                                        ),
                                      ),
                                      if (book['author'] != null &&
                                          (book['author'] as String)
                                              .isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          book['author'] as String,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: _kSub,
                                          ),
                                        ),
                                      ],
                                      if (target != null) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.calendar_today,
                                              size: 12,
                                              color: _kSub,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${l10n.target}: $target',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: _kSub,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(9999),
                                              child: LinearProgressIndicator(
                                                value: prog / 100,
                                                minHeight: 6,
                                                backgroundColor: _kProgBg,
                                                valueColor:
                                                    const AlwaysStoppedAnimation<
                                                      Color
                                                    >(_kPrimary),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '$prog%',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: _kSub,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                        ),
                      );
                    }).toList(),
              ),
          ],
        ],
      ),
    );
  }
}

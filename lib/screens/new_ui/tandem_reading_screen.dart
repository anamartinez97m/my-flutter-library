import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/model/tandem_chapter.dart';
import 'package:myrandomlibrary/model/tandem_reading.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/repositories/tandem_repository.dart';
import 'package:myrandomlibrary/screens/new_ui/tandem_chapter_form.dart';

/// Main screen for a tandem reading: shows both books, progress, and the
/// reorderable list of chapter steps.
class TandemReadingScreen extends StatefulWidget {
  final int tandemId;

  const TandemReadingScreen({super.key, required this.tandemId});

  @override
  State<TandemReadingScreen> createState() => _TandemReadingScreenState();
}

class _TandemReadingScreenState extends State<TandemReadingScreen> {
  static const _kPrimary = Color(0xFF43102B);
  static const _kSub = Color(0xFF514348);
  static const _kBg = Color(0xFFFDF8F6);
  static const _kMuted = Color(0xFFD5C2C7);
  static const _kBorder = Color(0x4DD5C2C7);
  static const _kText = Color(0xFF1C1B1A);

  TandemReading? _tandem;
  Book? _bookA;
  Book? _bookB;
  List<TandemChapter> _chapters = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final db = await DatabaseHelper.instance.database;
      final tandemRepo = TandemRepository(db);
      final bookRepo = BookRepository(db);

      final tandem = await tandemRepo.getTandemById(widget.tandemId);
      if (tandem == null) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = 'not found';
          });
        }
        return;
      }

      final results = await Future.wait([
        bookRepo.getBookById(tandem.bookAId),
        bookRepo.getBookById(tandem.bookBId),
        tandemRepo.getChaptersForTandem(widget.tandemId),
      ]);

      if (mounted) {
        setState(() {
          _tandem = tandem;
          _bookA = results[0] as Book?;
          _bookB = results[1] as Book?;
          _chapters = results[2] as List<TandemChapter>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '$e';
        });
      }
    }
  }

  String _chapterLabel(TandemChapter chapter, AppLocalizations l10n) {
    return chapter.startChapter == chapter.endChapter
        ? l10n.chapter_singular(chapter.startChapter)
        : l10n.chapter_range(chapter.startChapter, chapter.endChapter);
  }

  String _bookNameFor(TandemChapter chapter, AppLocalizations l10n) {
    final book =
        chapter.bookId == _bookA?.bookId
            ? _bookA
            : chapter.bookId == _bookB?.bookId
            ? _bookB
            : null;
    return book?.name ?? l10n.unknown_title;
  }

  Future<void> _toggleRead(TandemChapter chapter) async {
    final id = chapter.tandemChapterId;
    if (id == null) return;
    setState(() {
      _chapters =
          _chapters
              .map(
                (c) =>
                    c.tandemChapterId == id
                        ? TandemChapter(
                          tandemChapterId: c.tandemChapterId,
                          tandemId: c.tandemId,
                          bookId: c.bookId,
                          startChapter: c.startChapter,
                          endChapter: c.endChapter,
                          orderIndex: c.orderIndex,
                          isRead: !c.isRead,
                        )
                        : c,
              )
              .toList();
    });
    final db = await DatabaseHelper.instance.database;
    await TandemRepository(db).toggleChapterRead(id, !chapter.isRead);
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      final item = _chapters.removeAt(oldIndex);
      _chapters.insert(newIndex, item);
    });
    final db = await DatabaseHelper.instance.database;
    await TandemRepository(db).reorderChapters(
      widget.tandemId,
      _chapters.map((c) => c.tandemChapterId!).toList(),
    );
  }

  Future<void> _addStep() async {
    final tandem = _tandem;
    final bookA = _bookA;
    final bookB = _bookB;
    if (tandem == null || bookA == null || bookB == null) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => TandemChapterForm(
            tandem: tandem,
            bookA: bookA,
            bookB: bookB,
            nextOrderIndex: _chapters.length,
          ),
    );
    if (saved == true) _loadData();
  }

  Future<void> _editStep(TandemChapter chapter) async {
    final tandem = _tandem;
    final bookA = _bookA;
    final bookB = _bookB;
    if (tandem == null || bookA == null || bookB == null) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => TandemChapterForm(
            tandem: tandem,
            bookA: bookA,
            bookB: bookB,
            chapter: chapter,
          ),
    );
    if (saved == true) _loadData();
  }

  Future<void> _deleteStep(TandemChapter chapter) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.delete_step),
            content: Text(l10n.delete_step_confirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.delete_step),
              ),
            ],
          ),
    );
    if (confirmed != true) return;

    final id = chapter.tandemChapterId;
    if (id == null) return;
    setState(() {
      _chapters.removeWhere((c) => c.tandemChapterId == id);
    });
    final db = await DatabaseHelper.instance.database;
    await TandemRepository(db).deleteChapter(id);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.step_deleted)));
    }
  }

  Future<void> _deleteTandem() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.delete_tandem),
            content: Text(l10n.delete_tandem_confirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.delete_tandem),
              ),
            ],
          ),
    );
    if (confirmed != true) return;

    final db = await DatabaseHelper.instance.database;
    await TandemRepository(db).deleteTandem(widget.tandemId);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.tandem_deleted)));
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(child: CircularProgressIndicator(color: _kPrimary)),
      );
    }
    if (_error != null || _tandem == null) {
      return Scaffold(
        backgroundColor: _kBg,
        appBar: _buildAppBar(''),
        body: Center(
          child: Text(_error ?? '', style: const TextStyle(color: _kSub)),
        ),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    final title =
        (_tandem!.title?.isNotEmpty == true)
            ? _tandem!.title!
            : l10n.tandem_reading;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(title, l10n: l10n),
      floatingActionButton: FloatingActionButton(
        onPressed: _addStep,
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(l10n),
            _buildProgress(l10n),
            Expanded(
              child:
                  _chapters.isEmpty
                      ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            l10n.no_steps_yet,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              color: _kSub,
                            ),
                          ),
                        ),
                      )
                      : ReorderableListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                        itemCount: _chapters.length,
                        onReorderItem: _onReorder,
                        itemBuilder: (context, index) {
                          final chapter = _chapters[index];
                          return _buildChapterCard(chapter, l10n, index);
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String title, {AppLocalizations? l10n}) {
    return AppBar(
      backgroundColor: _kBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: _kPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _kPrimary,
              fontFamily: 'Manrope',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          if (l10n != null && _tandem?.title?.isNotEmpty == true)
            Text(
              l10n.tandem_reading,
              style: const TextStyle(color: _kSub, fontSize: 10),
            ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          tooltip: l10n?.delete_tandem,
          icon: const Icon(Icons.delete_outline, color: _kPrimary),
          onPressed: _deleteTandem,
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: _kMuted),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _HeaderBook(book: _bookA, accent: _kPrimary, l10n: l10n),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.swap_horiz, color: _kPrimary, size: 28),
          ),
          _HeaderBook(book: _bookB, accent: _kPrimary, l10n: l10n),
        ],
      ),
    );
  }

  Widget _buildProgress(AppLocalizations l10n) {
    final total = _chapters.length;
    final completed = _chapters.where((c) => c.isRead).length;
    final percent = total == 0 ? 0 : ((completed / total) * 100).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.tandem_progress(completed, total),
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kSub,
                ),
              ),
              Text(
                l10n.tandem_progress_percent(percent),
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : completed / total,
              minHeight: 8,
              backgroundColor: _kMuted.withValues(alpha: 0.4),
              valueColor: const AlwaysStoppedAnimation<Color>(_kPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterCard(
    TandemChapter chapter,
    AppLocalizations l10n,
    int index,
  ) {
    const accent = _kPrimary;

    return Container(
      key: ValueKey(chapter.tandemChapterId),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => _toggleRead(chapter),
                      borderRadius: BorderRadius.circular(9999),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          chapter.isRead
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: chapter.isRead ? _kPrimary : _kSub,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _bookNameFor(chapter, l10n),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _kText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _chapterLabel(chapter, l10n),
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 12,
                              color: _kSub,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: _kSub, size: 20),
                      onSelected: (value) {
                        if (value == 'edit') _editStep(chapter);
                        if (value == 'delete') _deleteStep(chapter);
                      },
                      itemBuilder:
                          (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text(l10n.edit_step),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(l10n.delete_step),
                            ),
                          ],
                    ),
                    ReorderableDragStartListener(
                      index: index,
                      child: const Icon(
                        Icons.drag_handle,
                        color: _kSub,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderBook extends StatelessWidget {
  final Book? book;
  final Color accent;
  final AppLocalizations l10n;

  const _HeaderBook({
    required this.book,
    required this.accent,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final coverUrl = book?.coverUrl?.trim();
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 56,
            height: 78,
            color: accent.withValues(alpha: 0.1),
            child:
                coverUrl == null || coverUrl.isEmpty
                    ? Icon(Icons.menu_book, color: accent, size: 26)
                    : Image.network(
                      coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) =>
                              Icon(Icons.menu_book, color: accent),
                    ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 110,
          child: Text(
            book?.name ?? l10n.unknown_title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1C1B1A),
            ),
          ),
        ),
      ],
    );
  }
}

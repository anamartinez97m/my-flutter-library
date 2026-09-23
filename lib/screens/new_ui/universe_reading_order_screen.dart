import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/model/book_relation.dart';
import 'package:myrandomlibrary/model/placeholder_relation.dart';
import 'package:myrandomlibrary/model/universe_placeholder.dart';
import 'package:myrandomlibrary/providers/role_provider.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/screens/add_book.dart';
import 'package:myrandomlibrary/screens/new_ui/new_book_detail.dart';
import 'package:myrandomlibrary/screens/settings/universe_placeholders_screen.dart';
import 'package:provider/provider.dart';

class UniverseReadingOrderScreen extends StatefulWidget {
  final String universe;
  final int? selectedBookId;

  const UniverseReadingOrderScreen({
    super.key,
    required this.universe,
    this.selectedBookId,
  });

  @override
  State<UniverseReadingOrderScreen> createState() =>
      _UniverseReadingOrderScreenState();
}

class _UniverseReadingOrderScreenState
    extends State<UniverseReadingOrderScreen> {
  static const _kPrimary = Color(0xFF43102B);
  static const _kSecondary = Color(0xFF894B67);
  static const _kSub = Color(0xFF514348);
  static const _kBg = Color(0xFFFDF8F6);
  static const _kMuted = Color(0xFFD5C2C7);
  static const _nodeSize = 84.0;
  static const _trackWidth = 220.0;
  static const _rowHeight = 140.0;
  static const _canvasPadding = 64.0;
  static const _firstNodeTop = 160.0;
  static const _sagaColors = [
    Color(0xFF43102B),
    Color(0xFF894B67),
    Color(0xFF6E2947),
    Color(0xFFA45F78),
    Color(0xFF5C3A4A),
    Color(0xFF9A405F),
  ];

  List<Book> _books = [];
  List<BookRelation> _relations = [];
  bool _loading = true;
  bool _editMode = false;
  bool _addingRelation = false;
  int? _relationStartBookId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<BookRepository> _repository() async {
    final db = await DatabaseHelper.instance.database;
    return BookRepository(db);
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final repository = await _repository();
      final results = await Future.wait([
        repository.getBooksByUniverse(widget.universe),
        repository.getBookRelationsForUniverse(widget.universe),
        repository.getPlaceholdersByUniverse(widget.universe),
        repository.getPlaceholderRelationsForUniverse(widget.universe),
        repository.getPlaceholderPlaceholderRelationsForUniverse(
          widget.universe,
        ),
      ]);
      final loadedBooks = results[0] as List<Book>;
      final bookIdsInUniverse =
          loadedBooks.map((b) => b.bookId).whereType<int>().toSet();
      final books =
          loadedBooks.where((book) {
            if (book.isBundle == true) return false;
            if (book.statusValue?.toLowerCase() == 'repeated') return false;
            if (book.originalBookId != null &&
                bookIdsInUniverse.contains(book.originalBookId)) {
              return false;
            }
            return true;
          }).toList();
      final placeholders = (results[2] as List<UniversePlaceholder>).map(
        (placeholder) => Book(
          bookId: -placeholder.placeholderId!,
          name: placeholder.title,
          saga: placeholder.saga,
          nSaga: placeholder.nSaga,
          sagaUniverse: placeholder.sagaUniverse,
          author: placeholder.author,
          coverUrl: placeholder.coverUrl,
          notes: placeholder.notes,
          orderWithinUniverse: placeholder.orderWithinUniverse,
          formatSagaValue: null,
          isbn: null,
          asin: null,
          pages: null,
          originalPublicationYear: null,
          loaned: null,
          statusValue: null,
          editorialValue: null,
          languageValue: null,
          placeValue: null,
          formatValue: null,
          createdAt: placeholder.createdAt,
          isPlaceholder: true,
        ),
      );
      if (!mounted) return;
      setState(() {
        _books = [...books, ...placeholders]..sort(_compareBooks);
        _relations = [
          ...results[1] as List<BookRelation>,
          ...results[3] as List<BookRelation>,
          ...results[4] as List<BookRelation>,
        ];
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  void _toggleEditMode() {
    setState(() {
      _editMode = !_editMode;
      _addingRelation = false;
      _relationStartBookId = null;
    });
  }

  String? _trackFor(Book book) {
    final saga = book.saga?.trim();
    return saga == null || saga.isEmpty ? null : saga;
  }

  List<String?> get _tracks {
    final sorted = [..._books]..sort(_compareBooks);
    final sagas = <String?>[];
    for (final book in sorted) {
      final track = _trackFor(book);
      if (!sagas.contains(track)) sagas.add(track);
    }
    return sagas;
  }

  Set<int> _sideBookIds(List<String?> tracks) {
    final booksById = {for (final book in _books) book.bookId: book};
    final sideBookIds = <int>{};
    for (final relation in _displayRelations) {
      if (relation.type == 'next') continue;
      final toBook = booksById[relation.toBookId];
      if (toBook == null) continue;
      final toTrack = _trackFor(toBook);
      final fromBook = booksById[relation.fromBookId];
      if (fromBook == null) continue;
      final fromTrack = _trackFor(fromBook);
      if (toTrack != null && toTrack == fromTrack) {
        sideBookIds.add(relation.toBookId);
      }
    }
    return sideBookIds;
  }

  List<double> _trackWidths(
    List<String?> tracks,
    Map<String?, List<Book>> booksByTrack,
    Set<int> sideBookIds,
  ) {
    return tracks.map((track) {
      final books = booksByTrack[track] ?? const <Book>[];
      final hasSide = books.any((book) => sideBookIds.contains(book.bookId));
      return hasSide ? _trackWidth * 2 : _trackWidth;
    }).toList();
  }

  ({Map<int, Offset> positions, List<double> trackWidths}) _layoutFor(
    List<String?> tracks,
  ) {
    final sorted = [..._books]..sort(_compareBooks);
    final booksByTrack = <String?, List<Book>>{};
    for (final book in sorted) {
      booksByTrack.putIfAbsent(_trackFor(book), () => []).add(book);
    }
    final sideBookIds = _sideBookIds(tracks);
    final trackWidths = _trackWidths(tracks, booksByTrack, sideBookIds);
    final positions = <int, Offset>{};
    var currentX = _canvasPadding;
    for (var column = 0; column < tracks.length; column++) {
      final books = booksByTrack[tracks[column]] ?? const <Book>[];
      final mainBooks =
          books.where((b) => !sideBookIds.contains(b.bookId)).toList();
      final sideBooks =
          books.where((b) => sideBookIds.contains(b.bookId)).toList();
      final trackTop = _firstNodeTop;
      for (var row = 0; row < mainBooks.length; row++) {
        final bookId = mainBooks[row].bookId;
        if (bookId != null) {
          positions[bookId] = Offset(
            currentX + _trackWidth / 2,
            trackTop + row * _rowHeight,
          );
        }
      }
      for (var row = 0; row < sideBooks.length; row++) {
        final bookId = sideBooks[row].bookId;
        if (bookId != null) {
          positions[bookId] = Offset(
            currentX + _trackWidth * 1.5,
            trackTop + row * _rowHeight,
          );
        }
      }
      currentX += trackWidths[column];
    }
    return (positions: positions, trackWidths: trackWidths);
  }

  int _compareBooks(Book a, Book b) {
    final aOrder = a.orderWithinUniverse;
    final bOrder = b.orderWithinUniverse;
    if (aOrder == null && bOrder != null) return 1;
    if (aOrder != null && bOrder == null) return -1;
    if (aOrder != null && bOrder != null && aOrder != bOrder) {
      return aOrder.compareTo(bOrder);
    }
    final sagaComparison = (a.saga ?? '').compareTo(b.saga ?? '');
    if (sagaComparison != 0) return sagaComparison;
    return (a.name ?? '').compareTo(b.name ?? '');
  }

  Color _colorForBook(Book book, List<String?> tracks) {
    final saga = book.saga?.trim();
    final key = saga == null || saga.isEmpty ? null : saga;
    final index = math.max(0, tracks.indexOf(key));
    return _sagaColors[index % _sagaColors.length];
  }

  List<BookRelation> get _displayRelations {
    // Only show relations explicitly added by the user; do not draw
    // auto-generated saga-sequence lines.
    return [..._relations];
  }

  Future<void> _handleBookTap(Book book) async {
    if (!_editMode || !_addingRelation) {
      if (book.isPlaceholder) {
        await _showBookActions(book);
      } else {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NewBookDetailScreen(book: book)),
        );
        await _loadData();
      }
      return;
    }
    final bookId = book.bookId;
    if (bookId == null) return;
    if (_relationStartBookId == null) {
      setState(() => _relationStartBookId = bookId);
      return;
    }
    if (_relationStartBookId == bookId) {
      setState(() => _relationStartBookId = null);
      return;
    }
    final type = await _chooseRelationType();
    if (type == null || !mounted) return;
    try {
      final repository = await _repository();
      final fromId = _relationStartBookId!;
      if (fromId < 0 && bookId < 0) {
        await repository.insertPlaceholderPlaceholderRelation(
          fromPlaceholderId: -fromId,
          toPlaceholderId: -bookId,
          type: type,
        );
      } else if (fromId < 0 || bookId < 0) {
        await repository.insertPlaceholderRelation(
          PlaceholderRelation(
            placeholderId: -(fromId < 0 ? fromId : bookId),
            bookId: fromId > 0 ? fromId : bookId,
            placeholderIsSource: fromId < 0,
            type: type,
          ),
        );
      } else {
        await repository.insertBookRelation(
          BookRelation(fromBookId: fromId, toBookId: bookId, type: type),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.relation_added)),
      );
      setState(() {
        _addingRelation = false;
        _relationStartBookId = null;
      });
      await _loadData();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.error_occurred(error.toString()),
          ),
        ),
      );
    }
  }

  Future<String?> _chooseRelationType() {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.relation_type),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.arrow_downward, color: _kPrimary),
                  title: Text(l10n.relation_next),
                  onTap: () => Navigator.pop(context, 'next'),
                ),
                ListTile(
                  leading: const Icon(Icons.link, color: _kSecondary),
                  title: Text(l10n.relation_related),
                  onTap: () => Navigator.pop(context, 'related'),
                ),
                ListTile(
                  leading: const Icon(Icons.alt_route, color: _kSecondary),
                  title: Text(l10n.relation_optional),
                  onTap: () => Navigator.pop(context, 'optional'),
                ),
              ],
            ),
          ),
    );
  }

  UniversePlaceholder _placeholderFromBook(Book book) {
    return UniversePlaceholder(
      placeholderId: -book.bookId!,
      sagaUniverse: book.sagaUniverse!,
      title: book.name ?? '',
      author: book.author,
      saga: book.saga,
      nSaga: book.nSaga,
      orderWithinUniverse: book.orderWithinUniverse,
      coverUrl: book.coverUrl,
      notes: book.notes,
      createdAt: book.createdAt,
    );
  }

  Future<void> _showBookActions(Book book) async {
    final l10n = AppLocalizations.of(context)!;
    if (book.isPlaceholder) {
      final placeholder = _placeholderFromBook(book);
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: _kBg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder:
            (sheetContext) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit_outlined, color: _kPrimary),
                    title: Text(
                      l10n.edit_placeholder,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => UniversePlaceholdersScreen(
                                initialUniverse: widget.universe,
                                editPlaceholder: placeholder,
                                returnAfterEdit: true,
                              ),
                        ),
                      );
                      await _loadData();
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.library_add_outlined,
                      color: _kPrimary,
                    ),
                    title: Text(
                      l10n.promote_to_library,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => AddBookScreen(
                                initialPlaceholder: placeholder,
                                onBookSaved:
                                    (bookId) => _repository().then(
                                      (repository) =>
                                          repository.promotePlaceholderToBook(
                                            placeholder.placeholderId!,
                                            bookId,
                                          ),
                                    ),
                              ),
                        ),
                      );
                      await _loadData();
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFB3261E),
                    ),
                    title: Text(
                      l10n.delete_placeholder,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB3261E),
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      final repository = await _repository();
                      await repository.deletePlaceholder(
                        placeholder.placeholderId!,
                      );
                      await _loadData();
                    },
                  ),
                ],
              ),
            ),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _kBg,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.menu_book_outlined,
                    color: _kPrimary,
                  ),
                  title: Text(book.name ?? l10n.unknown_title),
                  subtitle: Text(book.saga ?? l10n.standalone_books),
                  onTap: () async {
                    Navigator.pop(context);
                    await Navigator.push(
                      this.context,
                      MaterialPageRoute(
                        builder: (_) => NewBookDetailScreen(book: book),
                      ),
                    );
                    await _loadData();
                  },
                ),
                if (_editMode)
                  ListTile(
                    leading: const Icon(Icons.add_link, color: _kPrimary),
                    title: Text(l10n.add_relation),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _addingRelation = true;
                        _relationStartBookId = book.bookId;
                      });
                    },
                  ),
              ],
            ),
          ),
    );
  }

  Future<void> _showReorderSheet() async {
    final l10n = AppLocalizations.of(context)!;
    final reordered = [..._books]..sort(_compareBooks);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kBg,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setSheetState) => SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.78,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.reorder_books,
                                    style: const TextStyle(
                                      color: _kPrimary,
                                      fontFamily: 'Manrope',
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    l10n.drag_to_reorder,
                                    style: const TextStyle(
                                      color: _kSub,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(l10n.save),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ReorderableListView.builder(
                          padding: EdgeInsets.only(
                            left: 12,
                            right: 12,
                            bottom: MediaQuery.of(context).padding.bottom + 16,
                          ),
                          itemCount: reordered.length,
                          onReorderItem: (oldIndex, newIndex) {
                            setSheetState(() {
                              final book = reordered.removeAt(oldIndex);
                              reordered.insert(newIndex, book);
                            });
                          },
                          itemBuilder: (context, index) {
                            final book = reordered[index];
                            return Card(
                              key: ValueKey(book.bookId),
                              color: Colors.white,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _kPrimary,
                                  foregroundColor: _kBg,
                                  child: Text('${index + 1}'),
                                ),
                                title: Text(book.name ?? l10n.unknown_title),
                                subtitle: Text(
                                  book.saga ?? l10n.standalone_books,
                                ),
                                trailing: const Icon(
                                  Icons.drag_handle,
                                  color: _kSub,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
    if (saved != true || !mounted) return;
    try {
      final repository = await _repository();
      for (var index = 0; index < reordered.length; index++) {
        final id = reordered[index].bookId;
        if (id != null) {
          if (id < 0) {
            await repository.updatePlaceholderUniverseOrder(-id, index + 1);
          } else {
            await repository.updateBookUniverseOrder(id, index + 1);
          }
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.reading_order_saved)));
      await _loadData();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.error_occurred(error.toString()))),
      );
    }
  }

  Future<void> _showRelationsSheet() async {
    final l10n = AppLocalizations.of(context)!;
    final byId = {for (final book in _books) book.bookId: book};
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _kBg,
      builder:
          (context) => SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.65,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text(
                      l10n.delete_relation,
                      style: const TextStyle(
                        color: _kPrimary,
                        fontFamily: 'Manrope',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _relations.length,
                      itemBuilder: (context, index) {
                        final relation = _relations[index];
                        final from = byId[relation.fromBookId]?.name ?? '?';
                        final to = byId[relation.toBookId]?.name ?? '?';
                        return ListTile(
                          leading: Icon(
                            relation.type == 'next'
                                ? Icons.arrow_forward
                                : Icons.link,
                            color: _kPrimary,
                          ),
                          title: Text('$from → $to'),
                          subtitle: Text(relation.type),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed:
                                relation.relationId == null
                                    ? null
                                    : () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder:
                                            (dialogContext) => AlertDialog(
                                              content: Text(
                                                l10n.confirm_delete_relation,
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        dialogContext,
                                                        false,
                                                      ),
                                                  child: Text(l10n.cancel),
                                                ),
                                                FilledButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        dialogContext,
                                                        true,
                                                      ),
                                                  child: Text(l10n.delete),
                                                ),
                                              ],
                                            ),
                                      );
                                      if (confirmed != true) return;
                                      final repository = await _repository();
                                      if (relation.relationId! < 0) {
                                        final isPlaceholderPlaceholder =
                                            relation.fromBookId < 0 &&
                                            relation.toBookId < 0;
                                        if (isPlaceholderPlaceholder) {
                                          await repository
                                              .deletePlaceholderPlaceholderRelation(
                                                -relation.relationId!,
                                              );
                                        } else {
                                          await repository
                                              .deletePlaceholderRelation(
                                                -relation.relationId!,
                                              );
                                        }
                                      } else {
                                        await repository.deleteBookRelation(
                                          relation.relationId!,
                                        );
                                      }
                                      if (!context.mounted || !mounted) return;
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        this.context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(l10n.relation_deleted),
                                        ),
                                      );
                                      await _loadData();
                                    },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!context.watch<RoleProvider>().isAdmin) {
      return const Scaffold(backgroundColor: _kBg);
    }
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
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
              widget.universe.toUpperCase(),
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
            Text(
              l10n.universe_reading_order,
              style: const TextStyle(color: _kSub, fontSize: 10),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: _editMode ? l10n.finish_editing : l10n.edit_reading_order,
            icon: Icon(_editMode ? Icons.done : Icons.edit_outlined),
            color: _kPrimary,
            onPressed: _toggleEditMode,
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _kMuted),
        ),
      ),
      body: Column(
        children: [
          if (_editMode) _buildEditToolbar(l10n),
          if (_addingRelation)
            Container(
              width: double.infinity,
              color: _kSecondary.withValues(alpha: 0.12),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Text(
                _relationStartBookId == null
                    ? l10n.select_first_book
                    : l10n.select_second_book,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _kPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Expanded(child: _buildBody(l10n)),
        ],
      ),
    );
  }

  Widget _buildEditToolbar(AppLocalizations l10n) {
    return Container(
      color: _kBg,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          TextButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => UniversePlaceholdersScreen(
                        initialUniverse: widget.universe,
                        returnAfterEdit: true,
                        openAddForm: true,
                      ),
                ),
              );
              await _loadData();
            },
            icon: const Icon(Icons.add),
            label: Text(l10n.add_placeholder),
          ),
          TextButton.icon(
            onPressed: _showReorderSheet,
            icon: const Icon(Icons.reorder),
            label: Text(l10n.reorder_books),
          ),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _addingRelation = true;
                _relationStartBookId = null;
              });
            },
            icon: const Icon(Icons.add_link),
            label: Text(l10n.add_relation),
          ),
          if (_relations.isNotEmpty)
            TextButton.icon(
              onPressed: _showRelationsSheet,
              icon: const Icon(Icons.link_off),
              label: Text(l10n.delete_relation),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _kPrimary));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: _kSecondary, size: 40),
              const SizedBox(height: 12),
              Text(l10n.error_loading_reading_order),
              const SizedBox(height: 8),
              TextButton(onPressed: _loadData, child: Text(l10n.retry)),
            ],
          ),
        ),
      );
    }
    if (_books.isEmpty) {
      return Center(child: Text(l10n.no_books_in_universe));
    }
    final tracks = _tracks;
    final layout = _layoutFor(tracks);
    final positions = layout.positions;
    final trackWidths = layout.trackWidths;
    final totalTrackWidth = trackWidths.fold<double>(
      0,
      (sum, width) => sum + width,
    );
    final width = math.max(
      MediaQuery.sizeOf(context).width,
      _canvasPadding * 2 + math.max(1, totalTrackWidth),
    );
    final lowestNode = positions.values.fold<double>(
      _firstNodeTop,
      (lowest, position) => math.max(lowest, position.dy),
    );
    final height = math.max(
      MediaQuery.sizeOf(context).height - 100,
      lowestNode + _nodeSize + 72,
    );
    final booksById = {for (final book in _books) book.bookId: book};
    final trackLefts = <double>[];
    var cumulativeX = _canvasPadding;
    for (final trackWidth in trackWidths) {
      trackLefts.add(cumulativeX);
      cumulativeX += trackWidth;
    }
    return InteractiveViewer(
      constrained: false,
      minScale: 0.5,
      maxScale: 3,
      boundaryMargin: const EdgeInsets.all(100),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            CustomPaint(
              size: Size(width, height),
              painter: _ReadingOrderPainter(
                positions: positions,
                relations: _displayRelations,
                booksById: booksById,
                colorForBook: (book) => _colorForBook(book, tracks),
                nodeRadius: _nodeSize / 2,
              ),
            ),
            for (var index = 0; index < tracks.length; index++)
              Positioned(
                left: trackLefts[index] + 20,
                top: _firstNodeTop - 100,
                width: trackWidths[index] - 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _sagaColors[index % _sagaColors.length].withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    tracks[index] ?? l10n.standalone_books,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _sagaColors[index % _sagaColors.length],
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            for (final book in _books)
              if (book.bookId != null && positions[book.bookId] != null)
                Positioned(
                  left: positions[book.bookId]!.dx - _nodeSize / 2,
                  top: positions[book.bookId]!.dy - _nodeSize / 2,
                  child: _BookNode(
                    book: book,
                    color: _colorForBook(book, tracks),
                    selected:
                        widget.selectedBookId == book.bookId ||
                        _relationStartBookId == book.bookId,
                    onTap: () => _handleBookTap(book),
                    onLongPress: () => _showBookActions(book),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _BookNode extends StatelessWidget {
  final Book book;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _BookNode({
    required this.book,
    required this.color,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final title = book.name?.trim();
    final displayTitle =
        title == null || title.isEmpty
            ? AppLocalizations.of(context)!.unknown_title
            : title;
    final coverUrl = book.coverUrl?.trim();
    final isRead = [
      'yes',
      'finished',
      'read',
      'repeated',
    ].contains(book.statusValue?.toLowerCase());
    final isPlaceholder = book.isPlaceholder;
    final nodeColor = isPlaceholder ? Colors.grey.shade600 : color;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: SizedBox(
        width: 132,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 84,
              height: 84,
              padding: EdgeInsets.all(selected ? 4 : 2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFDF8F6),
                border: Border.all(
                  color: nodeColor,
                  width: selected ? 4 : (isPlaceholder ? 2.5 : 2),
                ),
                boxShadow:
                    selected
                        ? [
                          BoxShadow(
                            color: nodeColor.withValues(alpha: 0.35),
                            blurRadius: 14,
                            spreadRadius: 3,
                          ),
                        ]
                        : const [],
              ),
              child: ClipOval(
                child: Opacity(
                  opacity: isPlaceholder ? 0.25 : (isRead ? 1 : 0.82),
                  child:
                      coverUrl == null || coverUrl.isEmpty
                          ? ColoredBox(
                            color: color,
                            child: Center(
                              child: Text(
                                displayTitle.characters.first.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Manrope',
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          )
                          : Image.network(
                            coverUrl,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => ColoredBox(
                                  color: color,
                                  child: Center(
                                    child: Text(
                                      displayTitle.characters.first
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                          ),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Container(
              color: const Color(0xFFFDF8F6),
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                displayTitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF514348),
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
            if (isPlaceholder)
              Container(
                color: const Color(0xFFFDF8F6),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                child: Text(
                  AppLocalizations.of(context)!.not_in_library,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (book.orderWithinUniverse == null)
              ColoredBox(
                color: const Color(0xFFFDF8F6),
                child: Text(
                  AppLocalizations.of(context)!.unordered,
                  style: const TextStyle(
                    color: Color(0xFF894B67),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReadingOrderPainter extends CustomPainter {
  final Map<int, Offset> positions;
  final List<BookRelation> relations;
  final Map<int?, Book> booksById;
  final Color Function(Book) colorForBook;
  final double nodeRadius;

  _ReadingOrderPainter({
    required this.positions,
    required this.relations,
    required this.booksById,
    required this.colorForBook,
    required this.nodeRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final relation in relations) {
      final from = positions[relation.fromBookId];
      final to = positions[relation.toBookId];
      final fromBook = booksById[relation.fromBookId];
      if (from == null || to == null || fromBook == null) continue;
      if (from == to) continue;
      final path = _relationPath(from, to);
      final isSolid = relation.type == 'next';
      final paint =
          Paint()
            ..color =
                isSolid
                    ? colorForBook(fromBook)
                    : const Color(0xFF894B67).withValues(alpha: 0.65)
            ..strokeWidth = isSolid ? 3.4 : 2.8
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round;
      if (isSolid) {
        canvas.drawPath(path, paint);
      } else {
        _drawDashedPath(canvas, path, paint);
      }
      _drawArrowhead(canvas, path, paint);
    }
  }

  static const _arrowMargin = 8.0;

  Path _relationPath(Offset from, Offset to) {
    if ((to.dx - from.dx).abs() < 1) {
      final start = Offset(from.dx + nodeRadius, from.dy);
      final end = Offset(to.dx + nodeRadius, to.dy);
      final laneX = from.dx + nodeRadius + 28;
      return Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(laneX, start.dy, laneX, end.dy, end.dx, end.dy);
    }
    final direction = (to.dx - from.dx).sign;
    final start = Offset(from.dx + direction * nodeRadius, from.dy);
    final end = Offset(to.dx - direction * (nodeRadius + _arrowMargin), to.dy);
    final controlX = (start.dx + end.dx) / 2;
    return Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(controlX, start.dy, controlX, end.dy, end.dx, end.dy);
  }

  void _drawArrowhead(Canvas canvas, Path path, Paint paint) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.last;
    final tangent = metric.getTangentForOffset(metric.length);
    if (tangent == null) return;
    const arrowLength = 16.0;
    const arrowAngle = math.pi / 7;
    final angle = tangent.angle;
    final tip = tangent.position;
    final arrow =
        Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(
            tip.dx - arrowLength * math.cos(angle - arrowAngle),
            tip.dy - arrowLength * math.sin(angle - arrowAngle),
          )
          ..lineTo(
            tip.dx - arrowLength * math.cos(angle + arrowAngle),
            tip.dy - arrowLength * math.sin(angle + arrowAngle),
          )
          ..close();
    canvas.drawPath(
      arrow,
      Paint()
        ..color = paint.color
        ..style = PaintingStyle.fill,
    );
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + 8, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += 13;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ReadingOrderPainter oldDelegate) {
    return oldDelegate.positions != positions ||
        oldDelegate.relations != relations ||
        oldDelegate.booksById != booksById;
  }
}

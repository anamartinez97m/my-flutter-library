import 'package:flutter/material.dart';
import 'package:myrandomlibrary/config/v2_design_system.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/discovery/text/text_normalizer.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/user_list.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/screens/books_by_author.dart';
import 'package:myrandomlibrary/screens/books_by_genre.dart';
import 'package:myrandomlibrary/screens/books_by_saga.dart';
import 'package:myrandomlibrary/screens/new_ui/new_book_detail.dart';
import 'package:myrandomlibrary/screens/new_ui/user_list_share_screen.dart';
import 'package:myrandomlibrary/screens/new_ui/user_lists_screen.dart';

String userListSortLabel(AppLocalizations l10n, UserListSortMode mode) {
  switch (mode) {
    case UserListSortMode.manual:
      return l10n.list_sort_manual;
    case UserListSortMode.nameAsc:
      return l10n.list_sort_name_asc;
    case UserListSortMode.nameDesc:
      return l10n.list_sort_name_desc;
    case UserListSortMode.newest:
      return l10n.list_sort_newest;
    case UserListSortMode.oldest:
      return l10n.list_sort_oldest;
  }
}

/// Small cover (or first-letter placeholder) used by book entries.
class UserListCover extends StatelessWidget {
  final String title;
  final String? url;
  final double width;
  final double height;

  const UserListCover({
    super.key,
    required this.title,
    this.url,
    this.width = 40,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: V2Colors.primaryAlt,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          title.isNotEmpty ? title[0].toUpperCase() : '?',
          style: TextStyle(
            color: V2Colors.buttonText,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
    if (url == null || url!.isEmpty) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        url!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}

/// Thin read/total bar used by genre entries.
class UserListReadBar extends StatelessWidget {
  final int read;
  final int total;
  final double width;

  const UserListReadBar({
    super.key,
    required this.read,
    required this.total,
    this.width = 120,
  });

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(2),
    child: SizedBox(
      width: width,
      height: 4,
      child: LinearProgressIndicator(
        value: total == 0 ? 0 : read / total,
        backgroundColor: V2Colors.chip,
        color: V2Colors.primary,
      ),
    ),
  );
}

/// Author initials inside a ring that fills with the share of books read.
class UserListAuthorAvatar extends StatelessWidget {
  final String name;
  final int read;
  final int total;
  final double size;

  const UserListAuthorAvatar({
    super.key,
    required this.name,
    required this.read,
    required this.total,
    this.size = 48,
  });

  static String initials(String name) {
    final parts =
        name
            .replaceAll('.', ' ')
            .split(RegExp(r'\s+'))
            .where((p) => p.isNotEmpty)
            .toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.characters.first;
    final last = parts.length > 1 ? parts.last.characters.first : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Stack(
      fit: StackFit.expand,
      children: [
        CircularProgressIndicator(
          value: total == 0 ? 0 : read / total,
          strokeWidth: size / 16,
          backgroundColor: V2Colors.chip,
          color: V2Colors.primary,
        ),
        Padding(
          padding: EdgeInsets.all(size / 10),
          child: Container(
            decoration: BoxDecoration(
              color: V2Colors.primaryAlt,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Text(
                  initials(name),
                  style: TextStyle(
                    color: V2Colors.buttonText,
                    fontWeight: FontWeight.w700,
                    fontSize: size * 0.3,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Up to three small covers overlapping each other.
class UserListCoverFan extends StatelessWidget {
  final List<String> covers;
  final String title;

  const UserListCoverFan({
    super.key,
    required this.covers,
    required this.title,
  });

  static const double _width = 26;
  static const double _height = 38;
  static const double _step = 14;

  @override
  Widget build(BuildContext context) {
    final shown = covers.take(3).toList();
    if (shown.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      width: _width + _step * (shown.length - 1),
      height: _height,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: _step * i,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: V2Colors.background, width: 1.5),
                ),
                child: UserListCover(
                  title: title,
                  url: shown[i],
                  width: _width - 3,
                  height: _height - 3,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Square 2×2 collage of covers; one cover fills the square, none shows the
/// type icon.
class UserListCoverCollage extends StatelessWidget {
  final List<String> covers;
  final UserListType type;
  final double size;

  const UserListCoverCollage({
    super.key,
    required this.covers,
    required this.type,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size / 6);
    Widget empty(double s) =>
        Container(width: s, height: s, color: V2Colors.chip);
    Widget image(String url, double s) => Image.network(
      url,
      width: s,
      height: s,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => empty(s),
    );
    if (covers.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: V2Colors.chip, borderRadius: radius),
        child: Icon(
          userListTypeIcon(type),
          size: size * 0.42,
          color: V2Colors.primary,
        ),
      );
    }
    if (covers.length == 1) {
      return ClipRRect(borderRadius: radius, child: image(covers.first, size));
    }
    final gap = size / 24;
    final cell = (size - gap) / 2;
    Widget tile(int i) =>
        i < covers.length ? image(covers[i], cell) : empty(cell);
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: size,
        height: size,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final row in const [0, 2])
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [tile(row), tile(row + 1)],
              ),
          ],
        ),
      ),
    );
  }
}

/// Leading picture of a list entry: cover, author avatar or genre/trope
/// collage.
Widget userListEntryLeading(UserListType type, UserListEntry e) {
  switch (type) {
    case UserListType.book:
    case UserListType.saga:
      return UserListCover(title: e.title, url: e.coverUrl);
    case UserListType.author:
      return UserListAuthorAvatar(
        name: e.title,
        read: e.readCount,
        total: e.bookCount,
      );
    case UserListType.genre:
    case UserListType.trope:
      return UserListCoverCollage(covers: e.covers, type: type);
  }
}

IconData userListTypeIcon(UserListType type) {
  switch (type) {
    case UserListType.book:
      return Icons.menu_book_outlined;
    case UserListType.author:
      return Icons.person_outline;
    case UserListType.saga:
      return Icons.collections_bookmark_outlined;
    case UserListType.genre:
      return Icons.category_outlined;
    case UserListType.trope:
      return Icons.local_offer_outlined;
  }
}

class UserListDetailScreen extends StatefulWidget {
  final UserList list;
  const UserListDetailScreen({super.key, required this.list});

  @override
  State<UserListDetailScreen> createState() => _UserListDetailScreenState();
}

class _UserListDetailScreenState extends State<UserListDetailScreen> {
  late UserList _list = widget.list;
  List<UserListEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = await userListRepository();
      await repo.removeOrphanItems();
      final fresh = await repo.getList(_list.listId!);
      if (fresh == null) {
        if (mounted) Navigator.pop(context);
        return;
      }
      final entries = await repo.getEntries(fresh);
      if (mounted) {
        setState(() {
          _list = fresh;
          _entries = entries;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('list detail: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setSort(UserListSortMode mode) async {
    if (mode == _list.sortMode) return;
    try {
      final repo = await userListRepository();
      // Switching to manual keeps the order currently on screen.
      if (mode == UserListSortMode.manual) {
        await repo.reorderItems(_entries.map((e) => e.itemId).toList());
      }
      await repo.setSortMode(_list.listId!, mode);
    } catch (e) {
      if (mounted) showUserListError(context, e);
    }
    _load();
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    setState(() {
      final moved = _entries.removeAt(oldIndex);
      _entries.insert(newIndex, moved);
    });
    try {
      await (await userListRepository()).reorderItems(
        _entries.map((e) => e.itemId).toList(),
      );
    } catch (e) {
      if (mounted) showUserListError(context, e);
    }
  }

  Future<void> _add() async {
    final added = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder:
            (_) => UserListItemPickerScreen(
              list: _list,
              existingKeys: {
                for (final e in _entries)
                  e.refId != null ? 'id:${e.refId}' : 'text:${e.refText}',
              },
            ),
      ),
    );
    if (!mounted) return;
    if (added != null && added > 0) {
      showUserListSnackBar(
        context,
        AppLocalizations.of(context)!.items_added(added),
      );
    }
    _load();
  }

  Future<void> _remove(UserListEntry entry) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await confirmUserListDelete(
      context,
      message: l10n.remove_from_list_confirm(entry.title),
      action: l10n.remove,
    );
    if (!ok) return;
    try {
      await (await userListRepository()).removeItem(entry.itemId);
    } catch (e) {
      if (mounted) showUserListError(context, e);
    }
    _load();
  }

  Future<void> _edit() async {
    final result = await showUserListForm(context, existing: _list);
    if (result == null || !mounted) return;
    try {
      await (await userListRepository()).updateList(
        _list.copyWith(name: result.name, icon: result.icon),
      );
      if (mounted) {
        showUserListSnackBar(context, AppLocalizations.of(context)!.list_saved);
      }
    } catch (e) {
      if (mounted) showUserListError(context, e);
    }
    _load();
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await confirmUserListDelete(
      context,
      message: l10n.delete_list_confirm(_list.name),
      action: l10n.delete,
    );
    if (!ok || !mounted) return;
    try {
      await (await userListRepository()).deleteList(_list.listId!);
      if (!mounted) return;
      showUserListSnackBar(context, l10n.list_deleted);
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showUserListError(context, e);
    }
  }

  Future<void> _open(UserListEntry entry) async {
    Widget? screen;
    switch (_list.type) {
      case UserListType.book:
        final book = await BookRepository(
          await DatabaseHelper.instance.database,
        ).getBookById(entry.refId!);
        if (book != null) screen = NewBookDetailScreen(book: book);
      case UserListType.author:
        screen = BooksByAuthorScreen(authors: [entry.title]);
      case UserListType.genre:
        screen = BooksByGenreScreen(genres: [entry.title]);
      case UserListType.trope:
        screen = BooksByGenreScreen(genres: [entry.title], tropes: true);
      case UserListType.saga:
        screen = BooksBySagaScreen(sagaName: entry.title);
    }
    if (screen == null || !mounted) return;
    final target = screen;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => target));
    _load();
  }

  String? _subtitle(AppLocalizations l10n, UserListEntry e) {
    if (_list.type == UserListType.book) return e.subtitle;
    final read = l10n.list_books_read(e.readCount, e.bookCount);
    if (e.subtitle != null && e.subtitle!.isNotEmpty) {
      return '${e.subtitle} · $read';
    }
    return read;
  }

  Widget _tile(AppLocalizations l10n, UserListEntry e, int index) {
    final manual = _list.sortMode == UserListSortMode.manual;
    final subtitle = _subtitle(l10n, e);
    return Container(
      key: ValueKey(e.itemId),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: V2Colors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: V2Colors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _open(e),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: [
              userListEntryLeading(_list.type, e),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15, color: V2Colors.primary),
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: V2Colors.textSecondary,
                        ),
                      ),
                    ],
                    if (_list.type == UserListType.genre ||
                        _list.type == UserListType.trope ||
                        _list.type == UserListType.saga) ...[
                      const SizedBox(height: 6),
                      UserListReadBar(read: e.readCount, total: e.bookCount),
                    ],
                  ],
                ),
              ),
              if (_list.type == UserListType.author)
                UserListCoverFan(covers: e.covers, title: e.title),
              IconButton(
                tooltip: l10n.remove_from_list,
                onPressed: () => _remove(e),
                icon: Icon(
                  Icons.remove_circle_outline,
                  size: 20,
                  color: V2Colors.textSecondary,
                ),
              ),
              if (manual)
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(2, 8, 8, 8),
                    child: Icon(
                      Icons.drag_handle,
                      color: V2Colors.textSecondary,
                    ),
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
    final l10n = AppLocalizations.of(context)!;
    final manual = _list.sortMode == UserListSortMode.manual;
    return Scaffold(
      backgroundColor: V2Colors.background,
      appBar: userListAppBar(
        context,
        title: Row(
          children: [
            UserListIconBadge(icon: _list.icon, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _list.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${userListTypeLabel(l10n, _list.type)} · '
                    '${l10n.list_item_count(_entries.length)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: V2Colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (!_loading && _entries.isNotEmpty)
            IconButton(
              tooltip: l10n.share_list,
              icon: const Icon(Icons.share),
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => UserListShareScreen(
                            list: _list,
                            entries: List.of(_entries),
                          ),
                    ),
                  ),
            ),
          PopupMenuButton<UserListSortMode>(
            tooltip: l10n.sort_by,
            icon: const Icon(Icons.sort),
            onSelected: _setSort,
            itemBuilder:
                (_) => [
                  for (final m in UserListSortMode.values)
                    CheckedPopupMenuItem(
                      value: m,
                      checked: m == _list.sortMode,
                      child: Text(userListSortLabel(l10n, m)),
                    ),
                ],
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') _edit();
              if (v == 'delete') _delete();
            },
            itemBuilder:
                (_) => [
                  PopupMenuItem(value: 'edit', child: Text(l10n.edit_list)),
                  PopupMenuItem(value: 'delete', child: Text(l10n.delete_list)),
                ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'user_list_add_items',
        onPressed: _add,
        tooltip: l10n.add_to_list,
        backgroundColor: V2Colors.primary,
        elevation: 6,
        shape: const CircleBorder(),
        child: Icon(Icons.add, color: V2Colors.onPrimary),
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _entries.isEmpty
              ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      userListTypeIcon(_list.type),
                      size: 48,
                      color: V2Colors.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.list_empty,
                      style: TextStyle(
                        fontSize: 16,
                        color: V2Colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.list_empty_hint,
                      style: TextStyle(
                        fontSize: 14,
                        color: V2Colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
              : manual
              ? ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 96),
                buildDefaultDragHandles: false,
                itemCount: _entries.length,
                onReorder: _reorder,
                itemBuilder: (_, i) => _tile(l10n, _entries[i], i),
              )
              : ListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 96),
                itemCount: _entries.length,
                itemBuilder: (_, i) => _tile(l10n, _entries[i], i),
              ),
    );
  }
}

/// Multi-select picker; pops with the number of items added.
class UserListItemPickerScreen extends StatefulWidget {
  final UserList list;
  final Set<String> existingKeys;

  const UserListItemPickerScreen({
    super.key,
    required this.list,
    required this.existingKeys,
  });

  @override
  State<UserListItemPickerScreen> createState() =>
      _UserListItemPickerScreenState();
}

class _UserListItemPickerScreenState extends State<UserListItemPickerScreen> {
  final TextEditingController _search = TextEditingController();
  List<UserListCandidate> _all = [];
  final Map<String, UserListCandidate> _selected = {};
  String _query = '';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final all = await (await userListRepository()).getCandidates(
        widget.list.type,
      );
      if (mounted) {
        setState(() {
          _all = all;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('list picker: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  List<UserListCandidate> get _visible {
    if (_query.isEmpty) return _all;
    final q = TextNormalizer.normalize(_query);
    return _all
        .where(
          (c) =>
              TextNormalizer.normalize(c.title).contains(q) ||
              TextNormalizer.normalize(c.subtitle).contains(q),
        )
        .toList();
  }

  Future<void> _save() async {
    if (_selected.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final added = await (await userListRepository()).addItems(
        widget.list.listId!,
        _selected.values.toList(),
      );
      if (mounted) Navigator.pop(context, added);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showUserListError(context, e);
      }
    }
  }

  Widget _row(AppLocalizations l10n, UserListCandidate c) {
    final already = widget.existingKeys.contains(c.key);
    final checked = already || _selected.containsKey(c.key);
    final subtitle =
        widget.list.type == UserListType.book
            ? c.subtitle
            : '${c.bookCount} ${l10n.books}';
    return InkWell(
      onTap:
          already
              ? null
              : () => setState(() {
                if (!_selected.containsKey(c.key)) {
                  _selected[c.key] = c;
                } else {
                  _selected.remove(c.key);
                }
              }),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Checkbox(
              value: checked,
              activeColor: already ? V2Colors.disabled : V2Colors.primary,
              onChanged:
                  already
                      ? null
                      : (v) => setState(() {
                        if (v == true) {
                          _selected[c.key] = c;
                        } else {
                          _selected.remove(c.key);
                        }
                      }),
            ),
            const SizedBox(width: 4),
            if (widget.list.type == UserListType.book) ...[
              UserListCover(
                title: c.title,
                url: c.coverUrl,
                width: 32,
                height: 44,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      color:
                          already ? V2Colors.textSecondary : V2Colors.primary,
                    ),
                  ),
                  if (already || (subtitle != null && subtitle.isNotEmpty))
                    Text(
                      already ? l10n.already_in_list : subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: V2Colors.textSecondary,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visible = _visible;
    return Scaffold(
      backgroundColor: V2Colors.background,
      appBar: userListAppBar(context, title: Text(l10n.add_to_list)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v.trim()),
              style: TextStyle(color: V2Colors.textPrimary),
              decoration: InputDecoration(
                hintText: l10n.search,
                prefixIcon: Icon(Icons.search, color: V2Colors.textSecondary),
                suffixIcon:
                    _query.isEmpty
                        ? null
                        : IconButton(
                          icon: Icon(
                            Icons.close,
                            color: V2Colors.textSecondary,
                          ),
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                        ),
                filled: true,
                fillColor: V2Colors.searchBackground,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9999),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child:
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : visible.isEmpty
                    ? Center(
                      child: Text(
                        l10n.nothing_to_add,
                        style: TextStyle(color: V2Colors.textSecondary),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: visible.length,
                      itemBuilder: (_, i) => _row(l10n, visible[i]),
                    ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _selected.isEmpty || _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: V2Colors.primary,
                    foregroundColor: V2Colors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(l10n.add_selected(_selected.length)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

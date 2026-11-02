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
  }
}

Widget _typeAvatar(UserListType type) => Container(
  width: 40,
  height: 40,
  decoration: BoxDecoration(color: V2Colors.chip, shape: BoxShape.circle),
  child: Icon(userListTypeIcon(type), size: 20, color: V2Colors.primary),
);

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
              if (_list.type == UserListType.book)
                UserListCover(title: e.title, url: e.coverUrl)
              else
                _typeAvatar(_list.type),
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
                  ],
                ),
              ),
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
              icon: const Icon(Icons.ios_share),
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

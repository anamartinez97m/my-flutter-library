import 'package:flutter/material.dart';
import 'package:myrandomlibrary/config/app_theme.dart';
import 'package:myrandomlibrary/config/v2_design_system.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/user_list.dart';
import 'package:myrandomlibrary/repositories/user_list_repository.dart';
import 'package:myrandomlibrary/screens/new_ui/user_list_detail_screen.dart';

Future<UserListRepository> userListRepository() async =>
    UserListRepository(await DatabaseHelper.instance.database);

String userListTypeLabel(AppLocalizations l10n, UserListType type) {
  switch (type) {
    case UserListType.book:
      return l10n.list_type_books;
    case UserListType.author:
      return l10n.list_type_authors;
    case UserListType.saga:
      return l10n.list_type_sagas;
    case UserListType.genre:
      return l10n.list_type_genres;
    case UserListType.trope:
      return l10n.list_type_tropes;
  }
}

class UserListIconBadge extends StatelessWidget {
  final String icon;
  final double size;
  final bool selected;

  const UserListIconBadge({
    super.key,
    required this.icon,
    this.size = 40,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: selected ? V2Colors.primary : V2Colors.chip,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? V2Colors.primary : V2Colors.border,
        ),
      ),
      child: Icon(
        userListIcon(icon),
        size: size * 0.5,
        color: selected ? V2Colors.onPrimary : V2Colors.primary,
      ),
    );
  }
}

PreferredSizeWidget userListAppBar(
  BuildContext context, {
  required Widget title,
  List<Widget>? actions,
}) {
  return AppBar(
    backgroundColor: V2Colors.background,
    elevation: 0,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    leading: IconButton(
      onPressed: () => Navigator.pop(context),
      icon: Icon(Icons.arrow_back, color: V2Colors.primary),
    ),
    titleSpacing: 0,
    title: DefaultTextStyle.merge(
      style: TextStyle(fontSize: 18, color: V2Colors.primary),
      child: title,
    ),
    iconTheme: IconThemeData(color: V2Colors.primary),
    actionsIconTheme: IconThemeData(color: V2Colors.primary),
    actions: actions,
  );
}

void showUserListSnackBar(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), backgroundColor: AppTheme.notificationColor),
  );
}

void showUserListError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Error: $error'),
      backgroundColor: Theme.of(context).colorScheme.error,
    ),
  );
}

Future<bool> confirmUserListDelete(
  BuildContext context, {
  required String message,
  required String action,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final ok = await showDialog<bool>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          title: Text(l10n.confirm_delete_title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
                foregroundColor: Theme.of(ctx).colorScheme.onError,
              ),
              child: Text(action),
            ),
          ],
        ),
  );
  return ok == true;
}

class UserListFormResult {
  final String name;
  final UserListType type;
  final String icon;

  const UserListFormResult(this.name, this.type, this.icon);
}

/// Create (when [existing] is null) or edit a list's name and icon. The type
/// is fixed once the list exists.
Future<UserListFormResult?> showUserListForm(
  BuildContext context, {
  UserList? existing,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showModalBottomSheet<UserListFormResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: V2Colors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _UserListForm(existing: existing),
  );
}

class _UserListForm extends StatefulWidget {
  final UserList? existing;
  const _UserListForm({this.existing});

  @override
  State<_UserListForm> createState() => _UserListFormState();
}

class _UserListFormState extends State<_UserListForm> {
  late final TextEditingController _name = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late UserListType _type = widget.existing?.type ?? UserListType.book;
  late String _icon = widget.existing?.icon ?? defaultUserListIcon;
  bool _showNameError = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _showNameError = true);
      return;
    }
    Navigator.pop(context, UserListFormResult(name, _type, _icon));
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: V2Colors.textPrimary,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final editing = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                editing ? l10n.edit_list : l10n.new_list,
                style: TextStyle(fontSize: 20, color: V2Colors.primary),
              ),
              const SizedBox(height: 20),
              _label(l10n.list_name),
              TextField(
                controller: _name,
                autofocus: !editing,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 100,
                style: TextStyle(color: V2Colors.textPrimary),
                onChanged: (_) {
                  if (_showNameError) setState(() => _showNameError = false);
                },
                onSubmitted: (_) => _save(),
                decoration: InputDecoration(
                  counterText: '',
                  errorText: _showNameError ? l10n.list_name_required : null,
                  filled: true,
                  fillColor: V2Colors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: V2Colors.borderInput),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: V2Colors.borderInput),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: V2Colors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _label(l10n.list_type),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in UserListType.values)
                    ChoiceChip(
                      label: Text(userListTypeLabel(l10n, t)),
                      selected: _type == t,
                      showCheckmark: false,
                      selectedColor: V2Colors.primary,
                      backgroundColor: V2Colors.chip,
                      side: BorderSide(color: V2Colors.border),
                      labelStyle: TextStyle(
                        color:
                            _type == t
                                ? V2Colors.onPrimary
                                : V2Colors.textPrimary,
                      ),
                      onSelected:
                          editing ? null : (_) => setState(() => _type = t),
                    ),
                ],
              ),
              if (editing) ...[
                const SizedBox(height: 6),
                Text(
                  l10n.list_type_locked,
                  style: TextStyle(fontSize: 12, color: V2Colors.textSecondary),
                ),
              ],
              const SizedBox(height: 20),
              _label(l10n.list_icon),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final key in userListIcons.keys)
                    GestureDetector(
                      onTap: () => setState(() => _icon = key),
                      child: UserListIconBadge(
                        icon: key,
                        size: 40,
                        selected: _icon == key,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      l10n.cancel,
                      style: TextStyle(color: V2Colors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: V2Colors.primary,
                      foregroundColor: V2Colors.onPrimary,
                    ),
                    child: Text(editing ? l10n.save : l10n.create),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Creates a list from the form and opens it. Returns true if one was created.
Future<bool> createUserListAndOpen(BuildContext context) async {
  final result = await showUserListForm(context);
  if (result == null || !context.mounted) return false;
  try {
    final repo = await userListRepository();
    final id = await repo.createList(
      name: result.name,
      type: result.type,
      icon: result.icon,
    );
    final list = await repo.getList(id);
    if (list == null || !context.mounted) return true;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserListDetailScreen(list: list)),
    );
  } catch (e) {
    if (context.mounted) showUserListError(context, e);
  }
  return true;
}

class UserListsScreen extends StatefulWidget {
  const UserListsScreen({super.key});

  @override
  State<UserListsScreen> createState() => _UserListsScreenState();
}

class _UserListsScreenState extends State<UserListsScreen> {
  List<UserList> _lists = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final lists = await (await userListRepository()).getLists();
      if (mounted) {
        setState(() {
          _lists = lists;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('lists: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    await createUserListAndOpen(context);
    _load();
  }

  Future<void> _open(UserList list) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserListDetailScreen(list: list)),
    );
    _load();
  }

  Future<void> _edit(UserList list) async {
    final result = await showUserListForm(context, existing: list);
    if (result == null || !mounted) return;
    try {
      await (await userListRepository()).updateList(
        list.copyWith(name: result.name, icon: result.icon),
      );
      if (mounted) {
        showUserListSnackBar(context, AppLocalizations.of(context)!.list_saved);
      }
    } catch (e) {
      if (mounted) showUserListError(context, e);
    }
    _load();
  }

  Future<void> _delete(UserList list) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await confirmUserListDelete(
      context,
      message: l10n.delete_list_confirm(list.name),
      action: l10n.delete,
    );
    if (!ok || !mounted) return;
    try {
      await (await userListRepository()).deleteList(list.listId!);
      if (mounted) showUserListSnackBar(context, l10n.list_deleted);
    } catch (e) {
      if (mounted) showUserListError(context, e);
    }
    _load();
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    setState(() {
      final moved = _lists.removeAt(oldIndex);
      _lists.insert(newIndex, moved);
    });
    try {
      await (await userListRepository()).reorderLists(
        _lists.map((l) => l.listId!).toList(),
      );
    } catch (e) {
      if (mounted) showUserListError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: V2Colors.background,
      appBar: userListAppBar(context, title: Text(l10n.lists)),
      floatingActionButton: FloatingActionButton(
        heroTag: 'user_lists_add',
        onPressed: _create,
        tooltip: l10n.new_list,
        backgroundColor: V2Colors.primary,
        elevation: 6,
        shape: const CircleBorder(),
        child: Icon(Icons.add, color: V2Colors.onPrimary),
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _lists.isEmpty
              ? UserListsEmptyState(onCreate: _create)
              : ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 96),
                buildDefaultDragHandles: false,
                itemCount: _lists.length,
                onReorder: _reorder,
                itemBuilder: (ctx, i) {
                  final list = _lists[i];
                  return Container(
                    key: ValueKey(list.listId),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: V2Colors.border),
                    ),
                    child: ListTile(
                      onTap: () => _open(list),
                      contentPadding: const EdgeInsets.only(left: 12),
                      leading: UserListIconBadge(icon: list.icon),
                      title: Text(
                        list.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16, color: V2Colors.primary),
                      ),
                      subtitle: Text(
                        '${userListTypeLabel(l10n, list.type)} · '
                        '${l10n.list_item_count(list.itemCount)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: V2Colors.textSecondary,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert,
                              color: V2Colors.textSecondary,
                            ),
                            onSelected: (v) {
                              if (v == 'edit') _edit(list);
                              if (v == 'delete') _delete(list);
                            },
                            itemBuilder:
                                (_) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text(l10n.edit_list),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text(l10n.delete_list),
                                  ),
                                ],
                          ),
                          ReorderableDragStartListener(
                            index: i,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
                              child: Icon(
                                Icons.drag_handle,
                                color: V2Colors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}

class UserListsEmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const UserListsEmptyState({super.key, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.format_list_bulleted,
              size: 48,
              color: V2Colors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.no_lists_yet,
              style: TextStyle(fontSize: 16, color: V2Colors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.lists_hint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: V2Colors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onCreate,
              icon: Icon(Icons.add, color: V2Colors.primary),
              label: Text(
                l10n.new_list,
                style: TextStyle(color: V2Colors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

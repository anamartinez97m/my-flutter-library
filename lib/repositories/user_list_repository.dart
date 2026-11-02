import 'package:myrandomlibrary/discovery/text/text_normalizer.dart';
import 'package:myrandomlibrary/model/user_list.dart';
import 'package:sqflite/sqflite.dart';

class UserListRepository {
  final DatabaseExecutor db;

  UserListRepository(this.db);

  static const _authorsOfBook = '''
    (SELECT GROUP_CONCAT(a.name, ', ')
     FROM books_by_author ba
     INNER JOIN author a ON ba.author_id = a.author_id
     WHERE ba.book_id = b.book_id)''';

  // ── Lists ────────────────────────────────────────────────────────────────

  Future<List<UserList>> getLists() async {
    await removeOrphanItems();
    final rows = await db.rawQuery('''
      SELECT l.*,
        (SELECT COUNT(*) FROM user_list_items i WHERE i.list_id = l.list_id)
          AS item_count
      FROM user_lists l
      ORDER BY l.position ASC, l.list_id ASC
    ''');
    return rows.map(UserList.fromMap).toList();
  }

  Future<UserList?> getList(int listId) async {
    final rows = await db.rawQuery(
      '''
      SELECT l.*,
        (SELECT COUNT(*) FROM user_list_items i WHERE i.list_id = l.list_id)
          AS item_count
      FROM user_lists l
      WHERE l.list_id = ?
    ''',
      [listId],
    );
    return rows.isEmpty ? null : UserList.fromMap(rows.first);
  }

  Future<int> createList({
    required String name,
    required UserListType type,
    required String icon,
  }) async {
    final maxRow = await db.rawQuery(
      'SELECT MAX(position) AS max_pos FROM user_lists',
    );
    final next = ((maxRow.first['max_pos'] as num?)?.toInt() ?? -1) + 1;
    return db.insert('user_lists', {
      'name': name.trim(),
      'list_type': type.dbValue,
      'icon': icon,
      'sort_mode': UserListSortMode.manual.dbValue,
      'position': next,
    });
  }

  Future<void> updateList(UserList list) async {
    await db.update(
      'user_lists',
      {
        'name': list.name.trim(),
        'icon': list.icon,
        'sort_mode': list.sortMode.dbValue,
      },
      where: 'list_id = ?',
      whereArgs: [list.listId],
    );
  }

  Future<void> setSortMode(int listId, UserListSortMode mode) async {
    await db.update(
      'user_lists',
      {'sort_mode': mode.dbValue},
      where: 'list_id = ?',
      whereArgs: [listId],
    );
  }

  /// PRAGMA foreign_keys is OFF, so items are deleted explicitly.
  Future<void> deleteList(int listId) async {
    await db.delete(
      'user_list_items',
      where: 'list_id = ?',
      whereArgs: [listId],
    );
    await db.delete('user_lists', where: 'list_id = ?', whereArgs: [listId]);
  }

  Future<void> reorderLists(List<int> listIds) async {
    final batch = db.batch();
    for (var i = 0; i < listIds.length; i++) {
      batch.update(
        'user_lists',
        {'position': i},
        where: 'list_id = ?',
        whereArgs: [listIds[i]],
      );
    }
    await batch.commit(noResult: true);
  }

  // ── Items ────────────────────────────────────────────────────────────────

  Future<List<UserListEntry>> getEntries(UserList list) async {
    final rows = await db.rawQuery(_entriesQuery(list.type), [list.listId]);
    final entries =
        rows
            .map(
              (r) => UserListEntry(
                itemId: r['item_id'] as int,
                refId: (r['ref_id'] as num?)?.toInt(),
                refText: r['ref_text'] as String?,
                title: (r['title'] as String?) ?? '',
                subtitle: r['subtitle'] as String?,
                coverUrl: r['cover_url'] as String?,
                position: (r['position'] as num?)?.toInt() ?? 0,
                addedAt: r['added_at'] as String?,
                bookCount: (r['book_count'] as num?)?.toInt() ?? 0,
                readCount: (r['read_count'] as num?)?.toInt() ?? 0,
              ),
            )
            .toList();
    return sortEntries(entries, list.sortMode);
  }

  static List<UserListEntry> sortEntries(
    List<UserListEntry> entries,
    UserListSortMode mode,
  ) {
    int byName(UserListEntry a, UserListEntry b) {
      final c = TextNormalizer.normalize(
        a.title,
      ).compareTo(TextNormalizer.normalize(b.title));
      return c != 0 ? c : a.itemId.compareTo(b.itemId);
    }

    int byAdded(UserListEntry a, UserListEntry b) {
      final c = (a.addedAt ?? '').compareTo(b.addedAt ?? '');
      return c != 0 ? c : a.itemId.compareTo(b.itemId);
    }

    final sorted = List<UserListEntry>.from(entries);
    switch (mode) {
      case UserListSortMode.manual:
        sorted.sort((a, b) {
          final c = a.position.compareTo(b.position);
          return c != 0 ? c : a.itemId.compareTo(b.itemId);
        });
      case UserListSortMode.nameAsc:
        sorted.sort(byName);
      case UserListSortMode.nameDesc:
        sorted.sort((a, b) => byName(b, a));
      case UserListSortMode.oldest:
        sorted.sort(byAdded);
      case UserListSortMode.newest:
        sorted.sort((a, b) => byAdded(b, a));
    }
    return sorted;
  }

  String _entriesQuery(UserListType type) {
    switch (type) {
      case UserListType.book:
        return '''
          SELECT i.*, b.name AS title, b.cover_url AS cover_url,
            $_authorsOfBook AS subtitle
          FROM user_list_items i
          INNER JOIN book b ON b.book_id = i.ref_id
          WHERE i.list_id = ?
        ''';
      case UserListType.author:
        return '''
          SELECT i.*, a.name AS title,
            (SELECT COUNT(*) FROM books_by_author ba
             WHERE ba.author_id = a.author_id) AS book_count,
            (SELECT COUNT(*) FROM books_by_author ba
             INNER JOIN book b ON b.book_id = ba.book_id
             INNER JOIN status s ON s.status_id = b.status_id
             WHERE ba.author_id = a.author_id AND s.value = 'Yes') AS read_count
          FROM user_list_items i
          INNER JOIN author a ON a.author_id = i.ref_id
          WHERE i.list_id = ?
        ''';
      case UserListType.genre:
        return '''
          SELECT i.*, g.name AS title,
            (SELECT COUNT(*) FROM books_by_genre bg
             WHERE bg.genre_id = g.genre_id) AS book_count,
            (SELECT COUNT(*) FROM books_by_genre bg
             INNER JOIN book b ON b.book_id = bg.book_id
             INNER JOIN status s ON s.status_id = b.status_id
             WHERE bg.genre_id = g.genre_id AND s.value = 'Yes') AS read_count
          FROM user_list_items i
          INNER JOIN genre g ON g.genre_id = i.ref_id
          WHERE i.list_id = ?
        ''';
      case UserListType.saga:
        return '''
          SELECT i.*, i.ref_text AS title,
            (SELECT COUNT(*) FROM book b WHERE b.saga = i.ref_text)
              AS book_count,
            (SELECT COUNT(*) FROM book b
             INNER JOIN status s ON s.status_id = b.status_id
             WHERE b.saga = i.ref_text AND s.value = 'Yes') AS read_count,
            (SELECT GROUP_CONCAT(DISTINCT b.saga_universe) FROM book b
             WHERE b.saga = i.ref_text AND b.saga_universe IS NOT NULL
               AND b.saga_universe != '') AS subtitle
          FROM user_list_items i
          WHERE i.list_id = ?
        ''';
    }
  }

  /// Adds the candidates that aren't in the list yet, after the last item.
  Future<int> addItems(int listId, List<UserListCandidate> candidates) async {
    if (candidates.isEmpty) return 0;
    final existing = await db.query(
      'user_list_items',
      columns: ['ref_id', 'ref_text', 'position'],
      where: 'list_id = ?',
      whereArgs: [listId],
    );
    final keys = <String>{
      for (final r in existing)
        r['ref_id'] != null ? 'id:${r['ref_id']}' : 'text:${r['ref_text']}',
    };
    var next =
        existing.fold<int>(
          -1,
          (m, r) =>
              ((r['position'] as num?)?.toInt() ?? 0) > m
                  ? (r['position'] as num).toInt()
                  : m,
        ) +
        1;
    var added = 0;
    final batch = db.batch();
    for (final c in candidates) {
      if (!keys.add(c.key)) continue;
      batch.insert('user_list_items', {
        'list_id': listId,
        'ref_id': c.refId,
        'ref_text': c.refText,
        'position': next++,
      });
      added++;
    }
    await batch.commit(noResult: true);
    return added;
  }

  Future<void> removeItem(int itemId) async {
    await db.delete(
      'user_list_items',
      where: 'item_id = ?',
      whereArgs: [itemId],
    );
  }

  Future<void> reorderItems(List<int> itemIds) async {
    final batch = db.batch();
    for (var i = 0; i < itemIds.length; i++) {
      batch.update(
        'user_list_items',
        {'position': i},
        where: 'item_id = ?',
        whereArgs: [itemIds[i]],
      );
    }
    await batch.commit(noResult: true);
  }

  // ── Candidates ───────────────────────────────────────────────────────────

  Future<List<UserListCandidate>> getCandidates(UserListType type) async {
    switch (type) {
      case UserListType.book:
        final rows = await db.rawQuery('''
          SELECT b.book_id, b.name, b.cover_url, $_authorsOfBook AS authors
          FROM book b
          WHERE b.name IS NOT NULL AND b.name != ''
        ''');
        return _sortCandidates(
          rows.map(
            (r) => UserListCandidate(
              refId: r['book_id'] as int,
              title: r['name'] as String,
              subtitle: r['authors'] as String?,
              coverUrl: r['cover_url'] as String?,
            ),
          ),
        );
      case UserListType.author:
        final rows = await db.rawQuery('''
          SELECT a.author_id AS id, a.name,
            (SELECT COUNT(*) FROM books_by_author ba
             WHERE ba.author_id = a.author_id) AS book_count
          FROM author a
          WHERE a.name IS NOT NULL AND a.name != ''
        ''');
        return _sortCandidates(rows.map(_idCandidate));
      case UserListType.genre:
        final rows = await db.rawQuery('''
          SELECT g.genre_id AS id, g.name,
            (SELECT COUNT(*) FROM books_by_genre bg
             WHERE bg.genre_id = g.genre_id) AS book_count
          FROM genre g
          WHERE g.name IS NOT NULL AND g.name != ''
        ''');
        return _sortCandidates(rows.map(_idCandidate));
      case UserListType.saga:
        final rows = await db.rawQuery('''
          SELECT name, SUM(n) AS book_count FROM (
            SELECT b.saga AS name, 1 AS n FROM book b
            WHERE b.saga IS NOT NULL AND b.saga != ''
            UNION ALL
            SELECT m.value AS name, 0 AS n FROM dropdown_subtitle_metadata m
            WHERE m.category = 'saga' AND m.value IS NOT NULL AND m.value != ''
          )
          GROUP BY name
        ''');
        return _sortCandidates(
          rows.map(
            (r) => UserListCandidate(
              refText: r['name'] as String,
              title: r['name'] as String,
              bookCount: (r['book_count'] as num?)?.toInt() ?? 0,
            ),
          ),
        );
    }
  }

  UserListCandidate _idCandidate(Map<String, Object?> r) => UserListCandidate(
    refId: r['id'] as int,
    title: r['name'] as String,
    bookCount: (r['book_count'] as num?)?.toInt() ?? 0,
  );

  List<UserListCandidate> _sortCandidates(
    Iterable<UserListCandidate> candidates,
  ) {
    final list = candidates.toList();
    list.sort(
      (a, b) => TextNormalizer.normalize(
        a.title,
      ).compareTo(TextNormalizer.normalize(b.title)),
    );
    return list;
  }

  // ── Keeping items in sync with the library ───────────────────────────────

  /// Drops items whose book/author/genre/saga no longer exists. Deleting is
  /// done here rather than in `deleteBook`, because CSV import updates books
  /// by deleting and re-adding them with the same id.
  Future<void> removeOrphanItems() async {
    await db.rawDelete('''
      DELETE FROM user_list_items
      WHERE list_id NOT IN (SELECT list_id FROM user_lists)
        OR (list_id IN (SELECT list_id FROM user_lists WHERE list_type = 'book')
            AND ref_id NOT IN (SELECT book_id FROM book))
        OR (list_id IN (SELECT list_id FROM user_lists WHERE list_type = 'author')
            AND ref_id NOT IN (SELECT author_id FROM author))
        OR (list_id IN (SELECT list_id FROM user_lists WHERE list_type = 'genre')
            AND ref_id NOT IN (SELECT genre_id FROM genre))
        OR (list_id IN (SELECT list_id FROM user_lists WHERE list_type = 'saga')
            AND ref_text NOT IN (
              SELECT saga FROM book WHERE saga IS NOT NULL
              UNION
              SELECT value FROM dropdown_subtitle_metadata
              WHERE category = 'saga'))
    ''');
  }

  /// Points author/genre items at [newId] after a lookup value is replaced.
  Future<void> replaceRefId(UserListType type, int oldId, int newId) async {
    await db.rawUpdate(
      '''
      UPDATE user_list_items SET ref_id = ?
      WHERE ref_id = ?
        AND list_id IN (SELECT list_id FROM user_lists WHERE list_type = ?)
    ''',
      [newId, oldId, type.dbValue],
    );
    await _removeDuplicates();
  }

  /// Keeps saga items when a saga is renamed or replaced.
  Future<void> renameSaga(String oldName, String newName) async {
    if (oldName == newName) return;
    await db.rawUpdate(
      '''
      UPDATE user_list_items SET ref_text = ?
      WHERE ref_text = ?
        AND list_id IN (SELECT list_id FROM user_lists WHERE list_type = 'saga')
    ''',
      [newName, oldName],
    );
    await _removeDuplicates();
  }

  Future<void> _removeDuplicates() async {
    await db.rawDelete('''
      DELETE FROM user_list_items
      WHERE item_id NOT IN (
        SELECT MIN(item_id) FROM user_list_items
        GROUP BY list_id, IFNULL(ref_id, -1), IFNULL(ref_text, '')
      )
    ''');
  }
}

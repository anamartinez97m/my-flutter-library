import 'package:flutter/material.dart';

enum UserListType { book, author, saga, genre }

extension UserListTypeDb on UserListType {
  String get dbValue => name;

  static UserListType fromDb(String? value) => UserListType.values.firstWhere(
    (t) => t.name == value,
    orElse: () => UserListType.book,
  );
}

extension UserListTypeCovers on UserListType {
  /// Book lists show the book's cover; saga lists show one of the saga's.
  bool get showsCovers =>
      this == UserListType.book || this == UserListType.saga;
}

enum UserListSortMode { manual, nameAsc, nameDesc, newest, oldest }

extension UserListSortModeDb on UserListSortMode {
  String get dbValue => name;

  static UserListSortMode fromDb(String? value) =>
      UserListSortMode.values.firstWhere(
        (m) => m.name == value,
        orElse: () => UserListSortMode.manual,
      );
}

/// Icons a list can use, stored by key so the DB never holds code points.
const Map<String, IconData> userListIcons = {
  'list': Icons.format_list_bulleted,
  'star': Icons.star_outline,
  'favorite': Icons.favorite_border,
  'bookmark': Icons.bookmark_outline,
  'book': Icons.menu_book_outlined,
  'library': Icons.local_library_outlined,
  'person': Icons.person_outline,
  'group': Icons.groups_outlined,
  'trophy': Icons.emoji_events_outlined,
  'fire': Icons.local_fire_department_outlined,
  'magic': Icons.auto_awesome_outlined,
  'heart_broken': Icons.heart_broken_outlined,
  'castle': Icons.castle_outlined,
  'rocket': Icons.rocket_launch_outlined,
  'search': Icons.search,
  'skull': Icons.dangerous_outlined,
  'pets': Icons.pets_outlined,
  'flower': Icons.local_florist_outlined,
  'sun': Icons.wb_sunny_outlined,
  'moon': Icons.dark_mode_outlined,
  'snow': Icons.ac_unit,
  'coffee': Icons.local_cafe_outlined,
  'travel': Icons.flight_outlined,
  'music': Icons.music_note_outlined,
  'movie': Icons.movie_outlined,
  'gift': Icons.card_giftcard_outlined,
  'school': Icons.school_outlined,
  'category': Icons.category_outlined,
};

const String defaultUserListIcon = 'list';

IconData userListIcon(String? key) =>
    userListIcons[key] ?? userListIcons[defaultUserListIcon]!;

class UserList {
  final int? listId;
  final String name;
  final UserListType type;
  final String icon;
  final UserListSortMode sortMode;
  final int position;
  final int itemCount;

  const UserList({
    this.listId,
    required this.name,
    required this.type,
    this.icon = defaultUserListIcon,
    this.sortMode = UserListSortMode.manual,
    this.position = 0,
    this.itemCount = 0,
  });

  factory UserList.fromMap(Map<String, dynamic> map) => UserList(
    listId: map['list_id'] as int?,
    name: map['name'] as String? ?? '',
    type: UserListTypeDb.fromDb(map['list_type'] as String?),
    icon: map['icon'] as String? ?? defaultUserListIcon,
    sortMode: UserListSortModeDb.fromDb(map['sort_mode'] as String?),
    position: (map['position'] as num?)?.toInt() ?? 0,
    itemCount: (map['item_count'] as num?)?.toInt() ?? 0,
  );

  UserList copyWith({String? name, String? icon, UserListSortMode? sortMode}) =>
      UserList(
        listId: listId,
        name: name ?? this.name,
        type: type,
        icon: icon ?? this.icon,
        sortMode: sortMode ?? this.sortMode,
        position: position,
        itemCount: itemCount,
      );
}

/// One row of a list, resolved against the book/author/genre/saga it points to.
class UserListEntry {
  final int itemId;
  final int? refId;
  final String? refText;
  final String title;
  final String? subtitle;
  final String? coverUrl;
  final int position;
  final String? addedAt;

  /// Books in the library for an author/genre/saga entry.
  final int bookCount;

  /// Read books (status "Yes") for an author/genre/saga entry.
  final int readCount;

  const UserListEntry({
    required this.itemId,
    this.refId,
    this.refText,
    required this.title,
    this.subtitle,
    this.coverUrl,
    this.position = 0,
    this.addedAt,
    this.bookCount = 0,
    this.readCount = 0,
  });
}

/// Something that can be added to a list of the matching type.
class UserListCandidate {
  final int? refId;
  final String? refText;
  final String title;
  final String? subtitle;
  final String? coverUrl;
  final int bookCount;

  const UserListCandidate({
    this.refId,
    this.refText,
    required this.title,
    this.subtitle,
    this.coverUrl,
    this.bookCount = 0,
  });

  String get key => refId != null ? 'id:$refId' : 'text:$refText';
}

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:myrandomlibrary/config/v2_design_system.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/user_list.dart';
import 'package:myrandomlibrary/screens/new_ui/user_list_detail_screen.dart';
import 'package:myrandomlibrary/screens/new_ui/user_lists_screen.dart';
import 'package:share_plus/share_plus.dart';

const _maxShareItems = 60;

/// Preview of a list rendered as an image card, shared as a PNG.
class UserListShareScreen extends StatefulWidget {
  final UserList list;
  final List<UserListEntry> entries;

  const UserListShareScreen({
    super.key,
    required this.list,
    required this.entries,
  });

  @override
  State<UserListShareScreen> createState() => _UserListShareScreenState();
}

class _UserListShareScreenState extends State<UserListShareScreen> {
  final _cardKey = GlobalKey();
  bool _ready = false;
  bool _sharing = false;
  bool _precacheStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precacheStarted) {
      _precacheStarted = true;
      _precacheCovers();
    }
  }

  // Covers must be decoded before the card is captured, or they come out blank.
  Future<void> _precacheCovers() async {
    final urls =
        widget.entries
            .take(_maxShareItems)
            .map((e) => e.coverUrl)
            .whereType<String>()
            .where((u) => u.isNotEmpty)
            .toSet();
    await Future.wait(
      urls.map(
        (u) => precacheImage(
          NetworkImage(u),
          context,
          onError: (_, __) {},
        ).timeout(const Duration(seconds: 10), onTimeout: () {}),
      ),
    );
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _share(Rect origin) async {
    setState(() => _sharing = true);
    try {
      final boundary =
          _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final fileName = '${_fileName(widget.list.name)}.png';
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              data!.buffer.asUint8List(),
              mimeType: 'image/png',
              name: fileName,
            ),
          ],
          fileNameOverrides: [fileName],
          text: widget.list.name,
          sharePositionOrigin: origin,
        ),
      );
    } catch (e) {
      if (mounted) showUserListError(context, e);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  String _fileName(String name) {
    final cleaned = name
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    return cleaned.isEmpty ? 'list' : cleaned;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: V2Colors.surface,
      appBar: userListAppBar(context, title: Text(l10n.share_list)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: RepaintBoundary(
              key: _cardKey,
              child: UserListShareCard(
                list: widget.list,
                entries: widget.entries,
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Builder(
            builder:
                (buttonContext) => FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: V2Colors.primary,
                    foregroundColor: V2Colors.onPrimary,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed:
                      !_ready || _sharing
                          ? null
                          : () {
                            final box =
                                buttonContext.findRenderObject() as RenderBox;
                            _share(box.localToGlobal(Offset.zero) & box.size);
                          },
                  icon:
                      _ready && !_sharing
                          ? const Icon(Icons.ios_share)
                          : SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: V2Colors.onPrimary,
                            ),
                          ),
                  label: Text(
                    _ready ? l10n.share_list_image : l10n.share_list_preparing,
                  ),
                ),
          ),
        ),
      ),
    );
  }
}

/// The shareable card: list header, a grid of items and the app name.
class UserListShareCard extends StatelessWidget {
  final UserList list;
  final List<UserListEntry> entries;
  static const double width = 360;
  static const double _padding = 20;
  static const double _gap = 10;

  const UserListShareCard({
    super.key,
    required this.list,
    required this.entries,
  });

  int get _columns {
    final n = entries.length;
    if (n <= 9) return 3;
    if (n <= 24) return 4;
    return 5;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final shown = entries.take(_maxShareItems).toList();
    final hidden = entries.length - shown.length;
    final tileWidth = (width - _padding * 2 - _gap * (_columns - 1)) / _columns;
    return DefaultTextStyle(
      style: TextStyle(
        fontFamily: V2Typography.family,
        color: V2Colors.textPrimary,
      ),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(_padding),
        decoration: BoxDecoration(
          color: V2Colors.background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserListIconBadge(icon: list.icon, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        list.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: V2Colors.primary,
                        ),
                      ),
                      Text(
                        '${userListTypeLabel(l10n, list.type)} · '
                        '${l10n.list_item_count(entries.length)}',
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
            const SizedBox(height: 16),
            Wrap(
              spacing: _gap,
              runSpacing: _gap + 2,
              children: [
                for (final e in shown)
                  SizedBox(
                    width: tileWidth,
                    child:
                        list.type == UserListType.book
                            ? _BookTile(entry: e, width: tileWidth)
                            : _NameTile(
                              entry: e,
                              type: list.type,
                              width: tileWidth,
                            ),
                  ),
                if (hidden > 0)
                  SizedBox(
                    width: tileWidth,
                    height:
                        list.type == UserListType.book
                            ? tileWidth * 1.5
                            : tileWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        color: V2Colors.chip,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '+$hidden',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: V2Colors.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_stories_outlined,
                    size: 14,
                    color: V2Colors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.app_title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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
}

class _BookTile extends StatelessWidget {
  final UserListEntry entry;
  final double width;

  const _BookTile({required this.entry, required this.width});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UserListCover(
          title: entry.title,
          url: entry.coverUrl,
          width: width,
          height: width * 1.5,
        ),
        const SizedBox(height: 4),
        Text(
          entry.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _NameTile extends StatelessWidget {
  final UserListEntry entry;
  final UserListType type;
  final double width;

  const _NameTile({
    required this.entry,
    required this.type,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: width,
      height: width,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: V2Colors.chip,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(userListTypeIcon(type), size: 18, color: V2Colors.primary),
          const SizedBox(height: 4),
          Text(
            entry.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: V2Colors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.list_books_read(entry.readCount, entry.bookCount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 9, color: V2Colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

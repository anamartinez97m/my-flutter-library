import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';

// ── v2 design tokens ─────────────────────────────────────────────────────────
const _kBg = Color(0xFFFDF8F6);
const _kPrimary = Color(0xFF43102B);
const _kSub = Color(0xFF514348);
const _kText = Color(0xFF1C1B1A);
const _kBorder = Color(0xFFD5C2C7);
const _kSecondary = Color(0xFF5D2641);

class ManageClubNamesScreen extends StatefulWidget {
  final bool useNewUi;
  const ManageClubNamesScreen({super.key, this.useNewUi = false});

  @override
  State<ManageClubNamesScreen> createState() => _ManageClubNamesScreenState();
}

class _ManageClubNamesScreenState extends State<ManageClubNamesScreen> {
  List<Map<String, dynamic>> _clubs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  Future<void> _loadClubs() async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Get all clubs with their book counts
      final result = await db.rawQuery('''
        SELECT 
          club_name,
          COUNT(*) as book_count,
          AVG(reading_progress) as avg_progress
        FROM reading_clubs
        GROUP BY club_name
        ORDER BY club_name ASC
      ''');

      if (mounted) {
        setState(() {
          _clubs = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading clubs: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showRenameDialog(String oldName) async {
    final newName =
        widget.useNewUi
            ? await _showV2RenameDialog(oldName)
            : await _showV1RenameDialog(oldName);

    if (newName != null && newName != oldName) {
      try {
        final db = await DatabaseHelper.instance.database;

        // Check if new name already exists
        final existing = await db.query(
          'reading_clubs',
          where: 'club_name = ?',
          whereArgs: [newName],
          limit: 1,
        );

        if (existing.isNotEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.club_already_exists(newName),
                ),
                backgroundColor:
                    widget.useNewUi
                        ? const Color(0xFFB3261E)
                        : Theme.of(context).colorScheme.secondary,
              ),
            );
          }
          return;
        }

        // Rename all instances
        await db.update(
          'reading_clubs',
          {'club_name': newName},
          where: 'club_name = ?',
          whereArgs: [oldName],
        );

        await _loadClubs();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.renamed_club(oldName, newName),
              ),
              backgroundColor:
                  widget.useNewUi
                      ? _kPrimary
                      : Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppLocalizations.of(context)!.error}: $e'),
              backgroundColor:
                  widget.useNewUi
                      ? const Color(0xFFB3261E)
                      : Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<String?> _showV1RenameDialog(String oldName) async {
    final controller = TextEditingController(text: oldName);

    return showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.rename_club),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.club_name,
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = controller.text.trim();
                  if (name.isNotEmpty && name != oldName) {
                    Navigator.of(context).pop(name);
                  }
                },
                child: Text(AppLocalizations.of(context)!.rename),
              ),
            ],
          ),
    );
  }

  Future<String?> _showV2RenameDialog(String oldName) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: oldName);

    return showDialog<String>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: _kBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 25,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 384),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.edit_outlined,
                            color: _kPrimary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            l10n.rename_club,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: _kPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: controller,
                        autofocus: true,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 18,
                          color: _kText,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.club_name,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: _kSub),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: _kSub),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: _kPrimary,
                              width: 2,
                            ),
                          ),
                          labelStyle: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            color: _kPrimary,
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: const BoxDecoration(
                    color: _kBg,
                    border: Border(top: BorderSide(color: _kBorder)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: _kPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n.cancel,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final name = controller.text.trim();
                          if (name.isNotEmpty && name != oldName) {
                            Navigator.of(context).pop(name);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n.rename,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteClub(String clubName, int bookCount) async {
    final confirmed =
        widget.useNewUi
            ? await _showV2DeleteDialog(clubName, bookCount)
            : await _showV1DeleteDialog(clubName, bookCount);

    if (confirmed == true) {
      try {
        final db = await DatabaseHelper.instance.database;

        // Delete all books from this club
        await db.delete(
          'reading_clubs',
          where: 'club_name = ?',
          whereArgs: [clubName],
        );

        await _loadClubs();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.deleted_value(clubName),
              ),
              backgroundColor:
                  widget.useNewUi
                      ? _kPrimary
                      : Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppLocalizations.of(context)!.error}: $e'),
              backgroundColor:
                  widget.useNewUi
                      ? const Color(0xFFB3261E)
                      : Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<bool?> _showV1DeleteDialog(String clubName, int bookCount) async {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.delete_club),
            content: Text(
              AppLocalizations.of(
                context,
              )!.confirm_delete_club(clubName, bookCount),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: Text(AppLocalizations.of(context)!.delete),
              ),
            ],
          ),
    );
  }

  Future<bool?> _showV2DeleteDialog(String clubName, int bookCount) async {
    final l10n = AppLocalizations.of(context)!;

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: _kBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 25,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 384),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.delete_outline,
                            color: Color(0xFFB3261E),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            l10n.delete_club,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFB3261E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.confirm_delete_club(clubName, bookCount),
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 16,
                          color: _kText,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: const BoxDecoration(
                    color: _kBg,
                    border: Border(top: BorderSide(color: _kBorder)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          foregroundColor: _kSub,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n.cancel,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB3261E),
                          foregroundColor: Colors.white,
                          elevation: 4,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n.delete,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.useNewUi) {
      return _buildV2(context);
    }
    return _buildV1(context);
  }

  Widget _buildV1(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.manage_club_names),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildBody(context, isV2: false),
    );
  }

  Widget _buildV2(BuildContext context) {
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
        title: Text(
          l10n.manage_club_names,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: _kPrimary,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder.withValues(alpha: 0.5)),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: _kPrimary))
              : _buildBody(context, isV2: true),
    );
  }

  Widget _buildBody(BuildContext context, {required bool isV2}) {
    final l10n = AppLocalizations.of(context)!;

    if (_clubs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 64,
              color:
                  isV2
                      ? _kBorder
                      : Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.no_clubs_yet,
              style: TextStyle(
                fontFamily: isV2 ? 'Manrope' : null,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color:
                    isV2
                        ? _kSub
                        : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.add_books_to_clubs_hint,
              style: TextStyle(
                fontFamily: isV2 ? 'Manrope' : null,
                fontSize: 14,
                color:
                    isV2
                        ? _kSub
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding:
          isV2
              ? const EdgeInsets.fromLTRB(20, 20, 20, 50)
              : const EdgeInsets.all(16),
      itemCount: _clubs.length,
      itemBuilder: (context, index) {
        final club = _clubs[index];
        final clubName = club['club_name'] as String;
        final bookCount = club['book_count'] as int;
        final avgProgress = club['avg_progress'] as double?;

        if (isV2) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x1A27231E)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 6,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _kSecondary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _kSecondary.withValues(alpha: 0.12),
                    ),
                  ),
                  child: const Icon(
                    Icons.group_outlined,
                    color: _kSecondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clubName,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _kText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.book_count_label(bookCount),
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          color: _kSub,
                        ),
                      ),
                      if (avgProgress != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: avgProgress / 100,
                                  minHeight: 6,
                                  backgroundColor: const Color(0xFFF2EDEB),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        _kSecondary,
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${avgProgress.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _kSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      color: _kSub,
                      onPressed: () => _showRenameDialog(clubName),
                      tooltip: l10n.rename,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: const Color(0xFFB3261E),
                      onPressed: () => _deleteClub(clubName, bookCount),
                      tooltip: l10n.delete,
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: Theme.of(
                context,
              ).colorScheme.secondaryContainer.withValues(alpha: 0.3),
              child: Icon(
                Icons.group,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            title: Text(
              clubName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  l10n.book_count_label(bookCount),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (avgProgress != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: avgProgress / 100,
                            minHeight: 6,
                            backgroundColor:
                                Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${avgProgress.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  color: Theme.of(context).colorScheme.secondary,
                  onPressed: () => _showRenameDialog(clubName),
                  tooltip: l10n.rename,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  color: Theme.of(context).colorScheme.error,
                  onPressed: () => _deleteClub(clubName, bookCount),
                  tooltip: l10n.delete,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

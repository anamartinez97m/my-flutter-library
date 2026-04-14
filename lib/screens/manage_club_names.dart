import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';

class ManageClubNamesScreen extends StatefulWidget {
  const ManageClubNamesScreen({super.key});

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
    final controller = TextEditingController(text: oldName);

    final newName = await showDialog<String>(
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
                backgroundColor: Colors.orange,
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
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppLocalizations.of(context)!.error}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteClub(String clubName, int bookCount) async {
    final confirmed = await showDialog<bool>(
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
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(AppLocalizations.of(context)!.delete),
              ),
            ],
          ),
    );

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
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppLocalizations.of(context)!.error}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.manage_club_names),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _clubs.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.groups_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.no_clubs_yet,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.add_books_to_clubs_hint,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _clubs.length,
                itemBuilder: (context, index) {
                  final club = _clubs[index];
                  final clubName = club['club_name'] as String;
                  final bookCount = club['book_count'] as int;
                  final avgProgress = club['avg_progress'] as double?;

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
                        backgroundColor: Colors.teal.withValues(alpha: 0.1),
                        child: Icon(Icons.group, color: Colors.teal),
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
                            AppLocalizations.of(
                              context,
                            )!.book_count_label(bookCount),
                            style: TextStyle(color: Colors.grey[600]),
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
                                      backgroundColor: Colors.grey[300],
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            Colors.teal,
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
                                    color: Colors.teal,
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
                            color: Colors.teal,
                            onPressed: () => _showRenameDialog(clubName),
                            tooltip: AppLocalizations.of(context)!.rename,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            color: Colors.red,
                            onPressed: () => _deleteClub(clubName, bookCount),
                            tooltip: AppLocalizations.of(context)!.delete,
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

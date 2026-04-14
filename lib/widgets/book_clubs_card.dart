import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/reading_club.dart';
import 'package:myrandomlibrary/repositories/reading_club_repository.dart';
import 'package:myrandomlibrary/widgets/reading_club_dialog.dart';
import 'package:myrandomlibrary/config/app_theme.dart';

class BookClubsCard extends StatefulWidget {
  final int bookId;
  final VoidCallback? onClubsChanged;

  const BookClubsCard({super.key, required this.bookId, this.onClubsChanged});

  @override
  State<BookClubsCard> createState() => _BookClubsCardState();
}

class _BookClubsCardState extends State<BookClubsCard> {
  List<ReadingClub> _clubs = [];
  bool _isLoading = true;
  List<String> _existingClubNames = [];

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  Future<void> _loadClubs() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final repository = ReadingClubRepository(db);

      final clubs = await repository.getClubsForBook(widget.bookId);
      final allClubNames = await repository.getAllClubNames();

      if (mounted) {
        setState(() {
          _clubs = clubs;
          _existingClubNames = allClubNames;
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

  Future<void> _showAddClubDialog() async {
    final result = await showDialog<ReadingClub>(
      context: context,
      builder:
          (context) => ReadingClubDialog(
            bookId: widget.bookId,
            existingClubNames: _existingClubNames,
          ),
    );

    if (result != null) {
      try {
        final db = await DatabaseHelper.instance.database;
        final repository = ReadingClubRepository(db);

        // Check if book is already in this club
        final isAlreadyInClub = await repository.isBookInClub(
          widget.bookId,
          result.clubName,
        );

        if (isAlreadyInClub) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(
                    context,
                  )!.book_already_in_club(result.clubName),
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        await repository.addReadingClub(result);
        await _loadClubs();
        widget.onClubsChanged?.call();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.added_to_club(result.clubName),
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

  Future<void> _showEditClubDialog(ReadingClub club) async {
    final result = await showDialog<ReadingClub>(
      context: context,
      builder:
          (context) => ReadingClubDialog(
            bookId: widget.bookId,
            existingClub: club,
            existingClubNames: _existingClubNames,
          ),
    );

    if (result != null) {
      try {
        final db = await DatabaseHelper.instance.database;
        final repository = ReadingClubRepository(db);
        await repository.updateReadingClub(result);
        await _loadClubs();
        widget.onClubsChanged?.call();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.club_membership_updated,
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

  Future<void> _deleteClub(ReadingClub club) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.remove_from_club),
            content: Text(
              AppLocalizations.of(
                context,
              )!.remove_book_from_club(club.clubName),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(AppLocalizations.of(context)!.remove),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        final db = await DatabaseHelper.instance.database;
        final repository = ReadingClubRepository(db);
        await repository.deleteReadingClub(club.clubId!);
        await _loadClubs();
        widget.onClubsChanged?.call();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.removed_from_club(club.clubName),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: AppTheme.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.groups, color: Colors.teal, size: 24),
                AppTheme.horizontalSpaceLarge,
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.reading_clubs,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: Colors.teal,
                  onPressed: _showAddClubDialog,
                  tooltip: AppLocalizations.of(context)!.add_to_club,
                ),
              ],
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_clubs.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.not_in_any_clubs,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              ..._clubs.map((club) {
                return Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.group, color: Colors.teal, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              club.clubName,
                              style: Theme.of(
                                context,
                              ).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.teal[700],
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            color: Colors.teal,
                            onPressed: () => _showEditClubDialog(club),
                            tooltip: AppLocalizations.of(context)!.edit,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 18),
                            color: Colors.red,
                            onPressed: () => _deleteClub(club),
                            tooltip: AppLocalizations.of(context)!.remove,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      if (club.targetDate != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${AppLocalizations.of(context)!.target}: ${club.targetDate}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: club.readingProgress / 100,
                                minHeight: 6,
                                backgroundColor: Colors.grey[300],
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.teal,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${club.readingProgress}%',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

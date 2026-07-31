import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';

class LatestBookCard extends StatelessWidget {
  final String? latestBookName;

  const LatestBookCard({super.key, required this.latestBookName});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: 180,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.new_releases,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.latest_book_added,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              latestBookName != null && latestBookName!.isNotEmpty
                  ? latestBookName!
                  : l10n.no_books_in_database,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

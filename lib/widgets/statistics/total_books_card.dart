import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';

class TotalBooksCard extends StatelessWidget {
  final int totalCount;

  const TotalBooksCard({
    super.key,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        height: 180,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.library_books,
              size: 32,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.total_books,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$totalCount',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

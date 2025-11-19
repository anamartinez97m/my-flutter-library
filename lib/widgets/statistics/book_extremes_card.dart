import 'package:flutter/material.dart';

class BookExtremesCard extends StatelessWidget {
  final int? oldestYear;
  final String? oldestBookName;
  final int? newestYear;
  final String? newestBookName;
  final int? shortestPages;
  final String? shortestBookName;
  final int? longestPages;
  final String? longestBookName;

  const BookExtremesCard({
    super.key,
    this.oldestYear,
    this.oldestBookName,
    this.newestYear,
    this.newestBookName,
    this.shortestPages,
    this.shortestBookName,
    this.longestPages,
    this.longestBookName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Book Extremes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            // Oldest & Newest
            _buildExtremeRow(
              context,
              icon: Icons.calendar_today,
              color: Colors.blue,
              label1: 'Oldest',
              value1: oldestYear != null ? '$oldestYear' : 'N/A',
              book1: oldestBookName,
              label2: 'Newest',
              value2: newestYear != null ? '$newestYear' : 'N/A',
              book2: newestBookName,
            ),
            const Divider(height: 24),
            // Shortest & Longest
            _buildExtremeRow(
              context,
              icon: Icons.menu_book,
              color: Colors.purple,
              label1: 'Shortest',
              value1: shortestPages != null ? '$shortestPages pg' : 'N/A',
              book1: shortestBookName,
              label2: 'Longest',
              value2: longestPages != null ? '$longestPages pg' : 'N/A',
              book2: longestBookName,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtremeRow(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label1,
    required String value1,
    String? book1,
    required String label2,
    required String value2,
    String? book2,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label1,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          value1,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        if (book1 != null)
                          Text(
                            book1,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label2,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          value2,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        if (book2 != null)
                          Text(
                            book2,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

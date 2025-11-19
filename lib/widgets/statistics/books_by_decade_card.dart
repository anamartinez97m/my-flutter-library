import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/screens/books_by_decade.dart';

class BooksByDecadeCard extends StatelessWidget {
  final List<MapEntry<String, int>> sortedBooksByDecade;
  final bool showReadBooks;
  final ValueChanged<bool> onToggleChanged;

  const BooksByDecadeCard({
    super.key,
    required this.sortedBooksByDecade,
    required this.showReadBooks,
    required this.onToggleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (sortedBooksByDecade.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BooksByDecadeScreen(
                initialDecade: sortedBooksByDecade.first.key,
              ),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Books by Decade',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'All',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Switch(
                        value: showReadBooks,
                        onChanged: onToggleChanged,
                      ),
                      Text(
                        'Read',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '(Based on original publication year)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              if (sortedBooksByDecade.isEmpty)
                Center(
                  child: Text(AppLocalizations.of(context)!.no_data),
                )
              else
                ...sortedBooksByDecade.map((entry) {
                  final maxValue = sortedBooksByDecade
                      .map((e) => e.value)
                      .reduce((a, b) => a > b ? a : b);
                  final percentage = (entry.value / maxValue).clamp(0.0, 1.0);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BooksByDecadeScreen(
                              initialDecade: entry.key,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 4,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 70,
                              child: Text(
                                entry.key,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Stack(
                                children: [
                                  Container(
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: percentage,
                                    child: Container(
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 24,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '${entry.value}',
                                      style: TextStyle(
                                        color: percentage > 0.15 ? Colors.white : Colors.black87,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}

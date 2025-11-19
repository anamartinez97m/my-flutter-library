import 'package:flutter/material.dart';

/// Displays reading efficiency score
/// 
/// **How Reading Efficiency is Calculated:**
/// 1. Calculate your average reading velocity (pages/day) across all books
/// 2. For each book, calculate its actual reading pace (pages/day)
/// 3. If a book's pace >= average velocity, it's considered "efficient"
/// 4. Efficiency % = (efficient books / total books with data) * 100
/// 
/// Example:
/// - Your average velocity: 50 pages/day
/// - Book A: 300 pages in 5 days = 60 pages/day → Efficient ✓
/// - Book B: 200 pages in 5 days = 40 pages/day → Not efficient ✗
/// - Efficiency: 50% (1 out of 2 books)
class ReadingEfficiencyCard extends StatelessWidget {
  final double efficiencyPercentage;
  final int totalReadingsWithData;

  const ReadingEfficiencyCard({
    super.key,
    required this.efficiencyPercentage,
    required this.totalReadingsWithData,
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
          children: [
            Text(
              'Reading Efficiency Score',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${efficiencyPercentage.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'of books read faster than your average pace',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'What does this mean?',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'This compares each book\'s reading speed to your overall average. '
                    'Higher percentages mean you\'re consistently reading at or above your typical pace.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Based on $totalReadingsWithData books with complete data',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

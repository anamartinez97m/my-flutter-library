import 'package:flutter/material.dart';

class AverageRatingCard extends StatelessWidget {
  final double averageRating;
  final int ratedBooksCount;

  const AverageRatingCard({
    super.key,
    required this.averageRating,
    required this.ratedBooksCount,
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
              'Average Rating',
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
                  averageRating.toStringAsFixed(2),
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[700],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.star,
                  color: Colors.amber[700],
                  size: 40,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Based on $ratedBooksCount rated books',
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

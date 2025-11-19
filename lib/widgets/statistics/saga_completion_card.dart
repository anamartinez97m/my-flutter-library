import 'package:flutter/material.dart';

/// Displays saga completion statistics
/// 
/// **How Saga Completion is Calculated:**
/// - **Completed**: All books in the saga have readCount > 0
/// - **In Progress**: At least one book read, but not all books in the saga
/// - **Not Started**: No books in the saga have been read (readCount == 0)
/// 
/// A saga is identified by the `saga` field in the book model.
/// Books with the same saga name are grouped together.
class SagaCompletionCard extends StatelessWidget {
  final int completedSagas;
  final int partialSagas;
  final int unstartedSagas;

  const SagaCompletionCard({
    super.key,
    required this.completedSagas,
    required this.partialSagas,
    required this.unstartedSagas,
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
              'Saga Completion Rate',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '$completedSagas',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Completed',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '$partialSagas',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'In Progress',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '$unstartedSagas',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Not Started',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

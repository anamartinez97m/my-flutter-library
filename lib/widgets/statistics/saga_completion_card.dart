import 'package:flutter/material.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/screens/saga_completion_detail.dart';

/// Displays saga completion statistics
///
/// **How Saga Completion is Calculated:**
/// - **Completed**: All expected books in the saga (based on formatSagaValue) have been read
/// - **In Progress**: At least one book read, but not all expected books
/// - **Not Started**: No books in the saga have been read (readCount == 0)
///
/// The expected total is determined by the formatSagaValue field:
/// - Standalone: 1, Bilogy: 2, Trilogy: 3, Tetralogy: 4, Pentalogy: 5, Hexalogy: 6
/// - For 'Saga' and '6+': total is unknown (shown as '?')
class SagaCompletionCard extends StatelessWidget {
  final int completedSagas;
  final int partialSagas;
  final int unstartedSagas;
  final Map<String, Map<String, dynamic>> sagaStats;
  final List<Book> books;

  const SagaCompletionCard({
    super.key,
    required this.completedSagas,
    required this.partialSagas,
    required this.unstartedSagas,
    required this.sagaStats,
    required this.books,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => SagaCompletionDetailScreen(
                    sagaStats: sagaStats,
                    books: books,
                  ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Saga Completion Rate',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '$completedSagas',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineMedium?.copyWith(
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
                        style: Theme.of(
                          context,
                        ).textTheme.headlineMedium?.copyWith(
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
                        style: Theme.of(
                          context,
                        ).textTheme.headlineMedium?.copyWith(
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
      ),
    );
  }
}

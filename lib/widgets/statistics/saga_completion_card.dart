import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final total = completedSagas + partialSagas + unstartedSagas;
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => SagaCompletionDetailScreen(
                  sagaStats: sagaStats,
                  books: books,
                ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.72,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Title + arrow
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        l10n.saga_completion_rate,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
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
                const Spacer(),
                // Completed
                _buildStatSection(
                  context,
                  title: l10n.completed,
                  count: completedSagas,
                  total: total,
                  color: Colors.green,
                  icon: Icons.check_circle,
                ),
                const Spacer(),
                // In Progress
                _buildStatSection(
                  context,
                  title: l10n.in_progress,
                  count: partialSagas,
                  total: total,
                  color: Colors.orange,
                  icon: Icons.auto_stories,
                ),
                const Spacer(),
                // Not Started
                _buildStatSection(
                  context,
                  title: l10n.not_started,
                  count: unstartedSagas,
                  total: total,
                  color: Colors.grey,
                  icon: Icons.menu_book,
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatSection(
    BuildContext context, {
    required String title,
    required int count,
    required int total,
    required Color color,
    required IconData icon,
  }) {
    final percentage =
        total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '$percentage%',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
        ),
      ],
    );
  }
}

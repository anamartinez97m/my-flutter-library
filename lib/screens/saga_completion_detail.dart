import 'package:flutter/material.dart';
import 'package:myrandomlibrary/model/book.dart';

/// Screen showing detailed saga completion status with tabs for Completed, In Progress, and Not Started sagas
class SagaCompletionDetailScreen extends StatefulWidget {
  final Map<String, Map<String, dynamic>> sagaStats;
  final List<Book> books;

  const SagaCompletionDetailScreen({
    super.key,
    required this.sagaStats,
    required this.books,
  });

  @override
  State<SagaCompletionDetailScreen> createState() => _SagaCompletionDetailScreenState();
}

class _SagaCompletionDetailScreenState extends State<SagaCompletionDetailScreen> {
  int _selectedTabIndex = 0;

  List<MapEntry<String, Map<String, dynamic>>> get _completedSagas {
    return widget.sagaStats.entries
        .where((e) {
          final total = e.value['total'] as int;
          final read = e.value['read'] as int;
          // For unknown totals (-1), never consider completed
          if (total == -1) return false;
          return read == total;
        })
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
  }

  List<MapEntry<String, Map<String, dynamic>>> get _inProgressSagas {
    return widget.sagaStats.entries
        .where((e) {
          final total = e.value['total'] as int;
          final read = e.value['read'] as int;
          // For unknown totals, consider partial if any books read
          if (total == -1) return read > 0;
          return read > 0 && read < total;
        })
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
  }

  List<MapEntry<String, Map<String, dynamic>>> get _notStartedSagas {
    return widget.sagaStats.entries
        .where((e) => (e.value['read'] as int) == 0)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saga Completion'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Tab buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    index: 0,
                    label: 'Completed',
                    count: _completedSagas.length,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTabButton(
                    index: 1,
                    label: 'In Progress',
                    count: _inProgressSagas.length,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTabButton(
                    index: 2,
                    label: 'Not Started',
                    count: _notStartedSagas.length,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String label,
    required int count,
    required Color color,
  }) {
    final isSelected = _selectedTabIndex == index;
    
    return Material(
      color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? color : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? color : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    List<MapEntry<String, Map<String, dynamic>>> sagas;
    Color color;
    String emptyMessage;

    switch (_selectedTabIndex) {
      case 0:
        sagas = _completedSagas;
        color = Colors.green;
        emptyMessage = 'No completed sagas yet';
        break;
      case 1:
        sagas = _inProgressSagas;
        color = Colors.orange;
        emptyMessage = 'No sagas in progress';
        break;
      case 2:
        sagas = _notStartedSagas;
        color = Colors.grey;
        emptyMessage = 'No unstarted sagas';
        break;
      default:
        sagas = [];
        color = Colors.grey;
        emptyMessage = '';
    }

    if (sagas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.collections_bookmark_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sagas.length,
      itemBuilder: (context, index) {
        final saga = sagas[index];
        final sagaName = saga.key;
        final total = saga.value['total'] as int;
        final read = saga.value['read'] as int;
        final formatSaga = saga.value['formatSaga'] as String;
        final isUnknownTotal = total == -1;
        final progress = (total > 0 && !isUnknownTotal) ? read / total : 0.0;

        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        sagaName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color),
                      ),
                      child: Text(
                        isUnknownTotal ? '$read / ?' : '$read / $total',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isUnknownTotal 
                      ? 'Format: $formatSaga'
                      : '${(progress * 100).toStringAsFixed(0)}% complete',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

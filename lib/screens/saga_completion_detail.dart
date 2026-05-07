import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/screens/books_by_saga.dart';
import 'package:myrandomlibrary/utils/format_saga_helper.dart';

enum _SortMode { name, ascending, descending }

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
  State<SagaCompletionDetailScreen> createState() =>
      _SagaCompletionDetailScreenState();
}

class _SagaCompletionDetailScreenState
    extends State<SagaCompletionDetailScreen> {
  int _selectedTabIndex = 0;
  _SortMode _sortMode = _SortMode.name;

  List<MapEntry<String, Map<String, dynamic>>> get _completedSagas {
    return widget.sagaStats.entries.where((e) {
        final total = e.value['total'] as int;
        final read = e.value['read'] as int;
        // For unknown totals (-1), never consider completed
        if (total == -1) return false;
        return read == total;
      }).toList()
      ..sort((a, b) {
        if (_sortMode == _SortMode.name) return a.key.compareTo(b.key);
        final totalA = a.value['total'] as int;
        final totalB = b.value['total'] as int;
        return _sortMode == _SortMode.ascending
            ? totalA.compareTo(totalB)
            : totalB.compareTo(totalA);
      });
  }

  List<MapEntry<String, Map<String, dynamic>>> get _inProgressSagas {
    return widget.sagaStats.entries.where((e) {
        final total = e.value['total'] as int;
        final read = e.value['read'] as int;
        // For unknown totals, consider partial if any books read
        if (total == -1) return read > 0;
        return read > 0 && read < total;
      }).toList()
      ..sort((a, b) {
        if (_sortMode == _SortMode.name) return a.key.compareTo(b.key);
        final totalA = a.value['total'] as int;
        final readA = a.value['read'] as int;
        final leftA =
            totalA == -1 ? double.infinity : (totalA - readA).toDouble();
        final totalB = b.value['total'] as int;
        final readB = b.value['read'] as int;
        final leftB =
            totalB == -1 ? double.infinity : (totalB - readB).toDouble();
        return _sortMode == _SortMode.ascending
            ? leftA.compareTo(leftB)
            : leftB.compareTo(leftA);
      });
  }

  List<MapEntry<String, Map<String, dynamic>>> get _notStartedSagas {
    return widget.sagaStats.entries
        .where((e) => (e.value['read'] as int) == 0)
        .toList()
      ..sort((a, b) {
        if (_sortMode == _SortMode.name) return a.key.compareTo(b.key);
        final totalA = a.value['total'] as int;
        final totalB = b.value['total'] as int;
        // Push unknown totals (-1) to the end
        if (totalA == -1 && totalB == -1) return a.key.compareTo(b.key);
        if (totalA == -1) return 1;
        if (totalB == -1) return -1;
        return _sortMode == _SortMode.ascending
            ? totalA.compareTo(totalB)
            : totalB.compareTo(totalA);
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.saga_completion),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _sortMode == _SortMode.name
                  ? Icons.sort_by_alpha
                  : _sortMode == _SortMode.ascending
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
            ),
            onPressed: () {
              setState(() {
                switch (_sortMode) {
                  case _SortMode.name:
                    _sortMode = _SortMode.ascending;
                    break;
                  case _SortMode.ascending:
                    _sortMode = _SortMode.descending;
                    break;
                  case _SortMode.descending:
                    _sortMode = _SortMode.name;
                    break;
                }
              });
            },
          ),
        ],
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
                    label: AppLocalizations.of(context)!.completed,
                    count: _completedSagas.length,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTabButton(
                    index: 1,
                    label: AppLocalizations.of(context)!.in_progress,
                    count: _inProgressSagas.length,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTabButton(
                    index: 2,
                    label: AppLocalizations.of(context)!.not_started,
                    count: _notStartedSagas.length,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Expanded(child: _buildTabContent()),
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
      color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
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
              color:
                  isSelected
                      ? color
                      : Theme.of(context).colorScheme.outlineVariant,
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
                  color:
                      isSelected
                          ? color
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color:
                      isSelected
                          ? color
                          : Theme.of(context).colorScheme.onSurfaceVariant,
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
        color = Theme.of(context).colorScheme.primary;
        emptyMessage = AppLocalizations.of(context)!.no_completed_sagas;
        break;
      case 1:
        sagas = _inProgressSagas;
        color = Theme.of(context).colorScheme.secondary;
        emptyMessage = AppLocalizations.of(context)!.no_sagas_in_progress;
        break;
      case 2:
        sagas = _notStartedSagas;
        color = Theme.of(context).colorScheme.onSurfaceVariant;
        emptyMessage = AppLocalizations.of(context)!.no_unstarted_sagas;
        break;
      default:
        sagas = [];
        color = Theme.of(context).colorScheme.onSurfaceVariant;
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
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 50),
      itemCount: sagas.length,
      itemBuilder: (context, index) {
        final saga = sagas[index];
        final sagaName = saga.key;
        final total = saga.value['total'] as int;
        final read = saga.value['read'] as int;
        final formatSaga = saga.value['formatSaga'] as String;
        final isUnknownTotal = total == -1;
        final progress = (total > 0 && !isUnknownTotal) ? read / total : 0.0;

        final sagaUniverse = widget.books
            .where((b) => b.saga == sagaName)
            .map((b) => b.sagaUniverse)
            .firstWhere((u) => u != null && u.isNotEmpty, orElse: () => null);

        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => BooksBySagaScreen(
                        sagaName: sagaName,
                        sagaUniverse: sagaUniverse,
                      ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
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
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
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
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isUnknownTotal
                        ? '${AppLocalizations.of(context)!.format}: ${FormatSagaHelper.getLocalizedLabel(formatSaga, AppLocalizations.of(context)!)}'
                        : '${(progress * 100).toStringAsFixed(0)}% ${AppLocalizations.of(context)!.complete_label}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

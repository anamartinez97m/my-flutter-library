import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/screens/books_by_saga.dart';
import 'package:myrandomlibrary/utils/format_saga_helper.dart';

enum _SortMode { name, ascending, descending }

/// v2 redesign of the saga completion detail screen.
///
/// Preserves the original behaviour: three tabs (Completed, In Progress,
/// Not Started), a cyclic sort toggle, and tapping a saga opens the list of
/// books belonging to that saga.
class NewSagaCompletionDetailScreen extends StatefulWidget {
  final Map<String, Map<String, dynamic>> sagaStats;
  final List<Book> books;
  final int initialTabIndex;

  const NewSagaCompletionDetailScreen({
    super.key,
    required this.sagaStats,
    required this.books,
    this.initialTabIndex = 0,
  });

  @override
  State<NewSagaCompletionDetailScreen> createState() =>
      _NewSagaCompletionDetailScreenState();
}

class _NewSagaCompletionDetailScreenState
    extends State<NewSagaCompletionDetailScreen> {
  static const _kBg = Color(0xFFFDF8F6);
  static const _kPrimary = Color(0xFF43102B);
  static const _kText = Color(0xFF1C1B1A);
  static const _kSub = Color(0xFF514348);
  static const _kBorder = Color(0xFFD5C2C7);
  static const _kDivider = Color(0xFFE6E2DF);
  static const _kMuted = Color(0xFFD5C2C7);
  static const _kSecondary = Color(0xFF894B67);

  late int _selectedTabIndex;
  _SortMode _sortMode = _SortMode.name;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
  }

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

  void _cycleSortMode() {
    setState(() {
      switch (_sortMode) {
        case _SortMode.name:
          _sortMode = _SortMode.ascending;
        case _SortMode.ascending:
          _sortMode = _SortMode.descending;
        case _SortMode.descending:
          _sortMode = _SortMode.name;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.saga_completion,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: _kPrimary,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _sortMode == _SortMode.name
                  ? Icons.sort_by_alpha
                  : _sortMode == _SortMode.ascending
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              color: _kPrimary,
            ),
            onPressed: _cycleSortMode,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    index: 0,
                    label: l10n.completed,
                    count: _completedSagas.length,
                    color: _kPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTabButton(
                    index: 1,
                    label: l10n.in_progress,
                    count: _inProgressSagas.length,
                    color: _kSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTabButton(
                    index: 2,
                    label: l10n.not_started,
                    count: _notStartedSagas.length,
                    color: _kSub,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, thickness: 1, color: _kDivider),
          ),
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

    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : _kBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : _kSub,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : _kSub,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
        color = _kPrimary;
        emptyMessage = AppLocalizations.of(context)!.no_completed_sagas;
      case 1:
        sagas = _inProgressSagas;
        color = _kSecondary;
        emptyMessage = AppLocalizations.of(context)!.no_sagas_in_progress;
      case 2:
        sagas = _notStartedSagas;
        color = _kSub;
        emptyMessage = AppLocalizations.of(context)!.no_unstarted_sagas;
      default:
        sagas = [];
        color = _kSub;
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
              color: _kMuted,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(fontSize: 16, color: _kSub),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 50),
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

        return GestureDetector(
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
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x1A27231E)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 6,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        sagaName,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _kText,
                        ),
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
                          fontFamily: 'Manrope',
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
                    backgroundColor: _kDivider,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isUnknownTotal
                      ? '${AppLocalizations.of(context)!.format}: ${FormatSagaHelper.getLocalizedLabel(formatSaga, AppLocalizations.of(context)!)}'
                      : '${(progress * 100).toStringAsFixed(0)}% ${AppLocalizations.of(context)!.complete_label}',
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    color: _kSub,
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

import 'package:flutter/material.dart';
import 'package:myrandomlibrary/model/read_date.dart';

/// Widget for managing read dates for books within a bundle
/// Each book in the bundle can have multiple reading sessions
class BundleReadDatesWidget extends StatefulWidget {
  final int bookId;
  final int bundleCount;
  final Map<int, List<ReadDate>> initialBundleReadDates;
  final Function(Map<int, List<ReadDate>>) onChanged;

  const BundleReadDatesWidget({
    super.key,
    required this.bookId,
    required this.bundleCount,
    required this.initialBundleReadDates,
    required this.onChanged,
  });

  @override
  State<BundleReadDatesWidget> createState() => _BundleReadDatesWidgetState();
}

class _BundleReadDatesWidgetState extends State<BundleReadDatesWidget> {
  late Map<int, List<ReadDate>> _bundleReadDates;

  @override
  void initState() {
    super.initState();
    _bundleReadDates = Map.from(widget.initialBundleReadDates);
  }

  void _addReadDate(int bundleIndex) {
    setState(() {
      if (!_bundleReadDates.containsKey(bundleIndex)) {
        _bundleReadDates[bundleIndex] = [];
      }
      _bundleReadDates[bundleIndex]!.add(ReadDate(
        bookId: widget.bookId,
        dateStarted: null,
        dateFinished: null,
        bundleBookIndex: bundleIndex,
      ));
    });
    widget.onChanged(_bundleReadDates);
  }

  void _removeReadDate(int bundleIndex, int dateIndex) {
    setState(() {
      _bundleReadDates[bundleIndex]?.removeAt(dateIndex);
      if (_bundleReadDates[bundleIndex]?.isEmpty ?? false) {
        _bundleReadDates.remove(bundleIndex);
      }
    });
    widget.onChanged(_bundleReadDates);
  }

  void _updateReadDate(int bundleIndex, int dateIndex, String? dateStarted, String? dateFinished) {
    setState(() {
      final dates = _bundleReadDates[bundleIndex];
      if (dates != null && dateIndex < dates.length) {
        dates[dateIndex] = ReadDate(
          readDateId: dates[dateIndex].readDateId,
          bookId: widget.bookId,
          dateStarted: dateStarted,
          dateFinished: dateFinished,
          bundleBookIndex: bundleIndex,
        );
      }
    });
    widget.onChanged(_bundleReadDates);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bundle Reading Sessions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(widget.bundleCount, (bundleIndex) {
          final readDates = _bundleReadDates[bundleIndex] ?? [];
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Book ${bundleIndex + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _addReadDate(bundleIndex),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Session'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                    ],
                  ),
                  if (readDates.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No reading sessions',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    )
                  else
                    ...List.generate(readDates.length, (dateIndex) {
                      final readDate = readDates[dateIndex];
                      return Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Session ${dateIndex + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 18),
                                  onPressed: () => _removeReadDate(bundleIndex, dateIndex),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: readDate.dateStarted != null
                                            ? DateTime.parse(readDate.dateStarted!)
                                            : DateTime.now(),
                                        firstDate: DateTime(1900),
                                        lastDate: DateTime.now(),
                                      );
                                      if (date != null) {
                                        final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                                        _updateReadDate(bundleIndex, dateIndex, dateStr, readDate.dateFinished);
                                      }
                                    },
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'Started',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 6,
                                        ),
                                      ),
                                      child: Text(
                                        readDate.dateStarted ?? 'Not set',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: readDate.dateStarted != null
                                              ? null
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: readDate.dateFinished != null
                                            ? DateTime.parse(readDate.dateFinished!)
                                            : DateTime.now(),
                                        firstDate: DateTime(1900),
                                        lastDate: DateTime.now(),
                                      );
                                      if (date != null) {
                                        final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                                        _updateReadDate(bundleIndex, dateIndex, readDate.dateStarted, dateStr);
                                      }
                                    },
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'Finished',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 6,
                                        ),
                                      ),
                                      child: Text(
                                        readDate.dateFinished ?? 'Not set',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: readDate.dateFinished != null
                                              ? null
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

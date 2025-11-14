import 'package:flutter/material.dart';
import 'package:myrandomlibrary/model/read_date.dart';

class ReadDatesWidget extends StatefulWidget {
  final int bookId;
  final List<ReadDate> initialReadDates;
  final Function(List<ReadDate>) onChanged;

  const ReadDatesWidget({
    super.key,
    required this.bookId,
    required this.initialReadDates,
    required this.onChanged,
  });

  @override
  State<ReadDatesWidget> createState() => _ReadDatesWidgetState();
}

class _ReadDatesWidgetState extends State<ReadDatesWidget> {
  late List<ReadDate> _readDates;

  @override
  void initState() {
    super.initState();
    _readDates = List.from(widget.initialReadDates);
  }

  void _addReadDate() {
    setState(() {
      _readDates.add(ReadDate(
        bookId: widget.bookId,
        dateStarted: null,
        dateFinished: null,
      ));
    });
    widget.onChanged(_readDates);
  }

  void _removeReadDate(int index) {
    setState(() {
      _readDates.removeAt(index);
    });
    widget.onChanged(_readDates);
  }

  void _updateReadDate(int index, String? dateStarted, String? dateFinished) {
    setState(() {
      _readDates[index] = ReadDate(
        readDateId: _readDates[index].readDateId,
        bookId: widget.bookId,
        dateStarted: dateStarted,
        dateFinished: dateFinished,
      );
    });
    widget.onChanged(_readDates);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reading Sessions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton.icon(
              onPressed: _addReadDate,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Session'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_readDates.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'No reading sessions recorded',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
          )
        else
          ...List.generate(_readDates.length, (index) {
            final readDate = _readDates[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Session ${index + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () => _removeReadDate(index),
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
                                _updateReadDate(index, dateStr, readDate.dateFinished);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Started',
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                              ),
                              child: Text(
                                readDate.dateStarted ?? 'Not set',
                                style: TextStyle(
                                  fontSize: 13,
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
                                _updateReadDate(index, readDate.dateStarted, dateStr);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Finished',
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                              ),
                              child: Text(
                                readDate.dateFinished ?? 'Not set',
                                style: TextStyle(
                                  fontSize: 13,
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
              ),
            );
          }),
      ],
    );
  }
}

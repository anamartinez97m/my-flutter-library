import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
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
      _bundleReadDates[bundleIndex]!.add(
        ReadDate(
          bookId: widget.bookId,
          dateStarted: null,
          dateFinished: null,
          bundleBookIndex: bundleIndex,
        ),
      );
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

  void _updateReadDate(
    int bundleIndex,
    int dateIndex,
    String? dateStarted,
    String? dateFinished,
  ) {
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

  Future<String?> _showDateOrYearPicker(
    BuildContext context,
    String? currentDate,
    String label,
  ) async {
    // Show dialog to choose between full date or year only
    final choice = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('${AppLocalizations.of(context)!.select} $label'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(AppLocalizations.of(context)!.full_date),
                  onTap: () => Navigator.pop(context, 'date'),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_view_month),
                  title: Text(AppLocalizations.of(context)!.year_only),
                  onTap: () => Navigator.pop(context, 'year'),
                ),
              ],
            ),
          ),
    );

    if (choice == 'date') {
      if (!context.mounted) return null;
      final date = await showDatePicker(
        context: context,
        initialDate:
            currentDate != null && currentDate.length >= 4
                ? DateTime.tryParse(currentDate) ?? DateTime.now()
                : DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
      );
      if (date != null) {
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      }
    } else if (choice == 'year') {
      if (!context.mounted) return null;
      final year = await showDialog<String>(
        context: context,
        builder:
            (context) => _YearPickerDialog(
              initialYear:
                  currentDate != null && currentDate.length >= 4
                      ? currentDate.substring(0, 4)
                      : DateTime.now().year.toString(),
            ),
      );

      if (year != null) {
        return year; // Return just the year as a string
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.bundle_reading_sessions,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
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
                        '${AppLocalizations.of(context)!.book} ${bundleIndex + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _addReadDate(bundleIndex),
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(AppLocalizations.of(context)!.add_session),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (readDates.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        AppLocalizations.of(context)!.no_reading_sessions,
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
                                  '${AppLocalizations.of(context)!.session} ${dateIndex + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 18),
                                  onPressed:
                                      () => _removeReadDate(
                                        bundleIndex,
                                        dateIndex,
                                      ),
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
                                      final dateStr =
                                          await _showDateOrYearPicker(
                                            context,
                                            readDate.dateStarted,
                                            AppLocalizations.of(
                                              context,
                                            )!.start_date,
                                          );
                                      if (dateStr != null) {
                                        _updateReadDate(
                                          bundleIndex,
                                          dateIndex,
                                          dateStr,
                                          readDate.dateFinished,
                                        );
                                      }
                                    },
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText:
                                            AppLocalizations.of(
                                              context,
                                            )!.started,
                                        border: const OutlineInputBorder(),
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 6,
                                        ),
                                      ),
                                      child: Text(
                                        readDate.dateStarted ??
                                            AppLocalizations.of(
                                              context,
                                            )!.not_set,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              readDate.dateStarted != null
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
                                      final dateStr =
                                          await _showDateOrYearPicker(
                                            context,
                                            readDate.dateFinished,
                                            AppLocalizations.of(
                                              context,
                                            )!.end_date,
                                          );
                                      if (dateStr != null) {
                                        _updateReadDate(
                                          bundleIndex,
                                          dateIndex,
                                          readDate.dateStarted,
                                          dateStr,
                                        );
                                      }
                                    },
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText:
                                            AppLocalizations.of(
                                              context,
                                            )!.finished,
                                        border: const OutlineInputBorder(),
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 6,
                                        ),
                                      ),
                                      child: Text(
                                        readDate.dateFinished ??
                                            AppLocalizations.of(
                                              context,
                                            )!.not_set,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              readDate.dateFinished != null
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

class _YearPickerDialog extends StatefulWidget {
  final String initialYear;

  const _YearPickerDialog({required this.initialYear});

  @override
  State<_YearPickerDialog> createState() => _YearPickerDialogState();
}

class _YearPickerDialogState extends State<_YearPickerDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialYear);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.enter_year),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Year',
          hintText: 'e.g., 2024',
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        TextButton(
          onPressed: () {
            final yearValue = int.tryParse(_controller.text);
            if (yearValue != null &&
                yearValue >= 1900 &&
                yearValue <= DateTime.now().year) {
              Navigator.pop(context, _controller.text);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)!.please_enter_valid_year,
                  ),
                ),
              );
            }
          },
          child: Text(AppLocalizations.of(context)!.ok),
        ),
      ],
    );
  }
}

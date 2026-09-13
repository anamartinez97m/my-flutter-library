import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/read_date.dart';

class ReadDatesWidget extends StatefulWidget {
  final int bookId;
  final List<ReadDate> initialReadDates;
  final Function(List<ReadDate>) onChanged;
  final Color? titleColor;
  final bool useNewUi;

  const ReadDatesWidget({
    super.key,
    required this.bookId,
    required this.initialReadDates,
    required this.onChanged,
    this.titleColor,
    this.useNewUi = false,
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
      _readDates.add(
        ReadDate(bookId: widget.bookId, dateStarted: null, dateFinished: null),
      );
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

  Widget _buildV2(BuildContext context) {
    const primary = Color(0xFF43102B);
    const border = Color(0xFFD5C2C7);
    const label = Color(0xFF76656B);
    final l10n = AppLocalizations.of(context)!;

    Widget dateField({
      required String title,
      required String? value,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: label,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 15,
                      color: primary,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        value ?? l10n.not_set,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: value == null ? label : primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${l10n.reading_sessions} (${_readDates.length})',
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
            ),
            IconButton(
              onPressed: _addReadDate,
              icon: const Icon(Icons.add, color: primary, size: 20),
              tooltip: l10n.add_session,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_readDates.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: border),
            ),
            child: Column(
              children: [
                const Icon(Icons.event_note_outlined, color: label, size: 24),
                const SizedBox(height: 8),
                Text(
                  l10n.no_reading_sessions,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13,
                    color: label,
                  ),
                ),
              ],
            ),
          )
        else
          ...List.generate(_readDates.length, (index) {
            final readDate = _readDates[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: border),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${l10n.session} ${index + 1}',
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: primary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removeReadDate(index),
                        icon: const Icon(Icons.delete_outline, size: 19),
                        color: label,
                        tooltip: l10n.delete,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      dateField(
                        title: l10n.started,
                        value: readDate.dateStarted,
                        onTap: () async {
                          final date = await _showDateOrYearPicker(
                            context,
                            readDate.dateStarted,
                            l10n.start_date,
                          );
                          if (date != null) {
                            _updateReadDate(index, date, readDate.dateFinished);
                          }
                        },
                      ),
                      const SizedBox(width: 10),
                      dateField(
                        title: l10n.finished,
                        value: readDate.dateFinished,
                        onTap: () async {
                          final date = await _showDateOrYearPicker(
                            context,
                            readDate.dateFinished,
                            l10n.end_date,
                          );
                          if (date != null) {
                            _updateReadDate(index, readDate.dateStarted, date);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.useNewUi) return _buildV2(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 9),
          decoration:
              widget.useNewUi
                  ? BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: const Color(0xFF27231E).withValues(alpha: 0.2),
                      ),
                    ),
                  )
                  : null,
          child: Row(
            children: [
              if (widget.useNewUi) ...[
                const Icon(Icons.history, color: Color(0xFF43102B), size: 20),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.reading_sessions,
                  style:
                      widget.useNewUi
                          ? const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF43102B),
                          )
                          : Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: widget.titleColor,
                          ),
                ),
              ),
              TextButton.icon(
                onPressed: _addReadDate,
                style:
                    widget.useNewUi
                        ? TextButton.styleFrom(
                          foregroundColor: const Color(0xFF43102B),
                        )
                        : null,
                icon: const Icon(Icons.add, size: 18),
                label: Text(AppLocalizations.of(context)!.add_session),
              ),
            ],
          ),
        ),
        SizedBox(height: widget.useNewUi ? 16 : 8),
        if (_readDates.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 13),
            decoration:
                widget.useNewUi
                    ? BoxDecoration(
                      color: const Color(0xFF43102B).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF43102B).withValues(alpha: 0.1),
                      ),
                    )
                    : null,
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.no_reading_sessions,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontFamily: widget.useNewUi ? 'Manrope' : null,
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          ...List.generate(_readDates.length, (index) {
            final readDate = _readDates[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(13),
              decoration:
                  widget.useNewUi
                      ? BoxDecoration(
                        color: const Color(0xFF43102B).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF43102B).withValues(alpha: 0.1),
                        ),
                      )
                      : BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${AppLocalizations.of(context)!.session} ${index + 1}',
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
                            final dateStr = await _showDateOrYearPicker(
                              context,
                              readDate.dateStarted,
                              AppLocalizations.of(context)!.start_date,
                            );
                            if (dateStr != null) {
                              _updateReadDate(
                                index,
                                dateStr,
                                readDate.dateFinished,
                              );
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.started,
                              border: const OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                            ),
                            child: Text(
                              readDate.dateStarted ??
                                  AppLocalizations.of(context)!.not_set,
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                    readDate.dateStarted != null
                                        ? null
                                        : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final dateStr = await _showDateOrYearPicker(
                              context,
                              readDate.dateFinished,
                              AppLocalizations.of(context)!.end_date,
                            );
                            if (dateStr != null) {
                              _updateReadDate(
                                index,
                                readDate.dateStarted,
                                dateStr,
                              );
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.finished,
                              border: const OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                            ),
                            child: Text(
                              readDate.dateFinished ??
                                  AppLocalizations.of(context)!.not_set,
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                    readDate.dateFinished != null
                                        ? null
                                        : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
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

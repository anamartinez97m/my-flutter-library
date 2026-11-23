import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/utils/publication_date.dart';

enum _Precision { year, month, day }

/// One "Release Date" field with a Year / Month / Day switch, so the date can
/// be known to the year, the month or the exact day.
class PublicationDateFields extends StatefulWidget {
  final TextEditingController yearController;
  final int? month;
  final int? day;
  final void Function(int? month, int? day) onChanged;
  final InputDecoration Function(String label, IconData icon) decoration;
  final double spacing;

  const PublicationDateFields({
    super.key,
    required this.yearController,
    required this.month,
    required this.day,
    required this.onChanged,
    required this.decoration,
    this.spacing = 10,
  });

  @override
  State<PublicationDateFields> createState() => _PublicationDateFieldsState();
}

class _PublicationDateFieldsState extends State<PublicationDateFields> {
  late _Precision _precision = _precisionOf(widget.month, widget.day);

  static _Precision _precisionOf(int? month, int? day) =>
      day != null
          ? _Precision.day
          : month != null
          ? _Precision.month
          : _Precision.year;

  @override
  void didUpdateWidget(PublicationDateFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    final known = _precisionOf(widget.month, widget.day);
    if (known.index > _precision.index) _precision = known;
  }

  int? get _year {
    final year = int.tryParse(widget.yearController.text.trim());
    return year != null && year > 0 ? year : null;
  }

  void _setPrecision(_Precision precision) {
    setState(() => _precision = precision);
    switch (precision) {
      case _Precision.year:
        if (widget.month != null || widget.day != null) {
          widget.onChanged(null, null);
        }
      case _Precision.month:
        if (widget.day != null) widget.onChanged(widget.month, null);
      case _Precision.day:
        break;
    }
  }

  Future<void> _pickMonth() async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder:
          (context) => _MonthPickerDialog(
            initial: DateTime(
              _year ?? DateTime.now().year,
              widget.month ?? DateTime.now().month,
            ),
          ),
    );
    if (picked == null) return;
    widget.yearController.text = picked.year.toString();
    widget.onChanged(picked.month, null);
  }

  Future<void> _pickDay() async {
    final first = DateTime(1900);
    final last = DateTime(2100, 12, 31);
    final current =
        PublicationDate.fromParts(_year, widget.month, widget.day)?.fullDate;
    var initial =
        current ??
        (_year != null
            ? DateTime(_year!, widget.month ?? 1, 1)
            : DateTime.now());
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked == null) return;
    widget.yearController.text = picked.year.toString();
    widget.onChanged(picked.month, picked.day);
  }

  void _clear() {
    widget.yearController.clear();
    widget.onChanged(null, null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final theme = Theme.of(context);

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.yearController,
      builder: (context, value, _) {
        final date = PublicationDate.fromParts(_year, widget.month, widget.day);
        final now = DateTime.now();

        final Widget field;
        final String hint;
        switch (_precision) {
          case _Precision.year:
            field = TextFormField(
              controller: widget.yearController,
              decoration: widget.decoration(
                l10n.release_date,
                Icons.calendar_today,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
            );
            hint = l10n.release_date_hint_year('${date?.year ?? now.year}');
          case _Precision.month:
            final hasMonth = date?.hasMonth ?? false;
            field = _PickerField(
              decoration: widget
                  .decoration(l10n.release_date, Icons.date_range)
                  .copyWith(suffixIcon: const Icon(Icons.arrow_drop_down)),
              text: hasMonth ? date!.format(locale) : null,
              placeholder: l10n.release_date_select_month,
              onTap: _pickMonth,
            );
            hint = l10n.release_date_hint_month(
              hasMonth
                  ? date!.format(locale)
                  : DateFormat.yMMMM(locale).format(now),
            );
          case _Precision.day:
            final hasDay = date?.hasDay ?? false;
            field = _PickerField(
              decoration: widget
                  .decoration(l10n.release_date, Icons.event)
                  .copyWith(
                    suffixIcon:
                        hasDay
                            ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: _clear,
                            )
                            : null,
                  ),
              text: hasDay ? date!.format(locale) : null,
              placeholder: l10n.select_release_date,
              onTap: _pickDay,
            );
            hint = l10n.release_date_hint_day(
              hasDay
                  ? date!.format(locale)
                  : PublicationDate(
                    now.year,
                    month: now.month,
                    day: now.day,
                  ).format(locale),
            );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.release_date,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            SegmentedButton<_Precision>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: _Precision.year,
                  label: Text(l10n.release_date_precision_year),
                ),
                ButtonSegment(
                  value: _Precision.month,
                  label: Text(l10n.publication_month),
                ),
                ButtonSegment(
                  value: _Precision.day,
                  label: Text(l10n.publication_day),
                ),
              ],
              selected: {_precision},
              onSelectionChanged: (s) => _setPrecision(s.first),
            ),
            SizedBox(height: widget.spacing),
            field,
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: Text(
                hint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PickerField extends StatelessWidget {
  final InputDecoration decoration;
  final String? text;
  final String placeholder;
  final VoidCallback onTap;

  const _PickerField({
    required this.decoration,
    required this.text,
    required this.placeholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: decoration,
        child: Text(
          text ?? placeholder,
          style: TextStyle(
            color:
                text != null
                    ? null
                    : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Picks a month and year.
class _MonthPickerDialog extends StatefulWidget {
  final DateTime initial;

  const _MonthPickerDialog({required this.initial});

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _year = widget.initial.year;
  late int _month = widget.initial.month;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final material = MaterialLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _year > 1900 ? () => setState(() => _year--) : null,
          ),
          Expanded(child: Text('$_year', textAlign: TextAlign.center)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _year < 2100 ? () => setState(() => _year++) : null,
          ),
        ],
      ),
      content: SizedBox(
        width: 300,
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          childAspectRatio: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            for (var m = 1; m <= 12; m++)
              ChoiceChip(
                label: SizedBox(
                  width: double.infinity,
                  child: Text(
                    DateFormat.MMM(locale).format(DateTime(2000, m)),
                    textAlign: TextAlign.center,
                  ),
                ),
                showCheckmark: false,
                selected: m == _month,
                selectedColor: scheme.primary,
                labelStyle: TextStyle(
                  color: m == _month ? scheme.onPrimary : null,
                ),
                onSelected: (_) => setState(() => _month = m),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(material.cancelButtonLabel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, DateTime(_year, _month)),
          child: Text(material.okButtonLabel),
        ),
      ],
    );
  }
}

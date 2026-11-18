import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/utils/publication_date.dart';

/// Year field plus optional month and day, so a publication date can be
/// known to the year, the month or the exact day.
class PublicationDateFields extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: yearController,
      builder: (context, value, _) {
        final year = int.tryParse(value.text.trim());
        final hasYear = year != null && year > 0;
        final selectedMonth = hasYear ? month : null;
        final selectedDay = selectedMonth != null ? day : null;
        final maxDay =
            selectedMonth != null
                ? PublicationDate.daysInMonth(year!, selectedMonth)
                : 31;

        return Column(
          children: [
            TextFormField(
              controller: yearController,
              decoration: decoration(
                l10n.publication_year,
                Icons.calendar_today,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
            ),
            SizedBox(height: spacing),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<int?>(
                    key: ValueKey('publication-month-$selectedMonth-$hasYear'),
                    initialValue: selectedMonth,
                    isExpanded: true,
                    decoration: decoration(
                      l10n.publication_month,
                      Icons.date_range,
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('—'),
                      ),
                      for (var m = 1; m <= 12; m++)
                        DropdownMenuItem<int?>(
                          value: m,
                          child: Text(
                            DateFormat.MMMM(locale).format(DateTime(2000, m)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged:
                        hasYear
                            ? (m) {
                              final keepDay =
                                  m != null &&
                                  day != null &&
                                  day! <= PublicationDate.daysInMonth(year, m);
                              onChanged(m, keepDay ? day : null);
                            }
                            : null,
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int?>(
                    key: ValueKey(
                      'publication-day-$selectedMonth-$selectedDay-$maxDay',
                    ),
                    initialValue: selectedDay,
                    isExpanded: true,
                    decoration: decoration(l10n.publication_day, Icons.today),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('—'),
                      ),
                      for (var d = 1; d <= maxDay; d++)
                        DropdownMenuItem<int?>(value: d, child: Text('$d')),
                    ],
                    onChanged:
                        selectedMonth != null
                            ? (d) => onChanged(selectedMonth, d)
                            : null,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

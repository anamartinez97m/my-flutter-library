import 'package:flutter/material.dart';
import 'package:myrandomlibrary/config/v2_design_system.dart';
import 'package:myrandomlibrary/discovery/text/text_normalizer.dart';
import 'package:myrandomlibrary/helpers/library_tool_fields.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';

/// Value picker used by the Library Tools. Free-text fields (author, saga,
/// reading club...) get a search box that also accepts new values, acquired
/// date gets a text box with a date picker, everything else a dropdown.
class LibraryToolValueInput extends StatefulWidget {
  final String field;
  final List<FieldOption> options;
  final String? value;
  final String label;
  final ValueChanged<String?> onChanged;

  const LibraryToolValueInput({
    super.key,
    required this.field,
    required this.options,
    required this.value,
    required this.label,
    required this.onChanged,
  });

  @override
  State<LibraryToolValueInput> createState() => _LibraryToolValueInputState();
}

class _LibraryToolValueInputState extends State<LibraryToolValueInput> {
  late final TextEditingController _dateController = TextEditingController(
    text: widget.field == 'acquired_date' ? widget.value ?? '' : '',
  );

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  InputDecoration _decoration({Widget? suffixIcon, String? helper}) {
    return InputDecoration(
      labelText: widget.label,
      labelStyle: TextStyle(
        fontFamily: V2Typography.family,
        color: V2Colors.textSubtle,
      ),
      helperText: helper,
      prefixIcon: Icon(Icons.label_outline, color: V2Colors.secondary),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: V2Colors.surface,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: V2Colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: V2Colors.primary, width: 1.5),
      ),
    );
  }

  TextStyle get _textStyle => TextStyle(
    fontFamily: V2Typography.family,
    fontSize: 14,
    color: V2Colors.textPrimary,
  );

  @override
  Widget build(BuildContext context) {
    if (widget.field == 'acquired_date') return _buildDateInput(context);
    if (LibraryToolFields.freeTextFields.contains(widget.field)) {
      return _buildSearchInput();
    }
    final hasValue = widget.options.any((o) => o.value == widget.value);
    return DropdownButtonFormField<String>(
      key: ValueKey('${widget.field}-${widget.value}'),
      initialValue: hasValue ? widget.value : null,
      isExpanded: true,
      style: _textStyle,
      dropdownColor: V2Colors.background,
      iconEnabledColor: V2Colors.primary,
      decoration: _decoration(),
      items:
          widget.options
              .map(
                (o) => DropdownMenuItem(
                  value: o.value,
                  child: Text(o.label, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
      onChanged: widget.onChanged,
    );
  }

  Widget _buildSearchInput() {
    final l10n = AppLocalizations.of(context)!;
    return Autocomplete<String>(
      key: ValueKey('${widget.field}-search'),
      initialValue: TextEditingValue(text: widget.value ?? ''),
      optionsBuilder: (text) {
        final query = TextNormalizer.normalize(text.text);
        final values = widget.options.map((o) => o.value);
        if (query.isEmpty) return values;
        return values.where((v) => TextNormalizer.normalize(v).contains(query));
      },
      onSelected: widget.onChanged,
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          style: _textStyle,
          textCapitalization: TextCapitalization.words,
          decoration: _decoration(helper: l10n.type_or_pick_value),
          onChanged: (text) {
            final value = text.trim();
            widget.onChanged(value.isEmpty ? null : value);
          },
          onSubmitted: (_) => onSubmitted(),
        );
      },
    );
  }

  Widget _buildDateInput(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = _dateController.text.trim();
    final invalid =
        text.isNotEmpty && !LibraryToolFields.isValidAcquiredDate(text);
    return TextField(
      controller: _dateController,
      style: _textStyle,
      keyboardType: TextInputType.datetime,
      decoration: _decoration(
        helper: l10n.acquired_date_format_hint,
        suffixIcon: IconButton(
          icon: Icon(Icons.calendar_month_outlined, color: V2Colors.primary),
          onPressed: _pickDate,
        ),
      ).copyWith(errorText: invalid ? l10n.invalid_value : null),
      onChanged: (_) => _emitDate(),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dateController.text.trim()) ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (picked == null) return;
    _dateController.text = formatIsoDate(picked);
    _emitDate();
  }

  void _emitDate() {
    final text = _dateController.text.trim();
    setState(() {});
    widget.onChanged(LibraryToolFields.isValidAcquiredDate(text) ? text : null);
  }
}

String formatIsoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

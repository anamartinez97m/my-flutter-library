import 'package:flutter/material.dart';

class ChipAutocompleteField extends StatefulWidget {
  final String labelText;
  final IconData? prefixIcon;
  final List<String> suggestions;
  final List<String> initialValues;
  final Function(List<String>) onChanged;
  final String? hintText;

  const ChipAutocompleteField({
    super.key,
    required this.labelText,
    this.prefixIcon,
    required this.suggestions,
    required this.initialValues,
    required this.onChanged,
    this.hintText,
  });

  @override
  State<ChipAutocompleteField> createState() => _ChipAutocompleteFieldState();
}

class _ChipAutocompleteFieldState extends State<ChipAutocompleteField> {
  late List<String> _selectedValues;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  TextEditingController? _fieldController;

  @override
  void initState() {
    super.initState();
    _selectedValues = List.from(widget.initialValues);
  }
  
  @override
  void didUpdateWidget(ChipAutocompleteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update selected values if initialValues changed
    if (widget.initialValues != oldWidget.initialValues) {
      setState(() {
        _selectedValues = List.from(widget.initialValues);
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addValue(String value) {
    final trimmedValue = value.trim();
    if (trimmedValue.isNotEmpty && !_selectedValues.contains(trimmedValue)) {
      setState(() {
        _selectedValues.add(trimmedValue);
      });
      widget.onChanged(_selectedValues);
      // Clear both controllers
      _textController.clear();
      _fieldController?.clear();
    }
  }

  void _removeValue(String value) {
    setState(() {
      _selectedValues.remove(value);
    });
    widget.onChanged(_selectedValues);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            return widget.suggestions.where((String option) {
              return option
                  .toLowerCase()
                  .contains(textEditingValue.text.toLowerCase()) &&
                  !_selectedValues.contains(option);
            });
          },
          onSelected: (String selection) {
            _addValue(selection);
            // Clear the field after selection
            _textController.clear();
          },
          fieldViewBuilder: (
            BuildContext context,
            TextEditingController fieldTextEditingController,
            FocusNode fieldFocusNode,
            VoidCallback onFieldSubmitted,
          ) {
            // Store reference to field controller
            _fieldController = fieldTextEditingController;
            
            _textController.text = fieldTextEditingController.text;
            _textController.selection = fieldTextEditingController.selection;
            
            fieldTextEditingController.addListener(() {
              _textController.text = fieldTextEditingController.text;
              _textController.selection = fieldTextEditingController.selection;
            });

            return TextFormField(
              controller: fieldTextEditingController,
              focusNode: fieldFocusNode,
              decoration: InputDecoration(
                labelText: widget.labelText,
                hintText: widget.hintText,
                border: const OutlineInputBorder(),
                prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
              ),
              textCapitalization: TextCapitalization.words,
              onFieldSubmitted: (value) {
                _addValue(value);
                onFieldSubmitted();
              },
            );
          },
          optionsViewBuilder: (
            BuildContext context,
            AutocompleteOnSelected<String> onSelected,
            Iterable<String> options,
          ) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final String option = options.elementAt(index);
                      return InkWell(
                        onTap: () {
                          onSelected(option);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(option),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        if (_selectedValues.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _selectedValues.map((value) {
                return Chip(
                  label: Text(
                    value,
                    style: const TextStyle(fontSize: 12),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => _removeValue(value),
                  backgroundColor: Colors.deepPurple.withOpacity(0.1),
                  labelStyle: const TextStyle(color: Colors.deepPurple),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}

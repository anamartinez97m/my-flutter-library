import 'package:flutter/material.dart';
import 'package:myrandomlibrary/model/reading_club.dart';
import 'package:intl/intl.dart';

class ReadingClubDialog extends StatefulWidget {
  final ReadingClub? existingClub;
  final int bookId;
  final List<String> existingClubNames;

  const ReadingClubDialog({
    super.key,
    this.existingClub,
    required this.bookId,
    this.existingClubNames = const [],
  });

  @override
  State<ReadingClubDialog> createState() => _ReadingClubDialogState();
}

class _ReadingClubDialogState extends State<ReadingClubDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _clubNameController;
  late TextEditingController _progressController;
  DateTime? _selectedDate;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.existingClub != null;
    _clubNameController = TextEditingController(
      text: widget.existingClub?.clubName ?? '',
    );
    _progressController = TextEditingController(
      text: widget.existingClub?.readingProgress.toString() ?? '0',
    );
    if (widget.existingClub?.targetDate != null) {
      try {
        _selectedDate = DateTime.parse(widget.existingClub!.targetDate!);
      } catch (e) {
        _selectedDate = null;
      }
    }
  }

  @override
  void dispose() {
    _clubNameController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final club = ReadingClub(
        clubId: widget.existingClub?.clubId,
        bookId: widget.bookId,
        clubName: _clubNameController.text.trim(),
        targetDate: _selectedDate?.toIso8601String().split('T')[0],
        readingProgress: int.tryParse(_progressController.text) ?? 0,
      );
      Navigator.of(context).pop(club);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Club Membership' : 'Add to Reading Club'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Club Name Field with Autocomplete
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _clubNameController.text),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  return widget.existingClubNames.where((String option) {
                    return option
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  _clubNameController.text = selection;
                },
                fieldViewBuilder: (
                  BuildContext context,
                  TextEditingController fieldTextEditingController,
                  FocusNode fieldFocusNode,
                  VoidCallback onFieldSubmitted,
                ) {
                  // Sync with our controller
                  if (fieldTextEditingController.text.isEmpty &&
                      _clubNameController.text.isNotEmpty) {
                    fieldTextEditingController.text = _clubNameController.text;
                  }
                  
                  return TextFormField(
                    controller: fieldTextEditingController,
                    focusNode: fieldFocusNode,
                    decoration: const InputDecoration(
                      labelText: 'Club Name',
                      hintText: 'Enter or select club name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.groups),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a club name';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      _clubNameController.text = value;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // Target Date Field
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Target Date (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate == null
                            ? 'Select date'
                            : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                        style: TextStyle(
                          color: _selectedDate == null
                              ? Colors.grey[600]
                              : Colors.black,
                        ),
                      ),
                      if (_selectedDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            setState(() {
                              _selectedDate = null;
                            });
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Reading Progress Field
              TextFormField(
                controller: _progressController,
                decoration: const InputDecoration(
                  labelText: 'Reading Progress (%)',
                  hintText: '0-100',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.trending_up),
                  suffixText: '%',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter progress';
                  }
                  final progress = int.tryParse(value);
                  if (progress == null || progress < 0 || progress > 100) {
                    return 'Progress must be between 0 and 100';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Track your reading progress for this club',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(_isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}

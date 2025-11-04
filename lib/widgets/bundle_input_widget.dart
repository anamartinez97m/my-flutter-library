import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BundleInputWidget extends StatefulWidget {
  final bool initialIsBundle;
  final int? initialBundleCount;
  final String? initialBundleNumbers;
  final List<DateTime?>? initialStartDates;
  final List<DateTime?>? initialEndDates;
  final Function(bool isBundle, int? count, String? numbers, List<DateTime?>? startDates, List<DateTime?>? endDates) onChanged;

  const BundleInputWidget({
    super.key,
    required this.initialIsBundle,
    this.initialBundleCount,
    this.initialBundleNumbers,
    this.initialStartDates,
    this.initialEndDates,
    required this.onChanged,
  });

  @override
  State<BundleInputWidget> createState() => _BundleInputWidgetState();
}

class _BundleInputWidgetState extends State<BundleInputWidget> {
  late bool _isBundle;
  late TextEditingController _bundleCountController;
  late TextEditingController _bundleNumbersController;
  List<DateTime?> _startDates = [];
  List<DateTime?> _endDates = [];

  @override
  void initState() {
    super.initState();
    _isBundle = widget.initialIsBundle;
    _bundleCountController = TextEditingController(
      text: widget.initialBundleCount?.toString() ?? '',
    );
    _bundleNumbersController = TextEditingController(
      text: widget.initialBundleNumbers ?? '',
    );
    
    if (widget.initialStartDates != null) {
      _startDates = List.from(widget.initialStartDates!);
    }
    if (widget.initialEndDates != null) {
      _endDates = List.from(widget.initialEndDates!);
    }
    
    _bundleCountController.addListener(_onCountChanged);
  }

  @override
  void dispose() {
    _bundleCountController.dispose();
    _bundleNumbersController.dispose();
    super.dispose();
  }

  void _onCountChanged() {
    final count = int.tryParse(_bundleCountController.text);
    if (count != null && count > 0) {
      setState(() {
        // Adjust lists to match count
        while (_startDates.length < count) {
          _startDates.add(null);
        }
        while (_endDates.length < count) {
          _endDates.add(null);
        }
        if (_startDates.length > count) {
          _startDates = _startDates.sublist(0, count);
        }
        if (_endDates.length > count) {
          _endDates = _endDates.sublist(0, count);
        }
      });
    }
    _notifyChange();
  }

  void _notifyChange() {
    final count = int.tryParse(_bundleCountController.text);
    widget.onChanged(
      _isBundle,
      count,
      _bundleNumbersController.text.trim().isEmpty ? null : _bundleNumbersController.text.trim(),
      _startDates.isEmpty ? null : _startDates,
      _endDates.isEmpty ? null : _endDates,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          title: const Text('This is a bundle'),
          subtitle: const Text('Check if this book contains multiple books in one volume'),
          value: _isBundle,
          onChanged: (value) {
            setState(() {
              _isBundle = value ?? false;
            });
            _notifyChange();
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (_isBundle) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _bundleCountController,
            decoration: const InputDecoration(
              labelText: 'Number of Books in Bundle',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.library_books),
              hintText: 'e.g., 3',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bundleNumbersController,
            decoration: const InputDecoration(
              labelText: 'Saga Numbers (optional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.format_list_numbered),
              hintText: 'e.g., 1-3 or 1, 2, 3',
            ),
            onChanged: (_) => _notifyChange(),
          ),
          const SizedBox(height: 16),
          if (_startDates.isNotEmpty) ...[
            Text(
              'Reading Dates for Each Book',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...List.generate(_startDates.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Book ${index + 1}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _startDates[index] ?? DateTime.now(),
                                    firstDate: DateTime(1900),
                                    lastDate: DateTime.now(),
                                  );
                                  if (date != null) {
                                    setState(() {
                                      _startDates[index] = date;
                                    });
                                    _notifyChange();
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Start Date',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  child: Text(
                                    _startDates[index] != null
                                        ? '${_startDates[index]!.year}-${_startDates[index]!.month.toString().padLeft(2, '0')}-${_startDates[index]!.day.toString().padLeft(2, '0')}'
                                        : 'Select date',
                                    style: TextStyle(
                                      color: _startDates[index] != null ? null : Colors.grey[600],
                                      fontSize: 13,
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
                                    initialDate: _endDates[index] ?? DateTime.now(),
                                    firstDate: DateTime(1900),
                                    lastDate: DateTime.now(),
                                  );
                                  if (date != null) {
                                    setState(() {
                                      _endDates[index] = date;
                                    });
                                    _notifyChange();
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'End Date',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  child: Text(
                                    _endDates[index] != null
                                        ? '${_endDates[index]!.year}-${_endDates[index]!.month.toString().padLeft(2, '0')}-${_endDates[index]!.day.toString().padLeft(2, '0')}'
                                        : 'Select date',
                                    style: TextStyle(
                                      color: _endDates[index] != null ? null : Colors.grey[600],
                                      fontSize: 13,
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
                ),
              );
            }),
          ],
        ],
      ],
    );
  }
}

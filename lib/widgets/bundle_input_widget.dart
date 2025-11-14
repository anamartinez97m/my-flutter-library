import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BundleInputWidget extends StatefulWidget {
  final bool initialIsBundle;
  final int? initialBundleCount;
  final String? initialBundleNumbers;
  final List<int?>? initialBundlePages;
  final List<int?>? initialBundlePublicationYears;
  final List<String?>? initialBundleTitles;
  final Function(bool isBundle, int? count, String? numbers, List<int?>? bundlePages, List<int?>? bundlePublicationYears, List<String?>? bundleTitles) onChanged;

  const BundleInputWidget({
    super.key,
    required this.initialIsBundle,
    this.initialBundleCount,
    this.initialBundleNumbers,
    this.initialBundlePages,
    this.initialBundlePublicationYears,
    this.initialBundleTitles,
    required this.onChanged,
  });

  @override
  State<BundleInputWidget> createState() => _BundleInputWidgetState();
}

class _BundleInputWidgetState extends State<BundleInputWidget> {
  late bool _isBundle;
  late TextEditingController _bundleCountController;
  late TextEditingController _bundleNumbersController;
  List<int?> _bundlePages = [];
  List<int?> _bundlePublicationYears = [];
  List<String?> _bundleTitles = [];

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
    
    if (widget.initialBundlePages != null) {
      _bundlePages = List.from(widget.initialBundlePages!);
    }
    if (widget.initialBundlePublicationYears != null) {
      _bundlePublicationYears = List.from(widget.initialBundlePublicationYears!);
    }
    if (widget.initialBundleTitles != null) {
      _bundleTitles = List.from(widget.initialBundleTitles!);
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
        while (_bundlePages.length < count) {
          _bundlePages.add(null);
        }
        if (_bundlePages.length > count) {
          _bundlePages = _bundlePages.sublist(0, count);
        }
        while (_bundlePublicationYears.length < count) {
          _bundlePublicationYears.add(null);
        }
        if (_bundlePublicationYears.length > count) {
          _bundlePublicationYears = _bundlePublicationYears.sublist(0, count);
        }
        while (_bundleTitles.length < count) {
          _bundleTitles.add(null);
        }
        if (_bundleTitles.length > count) {
          _bundleTitles = _bundleTitles.sublist(0, count);
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
      _bundlePages.isEmpty ? null : _bundlePages,
      _bundlePublicationYears.isEmpty ? null : _bundlePublicationYears,
      _bundleTitles.isEmpty ? null : _bundleTitles,
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
          if (_bundlePages.isNotEmpty) ...[
            Text(
              'Bundle Book Details',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...List.generate(_bundlePages.length, (index) {
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
                        // Book Title input
                        TextFormField(
                          initialValue: (index < _bundleTitles.length && _bundleTitles[index] != null) 
                              ? _bundleTitles[index] 
                              : '',
                          decoration: const InputDecoration(
                            labelText: 'Book Title',
                            border: OutlineInputBorder(),
                            isDense: true,
                            hintText: 'Enter book title',
                          ),
                          onChanged: (value) {
                            setState(() {
                              while (_bundleTitles.length <= index) {
                                _bundleTitles.add(null);
                              }
                              _bundleTitles[index] = value.isEmpty ? null : value;
                            });
                            _notifyChange();
                          },
                        ),
                        const SizedBox(height: 8),
                        // Pages input
                        TextFormField(
                          initialValue: (index < _bundlePages.length && _bundlePages[index] != null) 
                              ? _bundlePages[index].toString() 
                              : '',
                          decoration: const InputDecoration(
                            labelText: 'Pages',
                            border: OutlineInputBorder(),
                            isDense: true,
                            hintText: 'e.g., 250',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              // Ensure the list is large enough
                              while (_bundlePages.length <= index) {
                                _bundlePages.add(null);
                              }
                              _bundlePages[index] = int.tryParse(value);
                            });
                            _notifyChange();
                          },
                        ),
                        const SizedBox(height: 8),
                        // Original Publication Year input
                        TextFormField(
                          initialValue: (index < _bundlePublicationYears.length && _bundlePublicationYears[index] != null) 
                              ? _bundlePublicationYears[index].toString() 
                              : '',
                          decoration: const InputDecoration(
                            labelText: 'Original Publication Year',
                            border: OutlineInputBorder(),
                            isDense: true,
                            hintText: 'e.g., 2020',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              // Ensure the list is large enough
                              while (_bundlePublicationYears.length <= index) {
                                _bundlePublicationYears.add(null);
                              }
                              _bundlePublicationYears[index] = int.tryParse(value);
                            });
                            _notifyChange();
                          },
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

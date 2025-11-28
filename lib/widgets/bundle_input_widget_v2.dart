import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Data class to hold information about a single book in a bundle
class BundleBookData {
  String? sagaNumber;
  String? title;
  String? author;
  int? pages;
  int? publicationYear;
  String? status; // Status value like 'Yes', 'No', 'Started', etc.

  BundleBookData({
    this.sagaNumber,
    this.title,
    this.author,
    this.pages,
    this.publicationYear,
    this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'sagaNumber': sagaNumber,
      'title': title,
      'author': author,
      'pages': pages,
      'publicationYear': publicationYear,
      'status': status,
    };
  }

  factory BundleBookData.fromMap(Map<String, dynamic> map) {
    return BundleBookData(
      sagaNumber: map['sagaNumber'] as String?,
      title: map['title'] as String?,
      author: map['author'] as String?,
      pages: map['pages'] as int?,
      publicationYear: map['publicationYear'] as int?,
      status: map['status'] as String?,
    );
  }
}

class BundleInputWidgetV2 extends StatefulWidget {
  final bool initialIsBundle;
  final int? initialBundleCount;
  final List<BundleBookData>? initialBundleBooks;
  final List<Map<String, dynamic>>? statusOptions; // List of status options
  final Function(bool isBundle, int? count, List<BundleBookData>? bundleBooks) onChanged;
  final bool editMode; // If true, only show title and nsaga fields

  const BundleInputWidgetV2({
    super.key,
    required this.initialIsBundle,
    this.initialBundleCount,
    this.initialBundleBooks,
    this.statusOptions,
    required this.onChanged,
    this.editMode = false, // Default to false (show all fields)
  });

  @override
  State<BundleInputWidgetV2> createState() => _BundleInputWidgetV2State();
}

class _BundleInputWidgetV2State extends State<BundleInputWidgetV2> {
  late bool _isBundle;
  late TextEditingController _bundleCountController;
  List<BundleBookData> _bundleBooks = [];

  @override
  void initState() {
    super.initState();
    _isBundle = widget.initialIsBundle;
    _bundleCountController = TextEditingController(
      text: widget.initialBundleCount?.toString() ?? '',
    );
    
    // Initialize bundle books
    if (widget.initialBundleBooks != null && widget.initialBundleBooks!.isNotEmpty) {
      _bundleBooks = List.from(widget.initialBundleBooks!);
    }
    
    _bundleCountController.addListener(_onCountChanged);
  }

  @override
  void dispose() {
    _bundleCountController.dispose();
    super.dispose();
  }

  void _onCountChanged() {
    final count = int.tryParse(_bundleCountController.text);
    if (count != null && count > 0) {
      setState(() {
        // Adjust list to match count
        while (_bundleBooks.length < count) {
          _bundleBooks.add(BundleBookData(status: 'No')); // Default status
        }
        if (_bundleBooks.length > count) {
          _bundleBooks = _bundleBooks.sublist(0, count);
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
      _bundleBooks.isEmpty ? null : _bundleBooks,
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
          if (_bundleBooks.isNotEmpty) ...[
            Text(
              'Bundle Book Details',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...List.generate(_bundleBooks.length, (index) {
              final bookData = _bundleBooks[index];
              final bookTitle = (bookData.title != null && bookData.title!.isNotEmpty)
                  ? bookData.title!
                  : 'Book ${index + 1}';
              final statusValue = bookData.status ?? 'No';
              
              // Determine icon and color based on status
              IconData statusIcon;
              Color statusColor;
              if (statusValue == 'Yes') {
                statusIcon = Icons.check_circle;
                statusColor = Colors.green;
              } else if (statusValue == 'Started') {
                statusIcon = Icons.play_circle;
                statusColor = Colors.orange;
              } else {
                statusIcon = Icons.circle_outlined;
                statusColor = Colors.grey;
              }
              
              return Card(
                key: ValueKey('bundle_card_$index'),
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with icon and title
                      Row(
                        children: [
                          Icon(
                            statusIcon,
                            color: statusColor,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bookTitle,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: statusValue == 'Yes' ? Colors.green.shade700 : null,
                                  ),
                                ),
                                Text(
                                  statusValue,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Status dropdown - only show when NOT in edit mode
                      if (!widget.editMode && widget.statusOptions != null && widget.statusOptions!.isNotEmpty)
                        DropdownButtonFormField<String>(
                          value: statusValue,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: widget.statusOptions!.map((status) {
                            final value = status['value'] as String;
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _bundleBooks[index].status = value;
                            });
                            _notifyChange();
                          },
                        ),
                      if (!widget.editMode)
                        const SizedBox(height: 8),
                      // N_Saga input
                      TextFormField(
                        key: ValueKey('saga_$index'),
                        initialValue: bookData.sagaNumber ?? '',
                        decoration: const InputDecoration(
                          labelText: 'Saga Number (N_Saga)',
                          border: OutlineInputBorder(),
                          isDense: true,
                          hintText: 'e.g., 1 or 1.5',
                        ),
                        onChanged: (value) {
                          setState(() {
                            _bundleBooks[index].sagaNumber = value.isEmpty ? null : value;
                          });
                          _notifyChange();
                        },
                      ),
                      const SizedBox(height: 8),
                      // Book Title input
                      TextFormField(
                        key: ValueKey('title_$index'),
                        initialValue: bookData.title ?? '',
                        decoration: const InputDecoration(
                          labelText: 'Book Title',
                          border: OutlineInputBorder(),
                          isDense: true,
                          hintText: 'Enter book title',
                        ),
                        onChanged: (value) {
                          setState(() {
                            _bundleBooks[index].title = value.isEmpty ? null : value;
                          });
                          _notifyChange();
                        },
                      ),
                      const SizedBox(height: 8),
                      // Author input - only show when NOT in edit mode
                      if (!widget.editMode)
                        TextFormField(
                        key: ValueKey('author_$index'),
                        initialValue: bookData.author ?? '',
                        decoration: const InputDecoration(
                          labelText: 'Author(s)',
                          border: OutlineInputBorder(),
                          isDense: true,
                          hintText: 'Enter author name(s), separate with commas',
                        ),
                        onChanged: (value) {
                          setState(() {
                            _bundleBooks[index].author = value.isEmpty ? null : value;
                          });
                          _notifyChange();
                        },
                      ),
                      if (!widget.editMode)
                        const SizedBox(height: 8),
                      // Pages input - only show when NOT in edit mode
                      if (!widget.editMode)
                        TextFormField(
                        key: ValueKey('pages_$index'),
                        initialValue: bookData.pages?.toString() ?? '',
                        decoration: const InputDecoration(
                          labelText: 'Pages',
                          border: OutlineInputBorder(),
                          isDense: true,
                          hintText: 'e.g., 250',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            _bundleBooks[index].pages = int.tryParse(value);
                          });
                          _notifyChange();
                        },
                      ),
                      if (!widget.editMode)
                        const SizedBox(height: 8),
                      // Original Publication Year input - only show when NOT in edit mode
                      if (!widget.editMode)
                        TextFormField(
                        key: ValueKey('year_$index'),
                        initialValue: bookData.publicationYear?.toString() ?? '',
                        decoration: const InputDecoration(
                          labelText: 'Original Publication Year',
                          border: OutlineInputBorder(),
                          isDense: true,
                          hintText: 'e.g., 2020',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            _bundleBooks[index].publicationYear = int.tryParse(value);
                          });
                          _notifyChange();
                        },
                      ),
                    ],
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

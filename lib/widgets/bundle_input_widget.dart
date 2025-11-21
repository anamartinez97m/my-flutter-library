import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BundleInputWidget extends StatefulWidget {
  final bool initialIsBundle;
  final int? initialBundleCount;
  final String? initialBundleNumbers;
  final List<int?>? initialBundlePages;
  final List<int?>? initialBundlePublicationYears;
  final List<String?>? initialBundleTitles;
  final List<String?>? initialBundleAuthors;
  final Map<int, bool>? bundleBooksReadStatus; // Map of bundle index to read status
  final Map<int, bool>? bundleBooksHasReadingSessions;
  final Function(bool isBundle, int? count, String? numbers, List<int?>? bundlePages, List<int?>? bundlePublicationYears, List<String?>? bundleTitles, List<String?>? bundleAuthors) onChanged;
  final Function(int bundleIndex, bool isRead)? onReadStatusChanged; // Callback for manual read status changes

  const BundleInputWidget({
    super.key,
    required this.initialIsBundle,
    this.initialBundleCount,
    this.initialBundleNumbers,
    this.initialBundlePages,
    this.initialBundlePublicationYears,
    this.initialBundleTitles,
    this.initialBundleAuthors,
    this.bundleBooksReadStatus,
    this.bundleBooksHasReadingSessions,
    required this.onChanged,
    this.onReadStatusChanged,
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
  List<String?> _bundleAuthors = [];
  List<String?> _bundleSagaNumbers = []; // N_Saga for each book in bundle
  Set<int> _expandedPanels = {}; // Track which panels are expanded

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
    
    // Initialize all panels as expanded by default
    if (widget.initialBundleCount != null && widget.initialBundleCount! > 0) {
      _expandedPanels = Set.from(List.generate(widget.initialBundleCount!, (index) => index));
    }
    
    if (widget.initialBundlePages != null) {
      _bundlePages = List.from(widget.initialBundlePages!);
    }
    if (widget.initialBundlePublicationYears != null) {
      _bundlePublicationYears = List.from(widget.initialBundlePublicationYears!);
    }
    if (widget.initialBundleTitles != null) {
      _bundleTitles = List.from(widget.initialBundleTitles!);
    }
    if (widget.initialBundleAuthors != null) {
      _bundleAuthors = List.from(widget.initialBundleAuthors!);
    }
    
    // Initialize saga numbers from bundleNumbers string if available
    if (widget.initialBundleNumbers != null && widget.initialBundleNumbers!.isNotEmpty) {
      _bundleSagaNumbers = _parseSagaNumbers(widget.initialBundleNumbers!);
    }
    
    _bundleCountController.addListener(_onCountChanged);
    
    // Expand first panel by default if there are bundle books
    if (_bundlePages.isNotEmpty) {
      _expandedPanels.add(0);
    }
  }

  @override
  void dispose() {
    _bundleCountController.dispose();
    _bundleNumbersController.dispose();
    super.dispose();
  }

  List<String?> _parseSagaNumbers(String numbersStr) {
    // Parse formats like "1-3", "1, 2, 3", "1,2,3"
    final List<String?> result = [];
    
    if (numbersStr.contains('-')) {
      // Range format: "1-3"
      final parts = numbersStr.split('-');
      if (parts.length == 2) {
        final start = int.tryParse(parts[0].trim());
        final end = int.tryParse(parts[1].trim());
        if (start != null && end != null) {
          for (int i = start; i <= end; i++) {
            result.add(i.toString());
          }
        }
      }
    } else if (numbersStr.contains(',')) {
      // Comma-separated format: "1, 2, 3"
      final parts = numbersStr.split(',');
      for (final part in parts) {
        final trimmed = part.trim();
        if (trimmed.isNotEmpty) {
          result.add(trimmed);
        }
      }
    } else {
      // Single number
      result.add(numbersStr.trim());
    }
    
    return result;
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
        while (_bundleAuthors.length < count) {
          _bundleAuthors.add(null);
        }
        if (_bundleAuthors.length > count) {
          _bundleAuthors = _bundleAuthors.sublist(0, count);
        }
        while (_bundleSagaNumbers.length < count) {
          _bundleSagaNumbers.add(null);
        }
        if (_bundleSagaNumbers.length > count) {
          _bundleSagaNumbers = _bundleSagaNumbers.sublist(0, count);
        }
        
        // Expand all panels by default
        _expandedPanels = Set.from(List.generate(count, (index) => index));
      });
    }
    _notifyChange();
  }

  void _notifyChange() {
    final count = int.tryParse(_bundleCountController.text);
    
    // Build bundleNumbers string from individual saga numbers if they exist
    String? bundleNumbersStr;
    if (_bundleSagaNumbers.isNotEmpty && _bundleSagaNumbers.any((n) => n != null && n.isNotEmpty)) {
      // Use comma-separated format for individual saga numbers
      bundleNumbersStr = _bundleSagaNumbers
          .where((n) => n != null && n.isNotEmpty)
          .join(', ');
    } else if (_bundleNumbersController.text.trim().isNotEmpty) {
      // Fall back to the text field value
      bundleNumbersStr = _bundleNumbersController.text.trim();
    }
    
    widget.onChanged(
      _isBundle,
      count,
      bundleNumbersStr,
      _bundlePages.isEmpty ? null : _bundlePages,
      _bundlePublicationYears.isEmpty ? null : _bundlePublicationYears,
      _bundleTitles.isEmpty ? null : _bundleTitles,
      _bundleAuthors.isEmpty ? null : _bundleAuthors,
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
            ExpansionPanelList(
              key: ValueKey(_bundlePages.length), // Force rebuild when count changes
              elevation: 1,
              expandedHeaderPadding: EdgeInsets.zero,
              expansionCallback: (int index, bool isExpanded) {
                setState(() {
                  if (isExpanded) {
                    _expandedPanels.remove(index);
                  } else {
                    _expandedPanels.add(index);
                  }
                });
              },
              children: List.generate(_bundlePages.length, (index) {
                final isRead = widget.bundleBooksReadStatus?[index] ?? false;
                final bookTitle = (index < _bundleTitles.length && _bundleTitles[index] != null && _bundleTitles[index]!.isNotEmpty)
                    ? _bundleTitles[index]!
                    : 'Book ${index + 1}';
                
                return ExpansionPanel(
                  isExpanded: _expandedPanels.contains(index),
                  canTapOnHeader: true,
                  backgroundColor: Colors.grey[50],
                  headerBuilder: (BuildContext context, bool isExpanded) {
                    return ListTile(
                      leading: Icon(
                        isRead ? Icons.check_circle : Icons.circle_outlined,
                        color: isRead ? Colors.green : Colors.grey,
                      ),
                      title: Text(
                        bookTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isRead ? Colors.green.shade700 : null,
                        ),
                      ),
                      subtitle: Text(
                        isRead ? 'Read' : 'Not read',
                        style: TextStyle(
                          fontSize: 12,
                          color: isRead ? Colors.green : Colors.grey,
                        ),
                      ),
                    );
                  },
                  body: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.onReadStatusChanged != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'Mark as read',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Transform.scale(
                                  scale: 0.8,
                                  child: Checkbox(
                                    value: isRead,
                                    onChanged: (widget.bundleBooksHasReadingSessions?[index] ?? false)
                                        ? null
                                        : (value) {
                                            widget.onReadStatusChanged!(index, value ?? false);
                                          },
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // N_Saga input
                        TextFormField(
                          key: ValueKey('saga_$index'),
                          initialValue: (index < _bundleSagaNumbers.length && _bundleSagaNumbers[index] != null) 
                              ? _bundleSagaNumbers[index] 
                              : '',
                          decoration: const InputDecoration(
                            labelText: 'Saga Number (N_Saga)',
                            border: OutlineInputBorder(),
                            isDense: true,
                            hintText: 'e.g., 1 or 1.5',
                          ),
                          onChanged: (value) {
                            setState(() {
                              while (_bundleSagaNumbers.length <= index) {
                                _bundleSagaNumbers.add(null);
                              }
                              _bundleSagaNumbers[index] = value.isEmpty ? null : value;
                            });
                            _notifyChange();
                          },
                        ),
                        const SizedBox(height: 8),
                        // Book Title input
                        TextFormField(
                          key: ValueKey('title_$index'),
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
                        // Author input
                        TextFormField(
                          key: ValueKey('author_$index'),
                          initialValue: (index < _bundleAuthors.length && _bundleAuthors[index] != null) 
                              ? _bundleAuthors[index] 
                              : '',
                          decoration: const InputDecoration(
                            labelText: 'Author(s)',
                            border: OutlineInputBorder(),
                            isDense: true,
                            hintText: 'Enter author name(s), separate with commas',
                          ),
                          onChanged: (value) {
                            setState(() {
                              while (_bundleAuthors.length <= index) {
                                _bundleAuthors.add(null);
                              }
                              _bundleAuthors[index] = value.isEmpty ? null : value;
                            });
                            _notifyChange();
                          },
                        ),
                        const SizedBox(height: 8),
                        // Pages input
                        TextFormField(
                          key: ValueKey('pages_$index'),
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
                          key: ValueKey('year_$index'),
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
                );
              }),
            ),
          ],
        ],
      ],
    );
  }
}

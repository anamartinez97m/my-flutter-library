import 'package:flutter/material.dart';

class GoodreadsImportDialog extends StatefulWidget {
  final List<String> availableTags;

  const GoodreadsImportDialog({
    super.key,
    required this.availableTags,
  });

  @override
  State<GoodreadsImportDialog> createState() => _GoodreadsImportDialogState();
}

class _GoodreadsImportDialogState extends State<GoodreadsImportDialog> {
  late String _selectedOption; // 'all' or 'tag'
  String? _selectedTag;
  final TextEditingController _customTagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedOption = 'all';
  }

  @override
  void dispose() {
    _customTagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import from Goodreads'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How would you like to import your books?',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            // Option 1: Import all books
            RadioListTile<String>(
              title: const Text('Import all books'),
              value: 'all',
              groupValue: _selectedOption,
              onChanged: (value) {
                setState(() {
                  _selectedOption = value ?? 'all';
                });
              },
            ),
            const SizedBox(height: 8),
            // Option 2: Import by tag
            RadioListTile<String>(
              title: const Text('Import books from a specific tag'),
              value: 'tag',
              groupValue: _selectedOption,
              onChanged: (value) {
                setState(() {
                  _selectedOption = value ?? 'all';
                });
              },
            ),
            if (_selectedOption == 'tag') ...[
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Select or enter a tag:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              if (widget.availableTags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonFormField<String>(
                    value: _selectedTag,
                    decoration: const InputDecoration(
                      labelText: 'Available tags',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    isExpanded: true,
                    items: widget.availableTags.map((tag) {
                      return DropdownMenuItem(
                        value: tag,
                        child: SizedBox(
                          width: 200,
                          child: Text(
                            tag,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTag = value;
                        _customTagController.clear();
                      });
                    },
                  ),
                ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _customTagController,
                  decoration: const InputDecoration(
                    labelText: 'Or enter a custom tag',
                    border: OutlineInputBorder(),
                    isDense: true,
                    hintText: 'e.g., owned, wishlist',
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      setState(() {
                        _selectedTag = null;
                      });
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_selectedOption == 'tag') {
              final tag = _customTagController.text.trim().isNotEmpty
                  ? _customTagController.text.trim()
                  : _selectedTag;
              if (tag == null || tag.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select or enter a tag'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context, {'mode': 'tag', 'tag': tag});
            } else {
              Navigator.pop(context, {'mode': 'all'});
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
          child: const Text('Import'),
        ),
      ],
    );
  }
}

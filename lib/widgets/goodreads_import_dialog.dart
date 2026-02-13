import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';

class GoodreadsImportDialog extends StatefulWidget {
  final List<String> availableTags;

  const GoodreadsImportDialog({super.key, required this.availableTags});

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
      title: Text(AppLocalizations.of(context)!.import_from_goodreads),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.how_import_books,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            // Option 1: Import all books
            RadioListTile<String>(
              title: Text(AppLocalizations.of(context)!.import_all_books),
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
              title: Text(AppLocalizations.of(context)!.import_books_from_tag),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  AppLocalizations.of(context)!.select_or_enter_tag,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (widget.availableTags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonFormField<String>(
                    value: _selectedTag,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.available_tags,
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    isExpanded: true,
                    items:
                        widget.availableTags.map((tag) {
                          return DropdownMenuItem(
                            value: tag,
                            child: SizedBox(
                              width: 200,
                              child: Text(tag, overflow: TextOverflow.ellipsis),
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
                  decoration: InputDecoration(
                    labelText:
                        AppLocalizations.of(context)!.or_enter_custom_tag,
                    border: const OutlineInputBorder(),
                    isDense: true,
                    hintText: AppLocalizations.of(context)!.eg_owned_wishlist,
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
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            if (_selectedOption == 'tag') {
              final tag =
                  _customTagController.text.trim().isNotEmpty
                      ? _customTagController.text.trim()
                      : _selectedTag;
              if (tag == null || tag.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.please_select_or_enter_tag,
                    ),
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
          child: Text(AppLocalizations.of(context)!.import_label),
        ),
      ],
    );
  }
}

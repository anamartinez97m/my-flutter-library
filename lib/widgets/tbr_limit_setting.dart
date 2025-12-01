import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TBRLimitSetting extends StatefulWidget {
  const TBRLimitSetting({super.key});

  @override
  State<TBRLimitSetting> createState() => _TBRLimitSettingState();
}

class _TBRLimitSettingState extends State<TBRLimitSetting> {
  int _tbrLimit = 5; // Default value
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTBRLimit();
  }

  Future<void> _loadTBRLimit() async {
    final prefs = await SharedPreferences.getInstance();
    final limit = prefs.getInt('tbr_limit') ?? 5;
    setState(() {
      _tbrLimit = limit;
      _controller.text = limit.toString();
    });
  }

  Future<void> _saveTBRLimit(int limit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tbr_limit', limit);
    setState(() {
      _tbrLimit = limit;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('TBR limit set to $limit books'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showEditDialog() {
    _controller.text = _tbrLimit.toString();

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              final currentValue = int.tryParse(_controller.text);
              final isValid =
                  currentValue != null &&
                  currentValue > 0 &&
                  currentValue <= 200;
              String? errorText;

              if (_controller.text.isNotEmpty) {
                if (currentValue == null || currentValue <= 0) {
                  errorText =
                      AppLocalizations.of(context)!.please_enter_valid_number;
                } else if (currentValue > 200) {
                  errorText =
                      AppLocalizations.of(context)!.maximum_limit_200_books;
                }
              }

              return AlertDialog(
                title: Text(AppLocalizations.of(context)!.set_tbr_limit),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.max_tbr_books_description,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.tbr_limit,
                        border: const OutlineInputBorder(),
                        suffixText: AppLocalizations.of(context)!.books,
                        helperText:
                            AppLocalizations.of(context)!.range_1_200_books,
                        errorText: errorText,
                      ),
                      autofocus: true,
                      onChanged: (value) {
                        setState(() {}); // Rebuild to update validation
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed:
                        isValid
                            ? () {
                              _saveTBRLimit(currentValue);
                              Navigator.pop(context);
                            }
                            : null,
                    child: const Text('Save'),
                  ),
                ],
              );
            },
          ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.bookmark_add, color: Colors.deepPurple),
        title: Text(AppLocalizations.of(context)!.tbr_limit),
        subtitle: Text(AppLocalizations.of(context)!.max_tbr_books_subtitle(_tbrLimit.toString())),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: _showEditDialog,
        ),
        onTap: _showEditDialog,
      ),
    );
  }
}

/// Helper function to get TBR limit from SharedPreferences
Future<int> getTBRLimit() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt('tbr_limit') ?? 5;
}

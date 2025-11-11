import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      builder: (context) => AlertDialog(
        title: const Text('Set TBR Limit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Maximum number of books you can mark as "To Be Read" at once:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'TBR Limit',
                border: OutlineInputBorder(),
                suffixText: 'books',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newLimit = int.tryParse(_controller.text);
              if (newLimit != null && newLimit > 0) {
                _saveTBRLimit(newLimit);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid number greater than 0'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.bookmark_add, color: Colors.deepPurple),
        title: const Text('TBR Limit'),
        subtitle: Text('Maximum books in "To Be Read": $_tbrLimit'),
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

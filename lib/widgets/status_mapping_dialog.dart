import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';

/// Dialog for mapping user's CSV status values to predefined app status values
class StatusMappingDialog extends StatefulWidget {
  final List<String> predefinedStatuses;

  const StatusMappingDialog({super.key, required this.predefinedStatuses});

  @override
  State<StatusMappingDialog> createState() => _StatusMappingDialogState();
}

class _StatusMappingDialogState extends State<StatusMappingDialog> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    // Create a controller for each predefined status
    for (final status in widget.predefinedStatuses) {
      _controllers[status] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Map<String, String> _getMappings() {
    final mappings = <String, String>{};
    for (final entry in _controllers.entries) {
      final userValue = entry.value.text.trim();
      if (userValue.isNotEmpty) {
        mappings[userValue.toLowerCase()] = entry.key;
      }
    }
    return mappings;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        AppLocalizations.of(context)!.map_status_values,
        style: const TextStyle(fontSize: 16),
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.match_csv_status_values,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              ...widget.predefinedStatuses.map((status) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'App: $status',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _controllers[status],
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: _getHintForStatus(status),
                          hintStyle: const TextStyle(fontSize: 11),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.leave_empty_if_not_used,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            final mappings = _getMappings();
            Navigator.pop(context, mappings);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          child: Text(AppLocalizations.of(context)!.continue_import),
        ),
      ],
    );
  }

  String _getHintForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'yes':
        return 'read, finished, completed';
      case 'no':
        return 'to-read, unread, tbr';
      case 'started':
        return 'reading, in-progress';
      case 'tbreleased':
        return 'unreleased, upcoming';
      default:
        return '';
    }
  }
}

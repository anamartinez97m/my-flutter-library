import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/providers/locale_provider.dart';
import 'package:myrandomlibrary/providers/theme_provider.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/screens/admin_csv_import.dart';
import 'package:myrandomlibrary/screens/manage_dropdowns.dart';
import 'package:myrandomlibrary/screens/manage_rating_fields.dart';
import 'package:myrandomlibrary/screens/manage_club_names.dart';
import 'package:myrandomlibrary/screens/bundle_migration_screen.dart';
import 'package:myrandomlibrary/screens/reverse_assign_screen.dart';
import 'package:myrandomlibrary/screens/fill_empty_wizard_screen.dart';
import 'package:myrandomlibrary/screens/smart_suggestions_screen.dart';
import 'package:myrandomlibrary/services/google_auth_service.dart';
import 'package:myrandomlibrary/services/backup_service.dart';
import 'package:myrandomlibrary/services/notification_service.dart';
import 'package:myrandomlibrary/utils/csv_import_helper.dart';
import 'package:myrandomlibrary/utils/bundle_migration.dart';
import 'package:myrandomlibrary/utils/reading_session_migration.dart';
import 'package:myrandomlibrary/widgets/tbr_limit_setting.dart';
import 'package:myrandomlibrary/widgets/status_mapping_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isAdmin = false;
  Set<String> _enabledFilters = {};
  Set<String> _enabledCardFields = {};

  // Reading Reminders state
  bool _readingReminderEnabled = false;
  int _readingReminderHour = 21;
  int _readingReminderMinute = 0;
  bool _readingReminderAllBooks = true;

  // Price Statistics & Currency
  bool _showPriceStatistics = false;
  String _currencySymbol = '€';

  // Cloud Sync state
  bool _isCloudBusy = false;
  Map<String, dynamic>? _backupMetadata;
  User? _currentUser;
  BackupFrequency _autoBackupFrequency = BackupFrequency.off;
  String? _lastAutoBackupTimestamp;

  // Available filter keys
  static const List<String> _availableFilterKeys = [
    'title',
    'isbn',
    'author',
    'status',
    'format',
    'genre',
    'language',
    'place',
    'editorial',
    'saga',
    'saga_universe',
    'format_saga',
    'pages_empty',
    'is_bundle',
    'is_tandem',
    'saga_format_without_saga',
    'saga_format_without_nsaga',
    'saga_without_format_saga',
    'publication_year_empty',
    'rating',
  ];

  String _getFilterLabel(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'title':
        return l10n.filter_title;
      case 'isbn':
        return l10n.filter_isbn_asin;
      case 'author':
        return l10n.filter_author;
      case 'status':
        return l10n.filter_status;
      case 'format':
        return l10n.filter_format;
      case 'genre':
        return l10n.filter_genre;
      case 'language':
        return l10n.filter_language;
      case 'place':
        return l10n.filter_place;
      case 'editorial':
        return l10n.filter_editorial;
      case 'saga':
        return l10n.filter_saga;
      case 'saga_universe':
        return l10n.filter_saga_universe;
      case 'format_saga':
        return l10n.filter_format_saga;
      case 'pages_empty':
        return l10n.filter_pages_empty;
      case 'is_bundle':
        return l10n.filter_is_bundle;
      case 'is_tandem':
        return l10n.filter_is_tandem;
      case 'saga_format_without_saga':
        return l10n.filter_saga_format_without_saga;
      case 'saga_format_without_nsaga':
        return l10n.filter_saga_format_without_nsaga;
      case 'saga_without_format_saga':
        return l10n.filter_saga_without_format_saga;
      case 'publication_year_empty':
        return l10n.filter_publication_year_empty;
      case 'rating':
        return l10n.filter_rating;
      default:
        return key;
    }
  }

  // Available card field keys
  static const List<String> _availableCardFieldKeys = [
    'title',
    'author',
    'saga',
    'format',
    'language',
    'isbn',
    'pages',
    'genre',
    'editorial',
    'publication_year',
    'publication_date',
    'rating',
    'read_count',
    'status',
    'progress',
  ];

  String _getCardFieldLabel(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'title':
        return l10n.card_field_title;
      case 'author':
        return l10n.card_field_author;
      case 'saga':
        return l10n.card_field_saga;
      case 'format':
        return l10n.card_field_format;
      case 'language':
        return l10n.card_field_language;
      case 'isbn':
        return l10n.card_field_isbn;
      case 'pages':
        return l10n.card_field_pages;
      case 'genre':
        return l10n.card_field_genre;
      case 'editorial':
        return l10n.card_field_editorial;
      case 'publication_year':
        return l10n.card_field_publication_year;
      case 'publication_date':
        return l10n.card_field_publication_date;
      case 'rating':
        return l10n.card_field_rating;
      case 'read_count':
        return l10n.card_field_read_count;
      case 'status':
        return l10n.card_field_status;
      case 'progress':
        return l10n.card_field_progress;
      default:
        return key;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadEnabledFilters();
    _loadEnabledCardFields();
    _loadReadingReminderSettings();
    _loadPriceSettings();
    _loadAdminMode();
    _currentUser = GoogleAuthService.instance.currentUser;
    if (_currentUser != null) {
      _loadBackupMetadata();
    }
    _loadAutoBackupSettings();
  }

  Future<void> _loadReadingReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _readingReminderEnabled =
          prefs.getBool(NotificationService.prefReadingReminderEnabled) ??
          false;
      _readingReminderHour =
          prefs.getInt(NotificationService.prefReadingReminderHour) ?? 21;
      _readingReminderMinute =
          prefs.getInt(NotificationService.prefReadingReminderMinute) ?? 0;
      _readingReminderAllBooks =
          prefs.getBool(NotificationService.prefReadingReminderAllBooks) ??
          true;
    });
  }

  Future<void> _saveReadingReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      NotificationService.prefReadingReminderEnabled,
      _readingReminderEnabled,
    );
    await prefs.setInt(
      NotificationService.prefReadingReminderHour,
      _readingReminderHour,
    );
    await prefs.setInt(
      NotificationService.prefReadingReminderMinute,
      _readingReminderMinute,
    );
    await prefs.setBool(
      NotificationService.prefReadingReminderAllBooks,
      _readingReminderAllBooks,
    );

    // Reschedule notifications
    final notificationService = NotificationService();
    await notificationService.scheduleReadingReminders();
  }

  Future<void> _loadPriceSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showPriceStatistics = prefs.getBool('show_price_statistics') ?? false;
      _currencySymbol = prefs.getString('currency_symbol') ?? '€';
    });
  }

  Future<void> _savePriceSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_price_statistics', _showPriceStatistics);
    await prefs.setString('currency_symbol', _currencySymbol);
  }

  Future<void> _loadAutoBackupSettings() async {
    final freq = await BackupService.instance.getBackupFrequency();
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _autoBackupFrequency = freq;
      _lastAutoBackupTimestamp = prefs.getString(
        BackupService.prefLastAutoBackupTimestamp,
      );
    });
  }

  Future<void> _setAutoBackupFrequency(BackupFrequency freq) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      BackupService.prefAutoBackupFrequency,
      BackupService.instance.frequencyToString(freq),
    );
    if (!context.mounted) return;
    setState(() {
      _autoBackupFrequency = freq;
    });
    final label = _frequencyLabel(freq);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          freq == BackupFrequency.off
              ? l10n.auto_backup_disabled
              : l10n.auto_backup_enabled(label),
        ),
        backgroundColor:
            freq == BackupFrequency.off ? Colors.grey : Colors.green,
      ),
    );
  }

  String _frequencyLabel(BackupFrequency freq) {
    switch (freq) {
      case BackupFrequency.off:
        return AppLocalizations.of(context)!.backup_frequency_off;
      case BackupFrequency.daily:
        return AppLocalizations.of(context)!.backup_frequency_daily;
      case BackupFrequency.weekly:
        return AppLocalizations.of(context)!.backup_frequency_weekly;
      case BackupFrequency.monthly:
        return AppLocalizations.of(context)!.backup_frequency_monthly;
    }
  }

  void _showCurrencyPicker() {
    final currencies = [
      '\u20ac',
      '\$',
      '\u00a3',
      '\u00a5',
      'CHF',
      'kr',
      'R\$',
      '\u20b9',
    ];
    final customController = TextEditingController();
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  AppLocalizations.of(context)!.currency_setting,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    currencies.map((symbol) {
                      final isSelected = symbol == _currencySymbol;
                      return ChoiceChip(
                        label: Text(
                          symbol,
                          style: const TextStyle(fontSize: 16),
                        ),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _currencySymbol = symbol;
                          });
                          _savePriceSettings();
                          Navigator.pop(ctx);
                        },
                      );
                    }).toList(),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: customController,
                        decoration: InputDecoration(
                          hintText:
                              AppLocalizations.of(
                                context,
                              )!.custom_currency_hint,
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                        maxLength: 5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final value = customController.text.trim();
                        if (value.isNotEmpty) {
                          setState(() {
                            _currencySymbol = value;
                          });
                          _savePriceSettings();
                          Navigator.pop(ctx);
                        }
                      },
                      child: Text(AppLocalizations.of(context)!.save),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadBackupMetadata() async {
    if (_currentUser == null) return;
    final metadata = await BackupService.instance.getBackupMetadata(
      _currentUser!.uid,
    );
    if (!mounted) return;
    setState(() {
      _backupMetadata = metadata;
    });
  }

  Future<void> _signInWithGoogle() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isCloudBusy = true);
    try {
      final user = await GoogleAuthService.instance.signInWithGoogle();
      if (!context.mounted) return;
      setState(() {
        _currentUser = user;
        _isCloudBusy = false;
      });
      if (user != null) {
        _loadBackupMetadata();
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.sign_in_failed),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Sign-in error: $e');
      if (!context.mounted) return;
      setState(() => _isCloudBusy = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('${l10n.sign_in_failed}: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 10),
        ),
      );
    }
  }

  Future<void> _signOut() async {
    await GoogleAuthService.instance.signOut();
    if (!mounted) return;
    setState(() {
      _currentUser = null;
      _backupMetadata = null;
    });
  }

  Future<void> _uploadBackup() async {
    if (_currentUser == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context, rootNavigator: true);

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.backup_to_cloud),
            content: Text(AppLocalizations.of(context)!.upload_your_library),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(AppLocalizations.of(context)!.confirm),
              ),
            ],
          ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    _showLoadingDialog(l10n.cloud_backup_in_progress);
    setState(() => _isCloudBusy = true);

    try {
      final success = await BackupService.instance.uploadBackup(
        _currentUser!.uid,
      );

      if (!context.mounted) return;
      navigator.pop();
      if (success) {
        _loadBackupMetadata();
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.cloud_backup_success),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.error), backgroundColor: Colors.red),
        );
      }
      setState(() => _isCloudBusy = false);
    } catch (e) {
      if (!context.mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
      setState(() => _isCloudBusy = false);
    }
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '?';
    try {
      final dt = DateTime.parse(timestamp);
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return timestamp;
    }
  }

  Future<void> _downloadBackup() async {
    if (_currentUser == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context, rootNavigator: true);
    final bookProvider = Provider.of<BookProvider?>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.restore_from_cloud),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.cloud_restore_warning,
                  style: const TextStyle(color: Colors.red),
                ),
                if (_backupMetadata != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.cloud_backup_books(_backupMetadata!['bookCount'] ?? '?'),
                  ),
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.last_backup(_backupMetadata!['timestamp'] ?? '?'),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text(AppLocalizations.of(context)!.restore),
              ),
            ],
          ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    _showLoadingDialog(l10n.cloud_restore_in_progress);
    setState(() => _isCloudBusy = true);

    try {
      final success = await BackupService.instance.downloadBackup(
        _currentUser!.uid,
      );

      if (!context.mounted) return;
      navigator.pop();
      if (success) {
        // Reload books
        await bookProvider?.loadBooks();

        // Reload theme and locale from restored SharedPreferences
        if (!context.mounted) return;
        await themeProvider.reloadFromPreferences();

        if (!context.mounted) return;
        await localeProvider.reloadFromPreferences();

        // Reload local settings state (filters, card fields, reading reminders)
        await _loadEnabledFilters();
        await _loadEnabledCardFields();
        await _loadReadingReminderSettings();

        if (!context.mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.cloud_restore_success),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.no_cloud_backup),
            backgroundColor: Colors.orange,
          ),
        );
      }
      setState(() => _isCloudBusy = false);
    } catch (e) {
      if (!context.mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
      setState(() => _isCloudBusy = false);
    }
  }

  Future<void> _loadAdminMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAdmin = prefs.getBool('is_admin') ?? false;
    });
  }

  Future<void> _loadEnabledFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final savedFilters = prefs.getStringList('enabled_filters');
    setState(() {
      if (savedFilters != null) {
        _enabledFilters = savedFilters.toSet();
      } else {
        // Default: enable all filters
        _enabledFilters = _availableFilterKeys.toSet();
      }
    });
  }

  Future<void> _saveEnabledFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('enabled_filters', _enabledFilters.toList());
  }

  Future<void> _loadEnabledCardFields() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCardFields = prefs.getStringList('enabled_card_fields');
    setState(() {
      if (savedCardFields != null) {
        _enabledCardFields = savedCardFields.toSet();
      } else {
        // Default: show essential fields
        _enabledCardFields = {'title', 'author', 'saga', 'format', 'language'};
      }
    });
  }

  Future<void> _saveEnabledCardFields() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'enabled_card_fields',
      _enabledCardFields.toList(),
    );
  }

  void _showFiltersDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text(
                    AppLocalizations.of(context)!.customize_home_filters,
                  ),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _availableFilterKeys.length,
                      itemBuilder: (context, index) {
                        final key = _availableFilterKeys[index];
                        final label = _getFilterLabel(context, key);

                        return CheckboxListTile(
                          title: Text(label),
                          value: _enabledFilters.contains(key),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _enabledFilters.add(key);
                              } else {
                                _enabledFilters.remove(key);
                              }
                            });
                            setDialogState(() {}); // Rebuild dialog
                            _saveEnabledFilters();
                          },
                        );
                      },
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _enabledFilters = _availableFilterKeys.toSet();
                        });
                        setDialogState(() {}); // Rebuild dialog
                        _saveEnabledFilters();
                      },
                      child: Text(AppLocalizations.of(context)!.select_all),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _enabledFilters.clear();
                        });
                        setDialogState(() {}); // Rebuild dialog
                        _saveEnabledFilters();
                      },
                      child: Text(AppLocalizations.of(context)!.clear_all),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(AppLocalizations.of(context)!.close),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showCardFieldsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text(
                    AppLocalizations.of(context)!.customize_card_fields,
                  ),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _availableCardFieldKeys.length,
                      itemBuilder: (context, index) {
                        final key = _availableCardFieldKeys[index];
                        final label = _getCardFieldLabel(context, key);

                        return CheckboxListTile(
                          title: Text(label),
                          value: _enabledCardFields.contains(key),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _enabledCardFields.add(key);
                              } else {
                                _enabledCardFields.remove(key);
                              }
                            });
                            setDialogState(() {}); // Rebuild dialog
                            _saveEnabledCardFields();
                          },
                        );
                      },
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _enabledCardFields = _availableCardFieldKeys.toSet();
                        });
                        setDialogState(() {}); // Rebuild dialog
                        _saveEnabledCardFields();
                      },
                      child: Text(AppLocalizations.of(context)!.select_all),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _enabledCardFields.clear();
                        });
                        setDialogState(() {}); // Rebuild dialog
                        _saveEnabledCardFields();
                      },
                      child: Text(AppLocalizations.of(context)!.clear_all),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(AppLocalizations.of(context)!.close),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => PopScope(
            canPop: false,
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Indeterminate spinner (spinning animation)
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(message),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  Future<void> _createBackup(BuildContext context) async {
    try {
      // Show loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.creating_backup),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Get the database path
      final dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;
      final dbPath = db.path;

      // Create backup file name with timestamp
      final timestamp =
          DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final backupFileName = 'my_library_backup_$timestamp.db';

      // Let user pick a directory
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select folder to save backup',
      );

      if (selectedDirectory == null) {
        // User canceled
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.backup_canceled),
              backgroundColor: Colors.grey,
            ),
          );
        }
        return;
      }

      // Create the full path for the backup file
      final backupPath = '$selectedDirectory/$backupFileName';

      // Copy the database file
      await File(dbPath).copy(backupPath);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.backup_created_successfully(backupPath),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('Backup error: $e');

      // Check if it's a permission error
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('permission') ||
          errorStr.contains('denied') ||
          errorStr.contains('eacces')) {
        // Permission error - try to request again
        if (context.mounted) {
          final shouldRetry = await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: Text(
                    AppLocalizations.of(context)!.permission_required,
                  ),
                  content: Text(
                    AppLocalizations.of(context)!.storage_permission_needed,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(AppLocalizations.of(context)!.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        AppLocalizations.of(context)!.grant_permission,
                      ),
                    ),
                  ],
                ),
          );

          if (shouldRetry == true) {
            // Retry the backup operation
            if (!context.mounted) return;
            await _createBackup(context);
          }
        }
      } else {
        // Other error
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(
                  context,
                )!.error_creating_backup(e.toString()),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  Future<void> _importFromCsv(BuildContext context) async {
    try {
      // Pick CSV file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        dialogTitle: 'Select CSV file',
      );

      if (result == null || result.files.single.path == null) {
        return; // User canceled the picker
      }

      final filePath = result.files.single.path!;

      // Validate it's a CSV file
      if (!filePath.toLowerCase().endsWith('.csv')) {
        throw Exception('Please select a CSV file');
      }

      // Read file with proper encoding handling
      String input;
      try {
        input = File(filePath).readAsStringSync();
      } catch (e) {
        throw Exception('Failed to read CSV file: $e');
      }

      // Check if file is empty
      if (input.trim().isEmpty) {
        throw Exception('CSV file is empty');
      }

      // Parse CSV with better error handling
      List<List<dynamic>> rows;
      try {
        // Configure CSV parser to handle different line endings
        rows = const CsvToListConverter(
          eol: '\n',
          shouldParseNumbers: false,
        ).convert(input);

        // If we got only 1 row, try with different line ending
        if (rows.length == 1) {
          debugPrint('Only 1 row found, trying with \\r\\n line ending...');
          rows = const CsvToListConverter(
            eol: '\r\n',
            shouldParseNumbers: false,
          ).convert(input);
        }

        // If still only 1 row, try with \\r
        if (rows.length == 1) {
          debugPrint('Still 1 row, trying with \\r line ending...');
          rows = const CsvToListConverter(
            eol: '\r',
            shouldParseNumbers: false,
          ).convert(input);
        }
      } catch (e) {
        throw Exception(
          'Failed to parse CSV file. Please check the file format: $e',
        );
      }

      if (rows.isEmpty) {
        throw Exception('CSV file appears to be empty or invalid');
      }

      // Filter out completely empty rows (all cells are null or empty)
      final nonEmptyRows =
          rows.where((row) {
            if (row.isEmpty) return false;
            // Check if at least one cell has meaningful content
            return row.any((cell) {
              if (cell == null) return false;
              final str = cell.toString().trim();
              return str.isNotEmpty && str != '';
            });
          }).toList();

      if (nonEmptyRows.length < 2) {
        throw Exception(
          'CSV file must have at least a header row and one data row. Found ${nonEmptyRows.length} non-empty row(s). Please check your CSV file format.',
        );
      }

      // Use filtered rows for the rest of the import
      rows = nonEmptyRows;

      // Detect CSV format
      final headers = rows[0];
      final csvFormat = CsvImportHelper.detectCsvFormat(headers);

      if (csvFormat == CsvFormat.unknown) {
        throw Exception('Unknown CSV format. Please check the file structure.');
      }

      // For Format 1 (non-Goodreads), show status mapping dialog
      Map<String, String>? statusMappings;
      if (csvFormat == CsvFormat.format1) {
        if (context.mounted) {
          // Get predefined status values from database
          final db = await DatabaseHelper.instance.database;
          final statusList = await db.query('status', columns: ['value']);
          final predefinedStatuses =
              statusList.map((s) => s['value'] as String).toList();

          // Show mapping dialog
          if (!context.mounted) return;
          statusMappings = await showDialog<Map<String, String>>(
            context: context,
            barrierDismissible: false,
            builder:
                (context) =>
                    StatusMappingDialog(predefinedStatuses: predefinedStatuses),
          );

          // User canceled
          if (statusMappings == null) {
            return;
          }
        }
      }

      // Show loading indicator
      if (context.mounted) {
        _showLoadingDialog('Importing books from CSV...');
      }

      // Get database and repository (ensure it's open)
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);

      // Verify database is open
      if (!db.isOpen) {
        throw Exception('Database is not open. Please restart the app.');
      }

      // Log current database state
      final currentBooks = await repository.getAllBooks();
      final tbReleasedBooks =
          currentBooks
              .where((b) => b.statusValue?.toLowerCase() == 'tbreleased')
              .toList();
      debugPrint('=== Before Import ===');
      debugPrint('Total books in database: ${currentBooks.length}');
      debugPrint('TBReleased books: ${tbReleasedBooks.length}');
      for (var book in tbReleasedBooks) {
        debugPrint(
          '  - ${book.name ?? '(no title)'} by ${book.author} (${book.saga} #${book.nSaga})',
        );
      }

      // Parse all books first to show import choice dialog
      final List<_BookImportItem> importItems = [];
      final Set<String> allTags = {};
      debugPrint('=== Parsing CSV for Import Choice ===');
      debugPrint('Processing ${rows.length - 1} rows from CSV');

      // Create header map for efficient lookups
      final headerMap = <String, int>{};
      for (int j = 0; j < headers.length; j++) {
        headerMap[headers[j].toString().toLowerCase()] = j;
      }

      // Skip header row (index 0) and process data rows
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];

        // Skip empty rows
        if (row.isEmpty ||
            row.every(
              (cell) => cell == null || cell.toString().trim().isEmpty,
            )) {
          continue;
        }

        try {
          // Extract tags from bookshelves if available (for Goodreads format)
          List<String> bookTags = [];
          if (csvFormat == CsvFormat.format2 &&
              headerMap.containsKey('bookshelves')) {
            final bookshelvesIndex = headerMap['bookshelves'];
            if (bookshelvesIndex != null && bookshelvesIndex < row.length) {
              final bookshelves = row[bookshelvesIndex]?.toString();
              if (bookshelves != null && bookshelves.isNotEmpty) {
                bookTags =
                    bookshelves
                        .split(',')
                        .map((tag) => tag.trim())
                        .where((tag) => tag.isNotEmpty)
                        .toList();
                allTags.addAll(bookTags);
              }
            }
          }

          // Parse book from CSV based on format
          final book = CsvImportHelper.parseBookFromCsv(
            row,
            csvFormat,
            headers,
          );

          if (book == null) {
            continue;
          }

          // Map status value to existing database value
          String? mappedStatus;
          if (csvFormat == CsvFormat.format1 && statusMappings != null) {
            // Use user-provided mappings for Format 1
            final bookStatusLower = book.statusValue?.toLowerCase().trim();
            if (bookStatusLower != null &&
                statusMappings.containsKey(bookStatusLower)) {
              mappedStatus = statusMappings[bookStatusLower];
            } else {
              // If no mapping found, keep original value
              mappedStatus = book.statusValue;
            }
          } else {
            // For Format 2 (Goodreads), use automatic mapping
            final dbHelper = DatabaseHelper();
            mappedStatus = await CsvImportHelper.mapStatusValue(
              book.statusValue,
              dbHelper,
            );
          }

          // Create book with mapped status (preserve ALL parsed fields)
          final bookWithMappedStatus = Book(
            bookId: book.bookId,
            name: book.name,
            isbn: book.isbn,
            asin: book.asin,
            author: book.author,
            saga: book.saga,
            nSaga: book.nSaga,
            sagaUniverse: book.sagaUniverse,
            formatSagaValue: book.formatSagaValue,
            pages: book.pages,
            originalPublicationYear: book.originalPublicationYear,
            loaned: book.loaned,
            statusValue: mappedStatus,
            editorialValue: book.editorialValue,
            languageValue: book.languageValue,
            placeValue: book.placeValue,
            formatValue: book.formatValue,
            createdAt: book.createdAt,
            genre: book.genre,
            dateReadInitial: book.dateReadInitial,
            dateReadFinal: book.dateReadFinal,
            readCount: book.readCount,
            myRating: book.myRating,
            myReview: book.myReview,
            notes: book.notes,
            price: book.price,
            isBundle: book.isBundle,
            bundleCount: book.bundleCount,
            bundleNumbers: book.bundleNumbers,
            bundleStartDates: book.bundleStartDates,
            bundleEndDates: book.bundleEndDates,
            bundlePages: book.bundlePages,
            bundlePublicationYears: book.bundlePublicationYears,
            bundleTitles: book.bundleTitles,
            bundleAuthors: book.bundleAuthors,
            tbr: book.tbr,
            isTandem: book.isTandem,
            originalBookId: book.originalBookId,
            notificationEnabled: book.notificationEnabled,
            notificationDatetime: book.notificationDatetime,
            bundleParentId: book.bundleParentId,
            readingProgress: book.readingProgress,
            progressType: book.progressType,
            ratingOverride: book.ratingOverride,
            releaseDate: book.releaseDate,
            coverUrl: book.coverUrl,
            description: book.description,
            metadataSource: book.metadataSource,
            metadataFetchedAt: book.metadataFetchedAt,
          );

          // Check for duplicates
          final duplicateIds = await repository.findDuplicateBooks(
            bookWithMappedStatus,
          );

          String importType;
          Book? existingBook;
          if (duplicateIds.isEmpty) {
            importType = 'NEW';
          } else if (duplicateIds.length == 1) {
            importType = 'UPDATE';
            existingBook =
                bookWithMappedStatus; // Simplified for settings import
          } else {
            importType = 'DUPLICATE';
          }

          importItems.add(
            _BookImportItem(
              book: bookWithMappedStatus,
              importType: importType,
              duplicateIds: duplicateIds,
              existingBook: existingBook,
              tags: bookTags,
            ),
          );
        } catch (e) {
          debugPrint('Error parsing row $i: $e');
        }
      }

      debugPrint('=== Parse Complete ===');
      debugPrint('Total books parsed: ${importItems.length}');
      debugPrint('Available tags: ${allTags.length}');

      // Show import choice dialog
      Map<String, dynamic>? importChoice;
      if (context.mounted) {
        importChoice = await showDialog<Map<String, dynamic>>(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => _ImportChoiceDialog(
                availableTags: allTags.toList()..sort(),
                csvFormat:
                    csvFormat == CsvFormat.format1 ? 'Format 1' : 'Goodreads',
              ),
        );
      }

      if (importChoice == null) {
        // User canceled - close loading dialog
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        return;
      }

      // Filter books based on user choice
      List<_BookImportItem> selectedItems;
      if (importChoice['importFromTag'] == true) {
        final selectedTag = importChoice['selectedTag'] as String;
        selectedItems =
            importItems
                .where((item) => item.tags.contains(selectedTag))
                .toList();
        debugPrint('=== Importing from tag: $selectedTag ===');
        debugPrint('Books with tag: ${selectedItems.length}');
      } else {
        selectedItems = importItems;
        debugPrint('=== Importing All Books ===');
        debugPrint('Total books to import: ${selectedItems.length}');
      }

      // Now process the selected books
      int importedCount = 0;
      int skippedCount = 0;
      int updatedCount = 0;
      final List<String> skippedReasons = [];

      for (final item in selectedItems) {
        try {
          if (item.importType == 'NEW') {
            await repository.addBook(item.book);
            importedCount++;
          } else if (item.importType == 'UPDATE' &&
              item.duplicateIds.isNotEmpty) {
            // Update all existing books with the same ISBN
            for (final duplicateId in item.duplicateIds) {
              await repository.updateBookWithNewData(duplicateId, item.book);
              updatedCount++;
            }
          } else {
            skippedCount++;
            skippedReasons.add('Duplicate: ${item.book.name}');
          }
        } catch (e) {
          skippedCount++;
          skippedReasons.add('Error importing ${item.book.name}: $e');
          debugPrint('Error importing ${item.book.name}: $e');
        }
      }

      // Log summary
      debugPrint('=== CSV Import Summary ===');
      debugPrint('Total rows processed: ${rows.length - 1}');
      debugPrint('Imported: $importedCount');
      debugPrint('Updated: $updatedCount');
      debugPrint('Skipped: $skippedCount');
      if (skippedReasons.isNotEmpty) {
        debugPrint('Skipped reasons:');
        for (final reason in skippedReasons) {
          debugPrint('  - $reason');
        }
      }

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Reload the books in the provider
      if (context.mounted) {
        final provider = Provider.of<BookProvider?>(context, listen: false);
        await provider?.loadBooks();

        // Show results in modal dialog
        if (!context.mounted) return;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 28),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.import_completed_title),
                  ],
                ),
                content: Text(
                  'Imported: $importedCount books\nUpdated: $updatedCount books\nSkipped: $skippedCount rows',
                  style: const TextStyle(fontSize: 16),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.ok),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      debugPrint('CSV Import Error: $e');
      debugPrint('Stack trace: ${StackTrace.current}');

      // Close any open dialogs to prevent black screen
      if (context.mounted) {
        try {
          // Try to pop any dialogs that might be open
          Navigator.of(
            context,
            rootNavigator: true,
          ).popUntil((route) => route.isFirst);
        } catch (popError) {
          debugPrint('Error closing dialogs: $popError');
        }
      }

      // Wait a bit to ensure dialogs are closed
      await Future.delayed(const Duration(milliseconds: 100));

      // Show error dialog
      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                title: Text(AppLocalizations.of(context)!.import_error),
                content: SingleChildScrollView(
                  child: Text(
                    e.toString(),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.ok),
                  ),
                ],
              ),
        );
      }
    }
  }

  Future<void> _deleteAllData(BuildContext context) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.delete_all_data),
            content: Text(
              AppLocalizations.of(context)!.delete_all_data_confirmation,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(AppLocalizations.of(context)!.delete_all_data),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    // Show loading indicator
    if (context.mounted) {
      _showLoadingDialog('Deleting all books...');
    }

    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);

      // Get all books
      final allBooks = await repository.getAllBooks();

      // Delete each book (this will also delete related records)
      for (final book in allBooks) {
        if (book.bookId != null) {
          await repository.deleteBook(book.bookId!);
        }
      }

      // Reset auto-increment counters for all tables
      await db.execute("DELETE FROM sqlite_sequence WHERE name='book'");
      await db.execute("DELETE FROM sqlite_sequence WHERE name='author'");
      await db.execute("DELETE FROM sqlite_sequence WHERE name='genre'");
      await db.execute("DELETE FROM sqlite_sequence WHERE name='editorial'");
      await db.execute("DELETE FROM sqlite_sequence WHERE name='status'");
      await db.execute("DELETE FROM sqlite_sequence WHERE name='language'");
      await db.execute("DELETE FROM sqlite_sequence WHERE name='place'");
      await db.execute("DELETE FROM sqlite_sequence WHERE name='format'");
      await db.execute("DELETE FROM sqlite_sequence WHERE name='format_saga'");

      debugPrint('Reset all auto-increment IDs to 0');

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Reload books in provider
      if (context.mounted) {
        final provider = Provider.of<BookProvider?>(context, listen: false);
        await provider?.loadBooks();

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.deleted_books(allBooks.length),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Force an immediate backup so the empty DB is saved intentionally
      try {
        final user = GoogleAuthService.instance.currentUser;
        await BackupService.instance.performBackupNow(user?.uid);
        debugPrint('Forced backup after Delete Everything completed');
      } catch (backupError) {
        debugPrint('Error forcing backup after delete: $backupError');
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.error_deleting_data(e.toString()),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _migrateReadingSessions(BuildContext context) async {
    // Get statistics first
    final stats = await ReadingSessionMigration.getStats();

    if (!stats.needsMigration) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.no_sessions_to_migrate),
            backgroundColor: Colors.green,
          ),
        );
      }
      return;
    }

    // Show confirmation dialog
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.history, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(
                      context,
                    )!.migrate_reading_sessions_question,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This will migrate ${stats.oldStyleSessions} reading session${stats.oldStyleSessions == 1 ? '' : 's'} '
                  'from ${stats.bundlesWithOldSessions} bundle${stats.bundlesWithOldSessions == 1 ? '' : 's'} '
                  'to individual books.',
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context)!.what_will_happen,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  AppLocalizations.of(context)!.migration_description,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.migration_safe_info,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Text(AppLocalizations.of(context)!.migrate),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    // Show loading indicator
    if (context.mounted) {
      _showLoadingDialog(
        AppLocalizations.of(context)!.migrating_reading_sessions,
      );
    }

    try {
      final result = await ReadingSessionMigration.migrateAllReadingSessions();

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Show result dialog
      if (context.mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(
                  result.hasErrors
                      ? AppLocalizations.of(
                        context,
                      )!.migration_completed_with_errors
                      : AppLocalizations.of(context)!.migration_successful,
                  style: TextStyle(
                    color: result.hasErrors ? Colors.orange : Colors.green,
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(
                          context,
                        )!.successful_bundles(result.successfulBundles),
                      ),
                      Text(
                        AppLocalizations.of(
                          context,
                        )!.skipped_bundles(result.skippedBundles),
                      ),
                      Text(
                        AppLocalizations.of(
                          context,
                        )!.failed_bundles(result.failedBundles),
                      ),
                      Text(
                        AppLocalizations.of(context)!.total_sessions_migrated(
                          result.totalSessionsMigrated,
                        ),
                      ),
                      if (result.errors.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.errors_label,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ...result.errors.map(
                          (error) => Text(
                            '• $error',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.close),
                  ),
                ],
              ),
        );

        // Refresh the settings screen to update badges
        setState(() {});
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.error_migrating_reading_sessions(e.toString()),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _importBackup(BuildContext context) async {
    try {
      // Pick database backup file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        dialogTitle: AppLocalizations.of(context)!.select_backup_file,
      );

      if (result == null || result.files.single.path == null) {
        return; // User canceled
      }

      final backupPath = result.files.single.path!;

      // Show confirmation dialog
      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(AppLocalizations.of(context)!.import_backup),
              content: Text(
                AppLocalizations.of(context)!.import_backup_confirmation,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(AppLocalizations.of(context)!.replace_database),
                ),
              ],
            ),
      );

      if (confirmed != true) return;

      // Get current database path before closing
      final db = await DatabaseHelper.instance.database;
      final dbPath = db.path;

      // Close the database
      await DatabaseHelper.instance.closeDatabase();

      // Replace database file
      await File(backupPath).copy(dbPath);

      // Reinitialize database (this will open the new database)
      await DatabaseHelper.instance.database;

      // Reload books in provider
      if (context.mounted) {
        final provider = Provider.of<BookProvider?>(context, listen: false);
        await provider?.loadBooks();

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.database_restored_successfully,
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      debugPrint(
        AppLocalizations.of(context)!.import_backup_error(e.toString()),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.error_importing_backup(e.toString()),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _exportToCsv(BuildContext context) async {
    try {
      // Show loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.preparing_csv_export),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Get all books from the database
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);
      final allBooks = await repository.getAllBooks();

      if (allBooks.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.no_books_to_export),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Create CSV data
      List<List<dynamic>> csvData = [];

      // Add header row with ALL book fields (proper CSV format for re-import)
      csvData.add([
        'Title',
        'Author',
        'ISBN',
        'ASIN',
        'Saga',
        'N_Saga',
        'Saga Universe',
        'Format Saga',
        'Status',
        'Editorial',
        'Language',
        'Place',
        'Format',
        'Genre',
        'Pages',
        'Original Publication Year',
        'Loaned',
        'Date Read Initial',
        'Date Read Final',
        'Read Count',
        'My Rating',
        'My Review',
        'Is Bundle',
        'Bundle Count',
        'Bundle Numbers',
        'Bundle Start Dates',
        'Bundle End Dates',
        'Bundle Pages',
        'Bundle Publication Years',
        'Bundle Titles',
        'Bundle Authors',
        'TBR',
        'Is Tandem',
        'Original Book ID',
        'Notification Enabled',
        'Notification Datetime',
        'Bundle Parent ID',
        'Reading Progress',
        'Progress Type',
        'Notes',
        'Price',
        'Rating Override',
        'Release Date',
        'Cover URL',
        'Description',
        'Metadata Source',
        'Metadata Fetched At',
        'Created At',
      ]);

      // Add book data with ALL fields
      for (var book in allBooks) {
        csvData.add([
          book.name ?? '',
          book.author ?? '',
          book.isbn ?? '',
          book.asin ?? '',
          book.saga ?? '',
          book.nSaga ?? '',
          book.sagaUniverse ?? '',
          book.formatSagaValue ?? '',
          book.statusValue ?? '',
          book.editorialValue ?? '',
          book.languageValue ?? '',
          book.placeValue ?? '',
          book.formatValue ?? '',
          book.genre ?? '',
          book.pages?.toString() ?? '',
          book.originalPublicationYear?.toString() ?? '',
          book.loaned ?? '',
          book.dateReadInitial ?? '',
          book.dateReadFinal ?? '',
          book.readCount?.toString() ?? '',
          book.myRating?.toString() ?? '',
          book.myReview ?? '',
          book.isBundle == true ? 'yes' : 'no',
          book.bundleCount?.toString() ?? '',
          book.bundleNumbers ?? '',
          book.bundleStartDates ?? '',
          book.bundleEndDates ?? '',
          book.bundlePages ?? '',
          book.bundlePublicationYears ?? '',
          book.bundleTitles ?? '',
          book.bundleAuthors ?? '',
          book.tbr == true ? 'yes' : 'no',
          book.isTandem == true ? 'yes' : 'no',
          book.originalBookId?.toString() ?? '',
          book.notificationEnabled == true ? 'yes' : 'no',
          book.notificationDatetime ?? '',
          book.bundleParentId?.toString() ?? '',
          book.readingProgress?.toString() ?? '',
          book.progressType ?? '',
          book.notes ?? '',
          book.price?.toString() ?? '',
          book.ratingOverride == true ? 'yes' : 'no',
          book.releaseDate ?? '',
          book.coverUrl ?? '',
          book.description ?? '',
          book.metadataSource ?? '',
          book.metadataFetchedAt ?? '',
          book.createdAt ?? '',
        ]);
      }

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(csvData);

      // Create file name with timestamp
      final timestamp =
          DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileName = 'my_library_export_$timestamp.csv';

      // Let user pick a directory
      if (!context.mounted) return;
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: AppLocalizations.of(context)!.select_folder_save_csv,
      );

      if (selectedDirectory == null) {
        // User canceled
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.export_canceled),
              backgroundColor: Colors.grey,
            ),
          );
        }
        return;
      }

      // Create the full path for the CSV file
      final filePath = '$selectedDirectory/$fileName';

      // Write the CSV file
      await File(filePath).writeAsString(csv);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.exported_books(allBooks.length, filePath),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('Export error: $e');

      // Check if it's a permission error
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('permission') ||
          errorStr.contains('denied') ||
          errorStr.contains('eacces')) {
        // Permission error - try to request again
        if (context.mounted) {
          final shouldRetry = await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: Text(
                    AppLocalizations.of(context)!.permission_required,
                  ),
                  content: Text(
                    AppLocalizations.of(context)!.storage_permission_export,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(AppLocalizations.of(context)!.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        AppLocalizations.of(context)!.grant_permission,
                      ),
                    ),
                  ],
                ),
          );

          if (shouldRetry == true) {
            // Retry the export operation
            if (!context.mounted) return;
            await _exportToCsv(context);
          }
        }
      } else {
        // Other error
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.error_exporting_csv(e.toString()),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  Future<void> _exportToExcel(BuildContext context) async {
    try {
      // Show loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.preparing_csv_export),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Get all books from the database
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);
      final allBooks = await repository.getAllBooks();

      if (allBooks.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.no_books_to_export),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Create CSV data
      List<List<dynamic>> csvData = [];

      // Add header row with ALL book fields
      csvData.add([
        'Title',
        'Author',
        'ISBN',
        'ASIN',
        'Saga',
        'N_Saga',
        'Saga Universe',
        'Format Saga',
        'Status',
        'Editorial',
        'Language',
        'Place',
        'Format',
        'Genre',
        'Pages',
        'Original Publication Year',
        'Loaned',
        'Date Read Initial',
        'Date Read Final',
        'Read Count',
        'My Rating',
        'My Review',
        'Is Bundle',
        'Bundle Count',
        'Bundle Numbers',
        'Bundle Start Dates',
        'Bundle End Dates',
        'Bundle Pages',
        'Bundle Publication Years',
        'Bundle Titles',
        'Bundle Authors',
        'TBR',
        'Is Tandem',
        'Original Book ID',
        'Notification Enabled',
        'Notification Datetime',
        'Bundle Parent ID',
        'Reading Progress',
        'Progress Type',
        'Notes',
        'Price',
        'Rating Override',
        'Release Date',
        'Cover URL',
        'Description',
        'Metadata Source',
        'Metadata Fetched At',
        'Created At',
      ]);

      // Add book data with ALL fields
      for (var book in allBooks) {
        csvData.add([
          book.name ?? '',
          book.author ?? '',
          book.isbn ?? '',
          book.asin ?? '',
          book.saga ?? '',
          book.nSaga ?? '',
          book.sagaUniverse ?? '',
          book.formatSagaValue ?? '',
          book.statusValue ?? '',
          book.editorialValue ?? '',
          book.languageValue ?? '',
          book.placeValue ?? '',
          book.formatValue ?? '',
          book.genre ?? '',
          book.pages?.toString() ?? '',
          book.originalPublicationYear?.toString() ?? '',
          book.loaned ?? '',
          book.dateReadInitial ?? '',
          book.dateReadFinal ?? '',
          book.readCount?.toString() ?? '',
          book.myRating?.toString() ?? '',
          book.myReview ?? '',
          book.isBundle == true ? 'yes' : 'no',
          book.bundleCount?.toString() ?? '',
          book.bundleNumbers ?? '',
          book.bundleStartDates ?? '',
          book.bundleEndDates ?? '',
          book.bundlePages ?? '',
          book.bundlePublicationYears ?? '',
          book.bundleTitles ?? '',
          book.bundleAuthors ?? '',
          book.tbr == true ? 'yes' : 'no',
          book.isTandem == true ? 'yes' : 'no',
          book.originalBookId?.toString() ?? '',
          book.notificationEnabled == true ? 'yes' : 'no',
          book.notificationDatetime ?? '',
          book.bundleParentId?.toString() ?? '',
          book.readingProgress?.toString() ?? '',
          book.progressType ?? '',
          book.notes ?? '',
          book.price?.toString() ?? '',
          book.ratingOverride == true ? 'yes' : 'no',
          book.releaseDate ?? '',
          book.coverUrl ?? '',
          book.description ?? '',
          book.metadataSource ?? '',
          book.metadataFetchedAt ?? '',
          book.createdAt ?? '',
        ]);
      }

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(csvData);

      // Create file name with timestamp (Excel-compatible CSV)
      final timestamp =
          DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileName = 'my_library_export_excel_$timestamp.csv';

      // Let user pick a directory
      if (!context.mounted) return;
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: AppLocalizations.of(context)!.select_folder_save_excel_csv,
      );

      if (selectedDirectory == null) {
        // User canceled
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.export_canceled),
              backgroundColor: Colors.grey,
            ),
          );
        }
        return;
      }

      // Create the full path for the CSV file
      final filePath = '$selectedDirectory/$fileName';

      // Write the CSV file
      await File(filePath).writeAsString(csv);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.exported_books(allBooks.length, filePath),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('Export error: $e');

      // Check if it's a permission error
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('permission') ||
          errorStr.contains('denied') ||
          errorStr.contains('eacces')) {
        // Permission error - try to request again
        if (context.mounted) {
          final shouldRetry = await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: Text(
                    AppLocalizations.of(context)!.permission_required,
                  ),
                  content: Text(
                    AppLocalizations.of(context)!.storage_permission_export,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(AppLocalizations.of(context)!.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        AppLocalizations.of(context)!.grant_permission,
                      ),
                    ),
                  ],
                ),
          );

          if (shouldRetry == true) {
            // Retry the export operation
            if (!context.mounted) return;
            await _exportToExcel(context);
          }
        }
      } else {
        // Other error
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.error_exporting_csv(e.toString()),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  Widget _buildLightThemeGrid(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildThemePreview(
          context,
          AppLocalizations.of(context)!.warm_earth,
          [
            const Color(0xFFa36361),
            const Color(0xFFd3a29d),
            const Color(0xFFe8b298),
          ],
          themeProvider.lightThemeVariant == LightThemeVariant.warmEarth,
          () => themeProvider.setLightThemeVariant(LightThemeVariant.warmEarth),
        ),
        _buildThemePreview(
          context,
          AppLocalizations.of(context)!.vibrant_sunset,
          [
            const Color(0xFFef476f),
            const Color(0xFFf78c6b),
            const Color(0xFFffd166),
          ],
          themeProvider.lightThemeVariant == LightThemeVariant.vibrantSunset,
          () => themeProvider.setLightThemeVariant(
            LightThemeVariant.vibrantSunset,
          ),
        ),
        _buildThemePreview(
          context,
          AppLocalizations.of(context)!.soft_pastel,
          [
            const Color(0xFFc8a8e9),
            const Color(0xFFe3aadd),
            const Color(0xFFf5bcba),
          ],
          themeProvider.lightThemeVariant == LightThemeVariant.softPastel,
          () =>
              themeProvider.setLightThemeVariant(LightThemeVariant.softPastel),
        ),
        _buildThemePreview(
          context,
          AppLocalizations.of(context)!.deep_ocean,
          [
            const Color(0xFF14919b),
            const Color(0xFF0ad1c8),
            const Color(0xFF45dfb1),
          ],
          themeProvider.lightThemeVariant == LightThemeVariant.deepOcean,
          () => themeProvider.setLightThemeVariant(LightThemeVariant.deepOcean),
        ),
        _buildThemePreview(
          context,
          AppLocalizations.of(context)!.custom,
          [
            themeProvider.customLightPrimary,
            themeProvider.customLightSecondary,
            themeProvider.customLightTertiary,
          ],
          themeProvider.lightThemeVariant == LightThemeVariant.custom,
          () {
            themeProvider.setLightThemeVariant(LightThemeVariant.custom);
            _showCustomLightPaletteDialog(context, themeProvider);
          },
        ),
      ],
    );
  }

  Widget _buildDarkThemeGrid(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildThemePreview(
          context,
          AppLocalizations.of(context)!.mystic_purple,
          [
            const Color(0xFF854f6c),
            const Color(0xFF522b5b),
            const Color(0xFFdfb6b2),
          ],
          themeProvider.darkThemeVariant == DarkThemeVariant.mysticPurple,
          () =>
              themeProvider.setDarkThemeVariant(DarkThemeVariant.mysticPurple),
        ),
        _buildThemePreview(
          context,
          AppLocalizations.of(context)!.deep_sea,
          [
            const Color(0xFF0c7075),
            const Color(0xFF0f969c),
            const Color(0xFF6da5c0),
          ],
          themeProvider.darkThemeVariant == DarkThemeVariant.deepSea,
          () => themeProvider.setDarkThemeVariant(DarkThemeVariant.deepSea),
        ),
        _buildThemePreview(
          context,
          AppLocalizations.of(context)!.warm_autumn,
          [
            const Color(0xFF662549),
            const Color(0xFFae445a),
            const Color(0xFFf39f5a),
          ],
          themeProvider.darkThemeVariant == DarkThemeVariant.warmAutumn,
          () => themeProvider.setDarkThemeVariant(DarkThemeVariant.warmAutumn),
        ),
        _buildThemePreview(
          context,
          AppLocalizations.of(context)!.custom,
          [
            themeProvider.customDarkPrimary,
            themeProvider.customDarkSecondary,
            themeProvider.customDarkTertiary,
          ],
          themeProvider.darkThemeVariant == DarkThemeVariant.custom,
          () {
            themeProvider.setDarkThemeVariant(DarkThemeVariant.custom);
            _showCustomDarkPaletteDialog(context, themeProvider);
          },
        ),
      ],
    );
  }

  void _showCustomLightPaletteDialog(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              AppLocalizations.of(context)!.edit_custom_light_palette,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildColorPickerRow(
                    context,
                    AppLocalizations.of(context)!.primary,
                    themeProvider.customLightPrimary,
                    (color) async {
                      await themeProvider.setCustomLightColors(
                        color,
                        themeProvider.customLightSecondary,
                        themeProvider.customLightTertiary,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildColorPickerRow(
                    context,
                    AppLocalizations.of(context)!.secondary,
                    themeProvider.customLightSecondary,
                    (color) async {
                      await themeProvider.setCustomLightColors(
                        themeProvider.customLightPrimary,
                        color,
                        themeProvider.customLightTertiary,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildColorPickerRow(
                    context,
                    AppLocalizations.of(context)!.tertiary,
                    themeProvider.customLightTertiary,
                    (color) async {
                      await themeProvider.setCustomLightColors(
                        themeProvider.customLightPrimary,
                        themeProvider.customLightSecondary,
                        color,
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.close),
              ),
            ],
          ),
    );
  }

  void _showCustomDarkPaletteDialog(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.edit_custom_dark_palette),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildColorPickerRow(
                    context,
                    AppLocalizations.of(context)!.primary,
                    themeProvider.customDarkPrimary,
                    (color) async {
                      await themeProvider.setCustomDarkColors(
                        color,
                        themeProvider.customDarkSecondary,
                        themeProvider.customDarkTertiary,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildColorPickerRow(
                    context,
                    AppLocalizations.of(context)!.secondary,
                    themeProvider.customDarkSecondary,
                    (color) async {
                      await themeProvider.setCustomDarkColors(
                        themeProvider.customDarkPrimary,
                        color,
                        themeProvider.customDarkTertiary,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildColorPickerRow(
                    context,
                    AppLocalizations.of(context)!.tertiary,
                    themeProvider.customDarkTertiary,
                    (color) async {
                      await themeProvider.setCustomDarkColors(
                        themeProvider.customDarkPrimary,
                        themeProvider.customDarkSecondary,
                        color,
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.close),
              ),
            ],
          ),
    );
  }

  Widget _buildThemePreview(
    BuildContext context,
    String name,
    List<Color> colors,
    bool isSelected,
    VoidCallback onTap, {
    VoidCallback? onLongPress,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[300]!,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children:
                    colors.map((color) {
                      return Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius:
                                colors.indexOf(color) == 0
                                    ? const BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                    )
                                    : colors.indexOf(color) == colors.length - 1
                                    ? const BorderRadius.only(
                                      topRight: Radius.circular(10),
                                    )
                                    : null,
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                      size: 16,
                    ),
                  if (isSelected) const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color:
                            isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: 16),

            // ===== APPEARANCE SECTION (COLLAPSIBLE) =====
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ExpansionTile(
                title: Row(
                  children: [
                    Icon(
                      Icons.palette,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        AppLocalizations.of(context)!.appearance,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  AppLocalizations.of(context)!.appearance_subtitle,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                initiallyExpanded: false,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Theme selector
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Consumer<ThemeProvider>(
                              builder: (context, themeProvider, _) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.palette,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.theme_mode,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    RadioListTile<AppThemeMode>(
                                      title: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.theme_light,
                                      ),
                                      value: AppThemeMode.light,
                                      groupValue: themeProvider.themeMode,
                                      onChanged: (value) {
                                        if (value != null) {
                                          themeProvider.setThemeMode(value);
                                        }
                                      },
                                    ),
                                    RadioListTile<AppThemeMode>(
                                      title: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.theme_dark,
                                      ),
                                      value: AppThemeMode.dark,
                                      groupValue: themeProvider.themeMode,
                                      onChanged: (value) {
                                        if (value != null) {
                                          themeProvider.setThemeMode(value);
                                        }
                                      },
                                    ),
                                    RadioListTile<AppThemeMode>(
                                      title: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.theme_system,
                                      ),
                                      value: AppThemeMode.system,
                                      groupValue: themeProvider.themeMode,
                                      onChanged: (value) {
                                        if (value != null) {
                                          themeProvider.setThemeMode(value);
                                        }
                                      },
                                    ),
                                    const Divider(height: 32),

                                    // Light theme variants
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.light_theme_colors,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildLightThemeGrid(
                                      context,
                                      themeProvider,
                                    ),
                                    const SizedBox(height: 24),

                                    // Dark theme variants
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.dark_theme_colors,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildDarkThemeGrid(context, themeProvider),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Language selector
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.language,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      AppLocalizations.of(context)!.language,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Consumer<LocaleProvider>(
                                  builder: (context, localeProvider, _) {
                                    return DropdownButtonFormField<String>(
                                      value: localeProvider.locale.languageCode,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                      ),
                                      items: [
                                        DropdownMenuItem(
                                          value: 'en',
                                          child: Row(
                                            children: [
                                              Text('🇬🇧'),
                                              SizedBox(width: 12),
                                              Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!.english,
                                              ),
                                            ],
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'es',
                                          child: Row(
                                            children: [
                                              Text('🇪🇸'),
                                              SizedBox(width: 12),
                                              Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!.spanish,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          localeProvider.setLocale(
                                            Locale(value),
                                          );
                                        }
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ===== LIBRARY DISPLAY SECTION (COLLAPSIBLE) =====
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                title: Row(
                  children: [
                    Icon(
                      Icons.tune,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        AppLocalizations.of(context)!.library_display,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  AppLocalizations.of(context)!.library_display_subtitle,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                initiallyExpanded: false,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // TBR Limit Setting
                        const TBRLimitSetting(),
                        const SizedBox(height: 16),

                        // Home Filters Configuration
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () => _showFiltersDialog(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.filter_list,
                                    size: 36,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.customize_home_filters,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.customize_home_filters_subtitle,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Default Sort Order setting
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Consumer<BookProvider>(
                              builder: (context, provider, child) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.sort,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.default_sort_order,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.default_sort_order_subtitle,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Colors.grey[600]),
                                    ),
                                    const SizedBox(height: 16),
                                    DropdownButtonFormField<String>(
                                      value: provider.currentSortBy,
                                      decoration: InputDecoration(
                                        labelText:
                                            AppLocalizations.of(
                                              context,
                                            )!.sort_by,
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      items: [
                                        DropdownMenuItem(
                                          value: 'name',
                                          child: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.search_by_title,
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'author',
                                          child: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.author,
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'created_at',
                                          child: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.date_added,
                                          ),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          provider.setDefaultSortOrder(
                                            value,
                                            provider.currentSortAscending,
                                          );
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SegmentedButton<bool>(
                                            segments: [
                                              ButtonSegment(
                                                value: true,
                                                label: Text(
                                                  AppLocalizations.of(
                                                    context,
                                                  )!.ascending,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                icon: const Icon(
                                                  Icons.arrow_upward,
                                                  size: 14,
                                                ),
                                              ),
                                              ButtonSegment(
                                                value: false,
                                                label: Text(
                                                  AppLocalizations.of(
                                                    context,
                                                  )!.descending,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                icon: const Icon(
                                                  Icons.arrow_downward,
                                                  size: 14,
                                                ),
                                              ),
                                            ],
                                            selected: {
                                              provider.currentSortAscending,
                                            },
                                            onSelectionChanged: (
                                              Set<bool> newSelection,
                                            ) {
                                              provider.setDefaultSortOrder(
                                                provider.currentSortBy,
                                                newSelection.first,
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Card Fields Configuration
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () => _showCardFieldsDialog(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.view_agenda,
                                    size: 36,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.customize_card_fields,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.customize_card_fields_subtitle,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.fields_selected(
                                      _enabledCardFields.length,
                                    ),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ===== CLOUD SYNC SECTION (COLLAPSIBLE) =====
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                title: Row(
                  children: [
                    Icon(
                      Icons.cloud_sync,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        AppLocalizations.of(context)!.cloud_sync,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  AppLocalizations.of(context)!.cloud_sync_subtitle,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                initiallyExpanded: false,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Google Account Card
                        if (_currentUser == null) ...[
                          // Not signed in - show Sign In button
                          Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: _isCloudBusy ? null : _signInWithGoogle,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    if (_isCloudBusy)
                                      const CircularProgressIndicator()
                                    else
                                      Icon(
                                        Icons.login,
                                        size: 36,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                      ),
                                    const SizedBox(height: 12),
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.sign_in_with_google,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.sign_in_required,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          // Signed in - show user info
                          Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  if (_currentUser!.photoURL != null)
                                    CircleAvatar(
                                      backgroundImage: NetworkImage(
                                        _currentUser!.photoURL!,
                                      ),
                                      radius: 20,
                                    )
                                  else
                                    const CircleAvatar(
                                      radius: 20,
                                      child: Icon(Icons.person),
                                    ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _currentUser!.displayName ??
                                              _currentUser!.email ??
                                              '',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (_currentUser!.email != null)
                                          Text(
                                            _currentUser!.email!,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall?.copyWith(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _signOut,
                                    child: Text(
                                      AppLocalizations.of(context)!.sign_out,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Backup info row
                          if (_backupMetadata != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      AppLocalizations.of(context)!.last_backup(
                                        _formatTimestamp(
                                          _backupMetadata!['timestamp'],
                                        ),
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Colors.grey[600]),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: _loadBackupMetadata,
                                    child: Icon(
                                      Icons.refresh,
                                      size: 18,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Text(
                                AppLocalizations.of(context)!.no_cloud_backup,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                            ),

                          // Backup and Restore cloud buttons
                          Row(
                            children: [
                              Expanded(
                                child: Card(
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: InkWell(
                                    onTap: _isCloudBusy ? null : _uploadBackup,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.cloud_upload_outlined,
                                            size: 36,
                                            color:
                                                _isCloudBusy
                                                    ? Colors.grey
                                                    : Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.backup_to_cloud,
                                            textAlign: TextAlign.center,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.upload_your_library,
                                            textAlign: TextAlign.center,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall?.copyWith(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Card(
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: InkWell(
                                    onTap:
                                        _isCloudBusy ? null : _downloadBackup,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.cloud_download_outlined,
                                            size: 36,
                                            color:
                                                _isCloudBusy
                                                    ? Colors.grey
                                                    : Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.restore_from_cloud,
                                            textAlign: TextAlign.center,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.download_your_library,
                                            textAlign: TextAlign.center,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall?.copyWith(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Auto Backup frequency selector
                          const SizedBox(height: 12),
                          Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.auto_backup,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.auto_backup_subtitle,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 8),
                                  RadioListTile<BackupFrequency>(
                                    title: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.backup_frequency_off,
                                    ),
                                    value: BackupFrequency.off,
                                    groupValue: _autoBackupFrequency,
                                    onChanged:
                                        (v) => _setAutoBackupFrequency(v!),
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  RadioListTile<BackupFrequency>(
                                    title: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.backup_frequency_daily,
                                    ),
                                    value: BackupFrequency.daily,
                                    groupValue: _autoBackupFrequency,
                                    onChanged:
                                        (v) => _setAutoBackupFrequency(v!),
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  RadioListTile<BackupFrequency>(
                                    title: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.backup_frequency_weekly,
                                    ),
                                    value: BackupFrequency.weekly,
                                    groupValue: _autoBackupFrequency,
                                    onChanged:
                                        (v) => _setAutoBackupFrequency(v!),
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  RadioListTile<BackupFrequency>(
                                    title: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.backup_frequency_monthly,
                                    ),
                                    value: BackupFrequency.monthly,
                                    groupValue: _autoBackupFrequency,
                                    onChanged:
                                        (v) => _setAutoBackupFrequency(v!),
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  if (_autoBackupFrequency !=
                                          BackupFrequency.off &&
                                      _lastAutoBackupTimestamp != null) ...[
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.schedule,
                                          size: 14,
                                          color: Colors.grey[500],
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.last_backup(
                                              _formatTimestamp(
                                                _lastAutoBackupTimestamp,
                                              ),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall?.copyWith(
                                              color: Colors.grey[500],
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ===== IMPORT/EXPORT SECTION (COLLAPSIBLE) =====
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                title: Row(
                  children: [
                    Icon(
                      Icons.import_export,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        AppLocalizations.of(context)!.import_export,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  AppLocalizations.of(context)!.import_export_subtitle,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                initiallyExpanded: false,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Backup and Restore buttons
                        Row(
                          children: [
                            Expanded(
                              child: Card(
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: InkWell(
                                  onTap: () => _createBackup(context),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.backup_outlined,
                                          size: 36,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.create_database_backup,
                                          textAlign: TextAlign.center,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.save_a_copy_of_your_library_database,
                                          textAlign: TextAlign.center,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Card(
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: InkWell(
                                  onTap: () => _importBackup(context),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.cloud_download_outlined,
                                          size: 36,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.import_database_backup,
                                          textAlign: TextAlign.center,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.restore_a_copy_of_your_library_database,
                                          textAlign: TextAlign.center,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Import from CSV
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () => _importFromCsv(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.upload_file,
                                    size: 36,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.import_from_csv,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.import_from_csv_file,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 12),
                                  // Case 1: Custom CSV
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.blue[200]!,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.table_chart_outlined,
                                              color: Colors.blue[700],
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Case 1: Custom CSV',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall?.copyWith(
                                                color: Colors.blue[900],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.import_from_csv_hint,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.copyWith(
                                            color: Colors.blue[800],
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              color: Colors.blue[600],
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!.import_from_csv_tbreleased,
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall?.copyWith(
                                                  color: Colors.blue[700],
                                                  fontSize: 11,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Case 2: Goodreads CSV
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.green[200]!,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.menu_book_outlined,
                                              color: Colors.green[700],
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Case 2: Goodreads CSV',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall?.copyWith(
                                                color: Colors.green[900],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.goodreads_csv_hint,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.copyWith(
                                            color: Colors.green[800],
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Export buttons
                        Row(
                          children: [
                            Expanded(
                              child: Card(
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: InkWell(
                                  onTap: () => _exportToCsv(context),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.file_download,
                                          size: 36,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.export_to_csv,
                                          textAlign: TextAlign.center,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Card(
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: InkWell(
                                  onTap: () => _exportToExcel(context),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.table_chart,
                                          size: 36,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.export_to_excel,
                                          textAlign: TextAlign.center,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ===== READING REMINDERS SECTION (COLLAPSIBLE) =====
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                title: Row(
                  children: [
                    Icon(
                      Icons.notifications_active,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        AppLocalizations.of(context)!.reading_reminders,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  AppLocalizations.of(context)!.reading_reminders_subtitle,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                initiallyExpanded: false,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Enable/Disable toggle
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SwitchListTile(
                            title: Text(
                              AppLocalizations.of(
                                context,
                              )!.enable_reading_reminders,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              AppLocalizations.of(
                                context,
                              )!.enable_reading_reminders_subtitle,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                            value: _readingReminderEnabled,
                            onChanged: (value) {
                              setState(() {
                                _readingReminderEnabled = value;
                              });
                              _saveReadingReminderSettings();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      value
                                          ? AppLocalizations.of(
                                            context,
                                          )!.reading_reminder_enabled
                                          : AppLocalizations.of(
                                            context,
                                          )!.reading_reminder_disabled,
                                    ),
                                    backgroundColor:
                                        value ? Colors.green : Colors.orange,
                                  ),
                                );
                              }
                            },
                            secondary: Icon(
                              _readingReminderEnabled
                                  ? Icons.notifications_active
                                  : Icons.notifications_off,
                              color:
                                  _readingReminderEnabled
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Time picker (only shown when enabled)
                        if (_readingReminderEnabled) ...[
                          Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: Icon(
                                Icons.access_time,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              title: Text(
                                AppLocalizations.of(context)!.reminder_time,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                AppLocalizations.of(
                                  context,
                                )!.reminder_time_subtitle,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${_readingReminderHour.toString().padLeft(2, '0')}:${_readingReminderMinute.toString().padLeft(2, '0')}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay(
                                    hour: _readingReminderHour,
                                    minute: _readingReminderMinute,
                                  ),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _readingReminderHour = picked.hour;
                                    _readingReminderMinute = picked.minute;
                                  });
                                  _saveReadingReminderSettings();
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 12),

                          // All books vs last started option
                          Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.menu_book,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.reminder_books_option,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  RadioListTile<bool>(
                                    title: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.reminder_all_started,
                                    ),
                                    subtitle: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.reminder_all_started_subtitle,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Colors.grey[600]),
                                    ),
                                    value: true,
                                    groupValue: _readingReminderAllBooks,
                                    onChanged: (value) {
                                      setState(() {
                                        _readingReminderAllBooks =
                                            value ?? true;
                                      });
                                      _saveReadingReminderSettings();
                                    },
                                  ),
                                  RadioListTile<bool>(
                                    title: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.reminder_last_started,
                                    ),
                                    subtitle: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.reminder_last_started_subtitle,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Colors.grey[600]),
                                    ),
                                    value: false,
                                    groupValue: _readingReminderAllBooks,
                                    onChanged: (value) {
                                      setState(() {
                                        _readingReminderAllBooks =
                                            value ?? true;
                                      });
                                      _saveReadingReminderSettings();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ===== LIBRARY CUSTOMIZATION SECTION (COLLAPSIBLE) =====
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                title: Row(
                  children: [
                    Icon(
                      Icons.build_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        AppLocalizations.of(context)!.library_customization,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  AppLocalizations.of(context)!.library_customization_subtitle,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                initiallyExpanded: false,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Manage Rating Field Names
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          const ManageRatingFieldsScreen(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.star_rate,
                                    size: 36,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.manage_rating_field_names,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.manage_rating_field_names_subtitle,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Manage Club Names
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          const ManageClubNamesScreen(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.groups,
                                    size: 36,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.manage_club_names,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.manage_club_names_subtitle,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Manage Dropdown Values
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          const ManageDropdownsScreen(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.settings_outlined,
                                    size: 36,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.manage_dropdown_values,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.manage_dropdown_values_hint,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Price Statistics Toggle
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SwitchListTile(
                            title: Text(
                              AppLocalizations.of(
                                context,
                              )!.show_price_statistics,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              AppLocalizations.of(
                                context,
                              )!.show_price_statistics_subtitle,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                            value: _showPriceStatistics,
                            onChanged: (value) {
                              setState(() {
                                _showPriceStatistics = value;
                              });
                              _savePriceSettings();
                            },
                            secondary: Icon(
                              Icons.attach_money,
                              color:
                                  _showPriceStatistics
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Currency Symbol Picker
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: Icon(
                              Icons.currency_exchange,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: Text(
                              AppLocalizations.of(context)!.currency_setting,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              AppLocalizations.of(
                                context,
                              )!.currency_setting_subtitle,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _currencySymbol,
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            onTap: () {
                              _showCurrencyPicker();
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ===== LIBRARY TOOLS SECTION (COLLAPSIBLE) =====
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                title: Row(
                  children: [
                    Icon(
                      Icons.handyman_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        AppLocalizations.of(context)!.library_tools,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  AppLocalizations.of(context)!.library_tools_subtitle,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                initiallyExpanded: false,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Assign Books to Value (Reverse Assign)
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const ReverseAssignScreen(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.playlist_add,
                                    size: 36,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.assign_books_to_value,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.assign_books_to_value_hint,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Fill Empty Fields (Wizard)
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          const FillEmptyWizardScreen(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.auto_fix_high,
                                    size: 36,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.fill_empty_fields,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.fill_empty_fields_hint,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Smart Suggestions
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          const SmartSuggestionsScreen(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    size: 36,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.smart_suggestions,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.smart_suggestions_hint,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ===== MIGRATIONS SECTION (COLLAPSIBLE) =====
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                title: Row(
                  children: [
                    Icon(
                      Icons.sync_alt,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        AppLocalizations.of(context)!.migrations_section,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  AppLocalizations.of(context)!.migrations_section_subtitle,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                initiallyExpanded: false,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.sync_alt),
                                title: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.migrate_bundle_books_title,
                                ),
                                subtitle: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.migrate_bundle_books_subtitle,
                                ),
                                trailing: FutureBuilder<bool>(
                                  future: BundleMigration.isMigrationNeeded(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      );
                                    }

                                    if (snapshot.data == true) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.available,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    }

                                    return const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    );
                                  },
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              const BundleMigrationScreen(),
                                    ),
                                  );
                                },
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(
                                  Icons.history,
                                  color: Colors.blue,
                                ),
                                title: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.migrate_reading_sessions,
                                ),
                                subtitle: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.migrate_reading_sessions_subtitle,
                                ),
                                trailing: FutureBuilder<bool>(
                                  future:
                                      ReadingSessionMigration.needsMigration(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      );
                                    }

                                    if (snapshot.data == true) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.available,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    }

                                    return const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    );
                                  },
                                ),
                                onTap: () => _migrateReadingSessions(context),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ===== DANGER ZONE =====
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                onTap: () => _deleteAllData(context),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.delete_forever,
                        size: 36,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context)!.delete_all_data,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(
                          context,
                        )!.permanently_delete_all_books_from_the_database,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ===== ADMIN MODE (moved to bottom) =====
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: CheckboxListTile(
                title: Text(AppLocalizations.of(context)!.admin_mode),
                subtitle: Text(
                  AppLocalizations.of(context)!.admin_mode_subtitle,
                ),
                value: _isAdmin,
                onChanged: (value) async {
                  final newValue = value ?? false;
                  setState(() {
                    _isAdmin = newValue;
                  });
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('is_admin', newValue);
                },
                secondary: const Icon(Icons.admin_panel_settings),
              ),
            ),
            const SizedBox(height: 16),
            // Admin CSV Import
            if (_isAdmin) ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminCsvImportScreen(),
                      ),
                    );
                    // If books were imported, reload the provider
                    if (result == true && context.mounted) {
                      final provider = Provider.of<BookProvider?>(
                        context,
                        listen: false,
                      );
                      await provider?.loadBooks();
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          size: 36,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppLocalizations.of(context)!.admin_csv_import,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.admin_csv_import_subtitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ===== ABOUT =====
            AboutListTile(
              icon: const Icon(Icons.info_outline),
              applicationName: AppLocalizations.of(context)!.application_name,
              applicationVersion: '1.0.0',
              applicationIcon: const FlutterLogo(),
              applicationLegalese:
                  AppLocalizations.of(context)!.application_legalese,
              aboutBoxChildren: [
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.about_box_children,
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
            const SizedBox(height: 8), // Bottom margin
          ],
        ),
      ),
    );
  }

  Widget _buildColorPickerRow(
    BuildContext context,
    String label,
    Color color,
    Function(Color) onColorChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap:
                    () =>
                        _showColorPickerDialog(context, color, onColorChanged),
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '#${color.toARGB32().toRadixString(16).toUpperCase().padLeft(8, '0')}',
                      style: TextStyle(
                        color:
                            color.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showHexInputDialog(color, onColorChanged),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                ),
                child: Icon(Icons.palette, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showColorPickerDialog(
    BuildContext context,
    Color initialColor,
    Function(Color) onColorChanged,
  ) {
    Color selectedColor = initialColor;
    bool showHueSlider = false;
    double hue = HSVColor.fromColor(initialColor).hue;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text(AppLocalizations.of(context)!.pick_a_color),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Big square showing current color
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: selectedColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '#${selectedColor.toARGB32().toRadixString(16).toUpperCase().padLeft(8, '0')}',
                              style: TextStyle(
                                color:
                                    selectedColor.computeLuminance() > 0.5
                                        ? Colors.black
                                        : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // 7 quick color options + 1 hue picker
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: [
                            // 7 quick color options
                            _buildColorOption(
                              const Color(0xFFa36361),
                              selectedColor,
                              (color) {
                                setDialogState(() {
                                  selectedColor = color;
                                  showHueSlider = false;
                                });
                              },
                            ),
                            _buildColorOption(
                              const Color(0xFFef476f),
                              selectedColor,
                              (color) {
                                setDialogState(() {
                                  selectedColor = color;
                                  showHueSlider = false;
                                });
                              },
                            ),
                            _buildColorOption(
                              const Color(0xFFc8a8e9),
                              selectedColor,
                              (color) {
                                setDialogState(() {
                                  selectedColor = color;
                                  showHueSlider = false;
                                });
                              },
                            ),
                            _buildColorOption(
                              const Color(0xFF14919b),
                              selectedColor,
                              (color) {
                                setDialogState(() {
                                  selectedColor = color;
                                  showHueSlider = false;
                                });
                              },
                            ),
                            _buildColorOption(
                              const Color(0xFF854f6c),
                              selectedColor,
                              (color) {
                                setDialogState(() {
                                  selectedColor = color;
                                  showHueSlider = false;
                                });
                              },
                            ),
                            _buildColorOption(
                              const Color(0xFF0c7075),
                              selectedColor,
                              (color) {
                                setDialogState(() {
                                  selectedColor = color;
                                  showHueSlider = false;
                                });
                              },
                            ),
                            _buildColorOption(
                              const Color(0xFF662549),
                              selectedColor,
                              (color) {
                                setDialogState(() {
                                  selectedColor = color;
                                  showHueSlider = false;
                                });
                              },
                            ),
                            // 8th square: colorized palette icon for hue picker
                            GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  showHueSlider = !showHueSlider;
                                  hue = HSVColor.fromColor(selectedColor).hue;
                                });
                              },
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: selectedColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.palette,
                                  color:
                                      selectedColor.computeLuminance() > 0.5
                                          ? Colors.black54
                                          : Colors.white54,
                                  size: 32,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Hue slider (shown when palette icon is tapped)
                        if (showHueSlider) ...[
                          const SizedBox(height: 24),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.hue,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 30,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  gradient: LinearGradient(
                                    colors: [
                                      HSVColor.fromAHSV(1, 0, 1, 1).toColor(),
                                      HSVColor.fromAHSV(1, 60, 1, 1).toColor(),
                                      HSVColor.fromAHSV(1, 120, 1, 1).toColor(),
                                      HSVColor.fromAHSV(1, 180, 1, 1).toColor(),
                                      HSVColor.fromAHSV(1, 240, 1, 1).toColor(),
                                      HSVColor.fromAHSV(1, 300, 1, 1).toColor(),
                                      HSVColor.fromAHSV(1, 360, 1, 1).toColor(),
                                    ],
                                  ),
                                ),
                                child: Slider(
                                  value: hue,
                                  min: 0,
                                  max: 360,
                                  onChanged: (newHue) {
                                    setDialogState(() {
                                      hue = newHue;
                                      selectedColor =
                                          HSVColor.fromAHSV(
                                            1,
                                            hue,
                                            1,
                                            1,
                                          ).toColor();
                                    });
                                  },
                                ),
                              ),
                            ],
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
                        onColorChanged(selectedColor);
                        Navigator.pop(context);
                      },
                      child: Text(AppLocalizations.of(context)!.apply),
                    ),
                  ],
                ),
          ),
    );
  }

  Widget _buildColorOption(
    Color color,
    Color selectedColor,
    Function(Color) onTap,
  ) {
    final isSelected = color.toARGB32() == selectedColor.toARGB32();
    return GestureDetector(
      onTap: () => onTap(color),
      onLongPress: () => _showHexInputDialog(color, onTap),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[300]!,
            width: isSelected ? 3 : 1,
          ),
        ),
      ),
    );
  }

  void _showHexInputDialog(Color initialColor, Function(Color) onColorChanged) {
    Color selectedColor = initialColor;
    double hue = HSVColor.fromColor(initialColor).hue;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text(
                    AppLocalizations.of(context)!.pick_a_custom_color,
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 150,
                          height: 80,
                          decoration: BoxDecoration(
                            color: selectedColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '#${selectedColor.toARGB32().toRadixString(16).toUpperCase().padLeft(8, '0')}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.hue,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                gradient: LinearGradient(
                                  colors: [
                                    HSVColor.fromAHSV(1, 0, 1, 1).toColor(),
                                    HSVColor.fromAHSV(1, 60, 1, 1).toColor(),
                                    HSVColor.fromAHSV(1, 120, 1, 1).toColor(),
                                    HSVColor.fromAHSV(1, 180, 1, 1).toColor(),
                                    HSVColor.fromAHSV(1, 240, 1, 1).toColor(),
                                    HSVColor.fromAHSV(1, 300, 1, 1).toColor(),
                                    HSVColor.fromAHSV(1, 360, 1, 1).toColor(),
                                  ],
                                ),
                              ),
                              child: Slider(
                                value: hue,
                                min: 0,
                                max: 360,
                                onChanged: (newHue) {
                                  setDialogState(() {
                                    hue = newHue;
                                    selectedColor =
                                        HSVColor.fromAHSV(
                                          1,
                                          hue,
                                          1,
                                          1,
                                        ).toColor();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildColorOption(
                              const Color(0xFFa36361),
                              selectedColor,
                              (color) {
                                setDialogState(() {
                                  selectedColor = color;
                                });
                              },
                            ),
                            _buildColorOption(
                              const Color(0xFFef476f),
                              selectedColor,
                              (color) {
                                setDialogState(() {
                                  selectedColor = color;
                                });
                              },
                            ),
                            _buildColorOption(
                              const Color(0xFFc8a8e9),
                              selectedColor,
                              (color) {
                                setDialogState(() {
                                  selectedColor = color;
                                });
                              },
                            ),
                            _buildColorOption(
                              const Color(0xFF14919b),
                              selectedColor,
                              (color) {
                                setDialogState(() {
                                  selectedColor = color;
                                });
                              },
                            ),
                            _buildColorOption(
                              const Color(0xFF854f6c),
                              selectedColor,
                              (color) {
                                setDialogState(() {
                                  selectedColor = color;
                                });
                              },
                            ),
                            _buildColorOption(
                              const Color(0xFF0c7075),
                              selectedColor,
                              (color) {
                                setDialogState(() {
                                  selectedColor = color;
                                });
                              },
                            ),
                            _buildColorOption(
                              const Color(0xFF662549),
                              selectedColor,
                              (color) {
                                setDialogState(() {
                                  selectedColor = color;
                                });
                              },
                            ),
                          ],
                        ),
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
                        onColorChanged(selectedColor);
                        Navigator.pop(context);
                      },
                      child: Text(AppLocalizations.of(context)!.apply),
                    ),
                  ],
                ),
          ),
    );
  }
}

// Book import item class for import processing
class _BookImportItem {
  final Book book;
  final String importType; // 'NEW', 'UPDATE', 'DUPLICATE'
  final List<int> duplicateIds;
  final Book? existingBook;
  final List<String> tags;

  _BookImportItem({
    required this.book,
    required this.importType,
    required this.duplicateIds,
    this.existingBook,
    this.tags = const [],
  });
}

// Simple import choice dialog
class _ImportChoiceDialog extends StatefulWidget {
  final List<String> availableTags;
  final String csvFormat;

  const _ImportChoiceDialog({
    required this.availableTags,
    required this.csvFormat,
  });

  @override
  State<_ImportChoiceDialog> createState() => _ImportChoiceDialogState();
}

class _ImportChoiceDialogState extends State<_ImportChoiceDialog> {
  String? _selectedTag;
  bool _importFromTag = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.import_export, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.import_options(widget.csvFormat),
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RadioListTile<bool>(
              title: Text(AppLocalizations.of(context)!.import_all_books),
              value: false,
              groupValue: _importFromTag,
              onChanged: (value) {
                setState(() {
                  _importFromTag = value!;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            if (widget.availableTags.isNotEmpty) ...[
              RadioListTile<bool>(
                title: Text(AppLocalizations.of(context)!.import_from_tag),
                value: true,
                groupValue: _importFromTag,
                onChanged: (value) {
                  setState(() {
                    _importFromTag = value!;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              if (_importFromTag) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedTag,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.select_tag,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.tag),
                    isDense: true,
                  ),
                  isExpanded: true,
                  items:
                      widget.availableTags
                          .map(
                            (tag) => DropdownMenuItem(
                              value: tag,
                              child: Text(tag, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTag = value;
                    });
                  },
                ),
              ],
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
          onPressed:
              (_importFromTag && _selectedTag == null)
                  ? null
                  : () {
                    Navigator.pop(context, {
                      'importFromTag': _importFromTag,
                      'selectedTag': _selectedTag,
                    });
                  },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: Text(
            _importFromTag
                ? AppLocalizations.of(context)!.import_from_tag
                : AppLocalizations.of(context)!.import_all_books,
          ),
        ),
      ],
    );
  }
}

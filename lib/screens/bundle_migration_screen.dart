import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/utils/bundle_migration.dart';

class BundleMigrationScreen extends StatefulWidget {
  const BundleMigrationScreen({super.key});

  @override
  State<BundleMigrationScreen> createState() => _BundleMigrationScreenState();
}

class _BundleMigrationScreenState extends State<BundleMigrationScreen> {
  MigrationStats? _stats;
  MigrationResult? _result;
  bool _isLoading = true;
  bool _isMigrating = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    final stats = await BundleMigration.getMigrationStats();

    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  Future<void> _runMigration() async {
    // Confirm with user
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.migrate_bundle_books),
            content: Text(
              'This will convert ${_stats?.oldStyleBundles ?? 0} old-style bundles to the new system.\n\n'
              'Individual book records will be created for each book in the bundle.\n\n'
              'This operation cannot be undone. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(AppLocalizations.of(context)!.migrate),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    setState(() => _isMigrating = true);

    try {
      final result = await BundleMigration.migrateAllBundles();

      setState(() {
        _result = result;
        _isMigrating = false;
      });

      // Reload stats
      await _loadStats();

      // Show result dialog
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(
                  result.hasErrors
                      ? AppLocalizations.of(context)!.migration_completed_errors
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
                      Text('✅ Successful: ${result.successfulMigrations}'),
                      Text('⏭️  Skipped: ${result.skippedMigrations}'),
                      Text('❌ Failed: ${result.failedMigrations}'),
                      Text(
                        '📚 Individual books created: ${result.individualBooksCreated}',
                      ),
                      if (result.errors.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Errors:',
                          style: TextStyle(fontWeight: FontWeight.bold),
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
      }
    } catch (e) {
      setState(() => _isMigrating = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Migration failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.bundle_migration),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.about_bundle_migration,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'This tool migrates old-style bundles (stored as JSON arrays) '
                              'to the new system where each book in a bundle is a separate database record.\n\n'
                              'Benefits:\n'
                              '• Individual status tracking for each book\n'
                              '• Better search and organization\n'
                              '• Easier to edit individual books\n'
                              '• Cleaner data structure',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Statistics Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.current_status,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildStatRow(
                              AppLocalizations.of(context)!.old_style_bundles,
                              _stats?.oldStyleBundles ?? 0,
                              Colors.orange,
                              Icons.folder_outlined,
                            ),
                            _buildStatRow(
                              AppLocalizations.of(context)!.new_style_bundles,
                              _stats?.newStyleBundles ?? 0,
                              Colors.green,
                              Icons.folder_special,
                            ),
                            _buildStatRow(
                              AppLocalizations.of(
                                context,
                              )!.individual_bundle_books,
                              _stats?.individualBundleBooks ?? 0,
                              Colors.blue,
                              Icons.menu_book,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Migration Button
                    if (_stats != null && _stats!.needsMigration) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isMigrating ? null : _runMigration,
                          icon:
                              _isMigrating
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : const Icon(Icons.sync),
                          label: Text(
                            _isMigrating
                                ? AppLocalizations.of(context)!.migrating
                                : AppLocalizations.of(
                                  context,
                                )!.migrate_n_bundles(
                                  _stats!.oldStyleBundles.toString(),
                                ),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '⚠️ This operation cannot be undone',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ] else ...[
                      Card(
                        color: Colors.green[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green[700],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.no_migration_needed,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Last Result
                    if (_result != null) ...[
                      const SizedBox(height: 24),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.last_migration_result,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text('Total bundles: ${_result!.totalBundles}'),
                              Text(
                                '✅ Successful: ${_result!.successfulMigrations}',
                              ),
                              Text(
                                '⏭️  Skipped: ${_result!.skippedMigrations}',
                              ),
                              Text('❌ Failed: ${_result!.failedMigrations}'),
                              Text(
                                '📚 Individual books created: ${_result!.individualBooksCreated}',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
    );
  }

  Widget _buildStatRow(String label, int value, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value.toString(),
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
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
            title: const Text('Migrate Bundle Books?'),
            content: Text(
              'This will convert ${_stats?.oldStyleBundles ?? 0} old-style bundles to the new system.\n\n'
              'Individual book records will be created for each book in the bundle.\n\n'
              'This operation cannot be undone. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Migrate'),
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
                      ? 'Migration Completed with Errors'
                      : 'Migration Successful!',
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
                    child: const Text('Close'),
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
      appBar: AppBar(title: const Text('Bundle Migration')),
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
                                const Text(
                                  'About Bundle Migration',
                                  style: TextStyle(
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
                            const Text(
                              'Current Status',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildStatRow(
                              'Old-style bundles',
                              _stats?.oldStyleBundles ?? 0,
                              Colors.orange,
                              Icons.folder_outlined,
                            ),
                            _buildStatRow(
                              'New-style bundles',
                              _stats?.newStyleBundles ?? 0,
                              Colors.green,
                              Icons.folder_special,
                            ),
                            _buildStatRow(
                              'Individual bundle books',
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
                                ? 'Migrating...'
                                : 'Migrate ${_stats!.oldStyleBundles} Bundle${_stats!.oldStyleBundles == 1 ? '' : 's'}',
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
                              const Expanded(
                                child: Text(
                                  'All bundles are using the new system!\nNo migration needed.',
                                  style: TextStyle(fontWeight: FontWeight.w500),
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
                              const Text(
                                'Last Migration Result',
                                style: TextStyle(
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
              color: color.withOpacity(0.1),
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

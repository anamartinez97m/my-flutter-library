import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/model/year_challenge.dart';
import 'package:myrandomlibrary/model/custom_challenge.dart';
import 'package:myrandomlibrary/repositories/year_challenge_repository.dart';

class YearChallengesScreen extends StatefulWidget {
  const YearChallengesScreen({super.key});

  @override
  State<YearChallengesScreen> createState() => _YearChallengesScreenState();
}

class _YearChallengesScreenState extends State<YearChallengesScreen> {
  List<YearChallenge> _challenges = [];
  Map<int, Map<String, dynamic>> _progressData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChallenges();
  }

  Future<void> _loadChallenges() async {
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseHelper.instance.database;
      final repository = YearChallengeRepository(db);
      final challenges = await repository.getAllChallenges();

      // Load progress for each challenge
      final Map<int, Map<String, dynamic>> progressData = {};
      for (var challenge in challenges) {
        final progress = await repository.getChallengeProgress(challenge.year);
        progressData[challenge.year] = progress;
      }

      // Sort challenges: current year first, then descending by year
      final currentYear = DateTime.now().year;
      challenges.sort((a, b) {
        if (a.year == currentYear) return -1;
        if (b.year == currentYear) return 1;
        return b.year.compareTo(a.year);
      });

      setState(() {
        _challenges = challenges;
        _progressData = progressData;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading challenges: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddChallengeDialog() async {
    final currentYear = DateTime.now().year;
    final yearController = TextEditingController(text: currentYear.toString());
    final booksController = TextEditingController();
    final pagesController = TextEditingController();
    final notesController = TextEditingController();

    // Custom challenges state
    final List<Map<String, TextEditingController>> customChallenges = [];

    final result = await showDialog<YearChallenge>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('New Year Challenge'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: yearController,
                          decoration: const InputDecoration(
                            labelText: 'Year',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: booksController,
                          decoration: const InputDecoration(
                            labelText: 'Target Books *',
                            border: OutlineInputBorder(),
                            hintText: 'e.g., 50',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: pagesController,
                          decoration: const InputDecoration(
                            labelText: 'Target Pages (optional)',
                            border: OutlineInputBorder(),
                            hintText: 'e.g., 10000',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: notesController,
                          decoration: const InputDecoration(
                            labelText: 'Notes (optional)',
                            border: OutlineInputBorder(),
                            hintText: 'Any notes about this challenge',
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Custom Challenges',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle),
                              onPressed: null,
                            ),
                          ],
                        ),
                        const Text(
                          'Add custom reading goals (e.g., "Read 5 classics", "Finish 3 series")',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        if (customChallenges.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          ...customChallenges.asMap().entries.map((entry) {
                            final index = entry.key;
                            final challenge = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    // Goal name row
                                    TextField(
                                      controller: challenge['name'],
                                      decoration: const InputDecoration(
                                        labelText: 'Goal name',
                                        hintText: 'e.g., Read 5 classics',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // Target row
                                    TextField(
                                      controller: challenge['target'],
                                      decoration: const InputDecoration(
                                        labelText: 'Target',
                                        hintText: 'e.g., 5',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Unit row
                                    TextField(
                                      controller: challenge['unit'],
                                      decoration: const InputDecoration(
                                        labelText: 'Unit',
                                        hintText:
                                            'e.g., books, chapters, pages',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // Delete button row
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setDialogState(() {
                                            customChallenges.removeAt(index);
                                          });
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
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
                        final year =
                            int.tryParse(yearController.text) ?? currentYear;
                        final targetBooks = int.tryParse(booksController.text);
                        final hasCustomChallenges = customChallenges.any(
                          (c) =>
                              c['name']!.text.isNotEmpty &&
                              c['target']!.text.isNotEmpty,
                        );

                        // Target books is required only if no custom challenges are added
                        if (!hasCustomChallenges &&
                            (targetBooks == null || targetBooks <= 0)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please enter valid target books or add custom challenges',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // Build custom challenges list
                        final customChallengesList =
                            customChallenges
                                .where(
                                  (c) =>
                                      c['name']!.text.isNotEmpty &&
                                      c['target']!.text.isNotEmpty,
                                )
                                .map((c) {
                                  return CustomChallenge(
                                    name: c['name']!.text,
                                    unit: c['unit']!.text,
                                    target:
                                        int.tryParse(c['target']!.text) ?? 0,
                                  );
                                })
                                .toList();

                        final challenge = YearChallenge(
                          year: year,
                          targetBooks: targetBooks ?? 0,
                          targetPages: int.tryParse(pagesController.text),
                          notes:
                              notesController.text.isEmpty
                                  ? null
                                  : notesController.text,
                          customChallenges:
                              customChallengesList.isNotEmpty
                                  ? customChallengesList
                                  : null,
                        );

                        Navigator.pop(context, challenge);
                      },
                      child: const Text('Create'),
                    ),
                  ],
                ),
          ),
    );

    if (result != null) {
      try {
        final db = await DatabaseHelper.instance.database;
        final repository = YearChallengeRepository(db);
        await repository.createChallenge(result);
        _loadChallenges();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Challenge created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating challenge: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showEditChallengeDialog(YearChallenge challenge) async {
    final booksController = TextEditingController(
      text: challenge.targetBooks.toString(),
    );
    final pagesController = TextEditingController(
      text: challenge.targetPages?.toString() ?? '',
    );
    final notesController = TextEditingController(text: challenge.notes ?? '');

    final result = await showDialog<YearChallenge>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Edit ${challenge.year} Challenge'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: booksController,
                    decoration: const InputDecoration(
                      labelText: 'Target Books *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pagesController,
                    decoration: const InputDecoration(
                      labelText: 'Target Pages (optional)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
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
                  final targetBooks = int.tryParse(booksController.text);

                  if (targetBooks == null || targetBooks <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter valid target books'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final updated = challenge.copyWith(
                    targetBooks: targetBooks,
                    targetPages: int.tryParse(pagesController.text),
                    notes:
                        notesController.text.isEmpty
                            ? null
                            : notesController.text,
                  );

                  Navigator.pop(context, updated);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );

    if (result != null) {
      try {
        final db = await DatabaseHelper.instance.database;
        final repository = YearChallengeRepository(db);
        await repository.updateChallenge(result);
        _loadChallenges();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Challenge updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating challenge: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteChallenge(YearChallenge challenge) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Challenge'),
            content: Text(
              'Are you sure you want to delete the ${challenge.year} challenge?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        final db = await DatabaseHelper.instance.database;
        final repository = YearChallengeRepository(db);
        await repository.deleteChallenge(challenge.challengeId!);
        _loadChallenges();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Challenge deleted'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting challenge: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildChallengeCard(YearChallenge challenge) {
    final progress = _progressData[challenge.year];
    final booksRead = progress?['booksRead'] ?? 0;
    final pagesRead = progress?['pagesRead'] ?? 0;
    final booksProgress = progress?['booksProgress'] ?? 0.0;
    final pagesProgress = progress?['pagesProgress'] ?? 0.0;

    final isCurrentYear = challenge.year == DateTime.now().year;
    final isPastYear = challenge.year < DateTime.now().year;
    final booksComplete = booksRead >= challenge.targetBooks;
    final pagesComplete =
        challenge.targetPages != null && pagesRead >= challenge.targetPages!;
    final isFinished =
        booksComplete && (challenge.targetPages == null || pagesComplete);

    return Card(
      elevation: isCurrentYear ? 4 : 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color:
          isFinished || (isPastYear && !isFinished)
              ? Colors.grey.shade200
              : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:
            isCurrentYear
                ? BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
                : isFinished
                ? BorderSide(color: Colors.green.withOpacity(0.3), width: 2)
                : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showEditChallengeDialog(challenge),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        challenge.year.toString(),
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      if (isCurrentYear) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Current',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteChallenge(challenge),
                    color: Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Books progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Books:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '$booksRead / ${challenge.targetBooks}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: booksComplete ? Colors.green : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: booksProgress.clamp(0.0, 1.0),
                  minHeight: 12,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    booksComplete
                        ? Colors.green
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),

              if (challenge.targetPages != null) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pages:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '$pagesRead / ${challenge.targetPages}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: pagesComplete ? Colors.green : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: pagesProgress.clamp(0.0, 1.0),
                    minHeight: 12,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      pagesComplete ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],

              if (challenge.customChallenges != null &&
                  challenge.customChallenges!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Custom Challenges',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...challenge.customChallenges!.map((customChallenge) {
                  final isComplete =
                      customChallenge.current >= customChallenge.target;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            isComplete
                                ? Colors.green.withOpacity(0.1)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              isComplete
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Challenge name row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  customChallenge.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isComplete ? Colors.green : null,
                                  ),
                                ),
                              ),
                              if (isComplete)
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 18,
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Progress bar row
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value:
                                  customChallenge.target > 0
                                      ? (customChallenge.current /
                                              customChallenge.target)
                                          .clamp(0.0, 1.0)
                                      : 0.0,
                              minHeight: 8,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isComplete
                                    ? Colors.green
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Progress text row
                          Text(
                            '${customChallenge.current} / ${customChallenge.target} ${customChallenge.unit}',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color:
                                  isComplete ? Colors.green : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],

              if (challenge.notes != null && challenge.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    challenge.notes!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Year Challenges')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _challenges.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No challenges yet',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first reading challenge!',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ).copyWith(bottom: 56),
                itemCount: _challenges.length,
                itemBuilder: (context, index) {
                  return _buildChallengeCard(_challenges[index]);
                },
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddChallengeDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Challenge'),
      ),
    );
  }
}

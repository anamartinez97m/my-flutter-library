import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/repositories/year_challenge_repository.dart';
import 'package:myrandomlibrary/screens/year_challenges.dart';

/// Card showing current year's reading goals progress
class ReadingGoalsCard extends StatefulWidget {
  const ReadingGoalsCard({super.key});

  @override
  State<ReadingGoalsCard> createState() => _ReadingGoalsCardState();
}

class _ReadingGoalsCardState extends State<ReadingGoalsCard> {
  Map<String, dynamic>? _currentYearProgress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentYearProgress();
  }

  Future<void> _loadCurrentYearProgress() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final repository = YearChallengeRepository(db);
      final currentYear = DateTime.now().year;
      
      // Try to get current year's challenge
      final challenges = await repository.getAllChallenges();
      final currentChallenge = challenges.where((c) => c.year == currentYear).firstOrNull;
      
      if (currentChallenge != null) {
        final progress = await repository.getChallengeProgress(currentYear);
        setState(() {
          _currentYearProgress = progress;
          _isLoading = false;
        });
      } else {
        setState(() {
          _currentYearProgress = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading current year progress: $e');
      setState(() {
        _currentYearProgress = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(20.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_currentYearProgress == null) {
      // Show placeholder if no challenge for current year
      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const YearChallengesScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.green.withOpacity(0.1),
                  Colors.teal.withOpacity(0.1),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Icon(
                    Icons.flag,
                    size: 48,
                    color: Colors.green.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Reading Goals Progress',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No challenge set for ${DateTime.now().year}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const YearChallengesScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Challenge'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Show current year progress
    final booksRead = _currentYearProgress!['booksRead'] ?? 0;
    final targetBooks = _currentYearProgress!['targetBooks'] ?? 0;
    final pagesRead = _currentYearProgress!['pagesRead'] ?? 0;
    final targetPages = _currentYearProgress!['targetPages'];
    final booksProgress = _currentYearProgress!['booksProgress'] ?? 0.0;
    final pagesProgress = _currentYearProgress!['pagesProgress'] ?? 0.0;
    
    final booksComplete = booksRead >= targetBooks;
    final pagesComplete = targetPages != null && pagesRead >= targetPages;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const YearChallengesScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.flag,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${DateTime.now().year} Reading Goals',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Books progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Books:', style: TextStyle(fontWeight: FontWeight.w500)),
                  Text(
                    '$booksRead / $targetBooks',
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
                    booksComplete ? Colors.green : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              
              if (targetPages != null) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Pages:', style: TextStyle(fontWeight: FontWeight.w500)),
                    Text(
                      '$pagesRead / $targetPages',
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
            ],
          ),
        ),
      ),
    );
  }
}

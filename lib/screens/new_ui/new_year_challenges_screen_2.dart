import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/custom_challenge.dart';
import 'package:myrandomlibrary/model/year_challenge.dart';
import 'package:myrandomlibrary/repositories/year_challenge_repository.dart';

// ── v2 design tokens ─────────────────────────────────────────────────────────
const _kBg = Color(0xFFFDF8F6);
const _kPrimary = Color(0xFF5D2641);
const _kPrimarySoft = Color(0xFFF9F1F4);
const _kText = Color(0xFF1C1B1A);
const _kSub = Color(0xFF76666D);
const _kBorder = Color(0xFFE8DED8);
const _kTrack = Color(0xFFEDE6E1);
const _kSuccess = Color(0xFF059669);
const _kSuccessBg = Color(0xFFECFDF5);
const _kSuccessBorder = Color(0xFFA7F3D0);

class NewYearChallengesScreen2 extends StatefulWidget {
  const NewYearChallengesScreen2({super.key});

  @override
  State<NewYearChallengesScreen2> createState() =>
      _NewYearChallengesScreen2State();
}

class _NewYearChallengesScreen2State extends State<NewYearChallengesScreen2> {
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

      final Map<int, Map<String, dynamic>> progressData = {};
      for (var challenge in challenges) {
        final progress = await repository.getChallengeProgress(challenge.year);
        progressData[challenge.year] = progress;
      }

      final currentYear = DateTime.now().year;
      challenges.sort((a, b) {
        if (a.year == currentYear) return -1;
        if (b.year == currentYear) return 1;
        return b.year.compareTo(a.year);
      });

      if (mounted) {
        setState(() {
          _challenges = challenges;
          _progressData = progressData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading challenges: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  YearChallenge? get _currentYearChallenge {
    final currentYear = DateTime.now().year;
    try {
      return _challenges.firstWhere((c) => c.year == currentYear);
    } catch (_) {
      return null;
    }
  }

  List<YearChallenge> get _previousChallenges {
    final currentYear = DateTime.now().year;
    return _challenges.where((c) => c.year != currentYear).toList();
  }

  Future<void> _showAddChallengeDialog() async {
    final currentYear = DateTime.now().year;
    final yearController = TextEditingController(text: currentYear.toString());
    final booksController = TextEditingController();
    final pagesController = TextEditingController();
    final notesController = TextEditingController();
    final List<Map<String, TextEditingController>> customChallenges = [];

    final result = await showDialog<YearChallenge>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text(AppLocalizations.of(context)!.new_year_challenge),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: yearController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.year_label,
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: booksController,
                          decoration: InputDecoration(
                            labelText:
                                '${AppLocalizations.of(context)!.target_books} *',
                            border: const OutlineInputBorder(),
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
                          decoration: InputDecoration(
                            labelText:
                                '${AppLocalizations.of(context)!.target_pages} (${AppLocalizations.of(context)!.optional})',
                            border: const OutlineInputBorder(),
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
                          decoration: InputDecoration(
                            labelText:
                                '${AppLocalizations.of(context)!.notes} (${AppLocalizations.of(context)!.optional})',
                            border: const OutlineInputBorder(),
                            hintText:
                                AppLocalizations.of(
                                  context,
                                )!.any_notes_about_challenge,
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
                              AppLocalizations.of(context)!.custom_challenges,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle),
                              onPressed: () {
                                setDialogState(() {
                                  customChallenges.add({
                                    'name': TextEditingController(),
                                    'target': TextEditingController(),
                                    'unit': TextEditingController(),
                                  });
                                });
                              },
                            ),
                          ],
                        ),
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.add_custom_reading_goals,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
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
                                  border: Border.all(
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.outlineVariant,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    TextField(
                                      controller: challenge['name'],
                                      decoration: InputDecoration(
                                        labelText:
                                            AppLocalizations.of(
                                              context,
                                            )!.goal_name,
                                        hintText:
                                            AppLocalizations.of(
                                              context,
                                            )!.goal_name_hint,
                                        border: const OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: challenge['target'],
                                      decoration: InputDecoration(
                                        labelText:
                                            AppLocalizations.of(
                                              context,
                                            )!.target,
                                        hintText: 'e.g., 5',
                                        border: const OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: challenge['unit'],
                                      decoration: InputDecoration(
                                        labelText:
                                            AppLocalizations.of(context)!.unit,
                                        hintText:
                                            AppLocalizations.of(
                                              context,
                                            )!.unit_hint,
                                        border: const OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
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
                      child: Text(AppLocalizations.of(context)!.cancel),
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
                        if (!hasCustomChallenges &&
                            (targetBooks == null || targetBooks <= 0)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(
                                  context,
                                )!.enter_valid_target_books,
                              ),
                              backgroundColor:
                                  Theme.of(context).colorScheme.error,
                            ),
                          );
                          return;
                        }
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
                          targetBooks: targetBooks,
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
                      child: Text(AppLocalizations.of(context)!.create),
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
            SnackBar(
              content: Text(AppLocalizations.of(context)!.challenge_created),
              backgroundColor: _kPrimary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppLocalizations.of(context)!.error}: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _showEditChallengeDialog(YearChallenge challenge) async {
    final booksController = TextEditingController(
      text: challenge.targetBooks?.toString() ?? '',
    );
    final pagesController = TextEditingController(
      text: challenge.targetPages?.toString() ?? '',
    );
    final notesController = TextEditingController(text: challenge.notes ?? '');

    final result = await showDialog<YearChallenge>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              AppLocalizations.of(
                context,
              )!.edit_year_challenge(challenge.year.toString()),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: booksController,
                    decoration: InputDecoration(
                      labelText:
                          '${AppLocalizations.of(context)!.target_books} *',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pagesController,
                    decoration: InputDecoration(
                      labelText:
                          '${AppLocalizations.of(context)!.target_pages} (${AppLocalizations.of(context)!.optional})',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notesController,
                    decoration: InputDecoration(
                      labelText:
                          '${AppLocalizations.of(context)!.notes} (${AppLocalizations.of(context)!.optional})',
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 3,
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
                  final targetBooks = int.tryParse(booksController.text);
                  if (targetBooks == null || targetBooks <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(
                            context,
                          )!.enter_valid_target_books,
                        ),
                        backgroundColor: Theme.of(context).colorScheme.error,
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
                child: Text(AppLocalizations.of(context)!.save),
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
            SnackBar(
              content: Text(AppLocalizations.of(context)!.challenge_updated),
              backgroundColor: _kPrimary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppLocalizations.of(context)!.error}: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
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
            title: Text(AppLocalizations.of(context)!.delete_challenge),
            content: Text(
              AppLocalizations.of(
                context,
              )!.confirm_delete_challenge(challenge.year.toString()),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: Text(AppLocalizations.of(context)!.delete),
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
            SnackBar(
              content: Text(AppLocalizations.of(context)!.challenge_deleted),
              backgroundColor: _kPrimary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppLocalizations.of(context)!.error}: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.year_challenges,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder.withValues(alpha: 0.6)),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(color: _kPrimary),
                    )
                    : _challenges.isEmpty && _currentYearChallenge == null
                    ? _buildEmptyState(l10n)
                    : _buildBody(l10n),
          ),
          _buildBottomBar(l10n),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: _kTrack,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.flag_outlined,
                size: 40,
                color: _kPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.no_challenges_yet,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.create_first_challenge,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14,
                color: _kSub,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 110),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child:
                  _currentYearChallenge != null
                      ? _buildHeroCard(_currentYearChallenge!)
                      : _buildNoCurrentYearCard(l10n),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'PREVIOUS YEARS',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _kSub,
                          letterSpacing: 0.7,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xB3EDE6E1),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          '${_previousChallenges.length} Years',
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'Sorted by year',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kSub,
                    ),
                  ),
                ],
              ),
            ),
            if (_previousChallenges.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  children:
                      _previousChallenges
                          .map(
                            (challenge) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildHistoryCard(challenge),
                            ),
                          )
                          .toList(),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Text(
                  'No previous challenges yet.',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    color: _kSub,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(YearChallenge challenge) {
    final progress = _progressData[challenge.year] ?? {};
    final booksRead = progress['booksRead'] ?? 0;
    final targetBooks = progress['targetBooks'] ?? 0;
    final pagesRead = progress['pagesRead'] ?? 0;
    final targetPages = progress['targetPages'] ?? 0;
    final booksProgress = (progress['booksProgress'] ?? 0.0) as double;

    final percentage = targetBooks > 0 ? (booksProgress * 100).round() : 0;
    final booksLeft = (targetBooks - booksRead).clamp(0, 999999);
    final monthsLeft = (12 - DateTime.now().month + 1).clamp(1, 12);
    final monthlyPace =
        monthsLeft > 0 ? (booksLeft / monthsLeft).toStringAsFixed(1) : '0.0';
    final ahead = booksRead - (targetBooks / 12 * DateTime.now().month);

    final isComplete =
        booksRead >= targetBooks &&
        (challenge.targetPages == null || pagesRead >= targetPages);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.2)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.white, Color(0xFFF9F1F4)],
          stops: [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.08),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorative watermarked year
          Positioned(
            right: -8,
            bottom: -16,
            child: Text(
              '${challenge.year}',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 72,
                fontWeight: FontWeight.w900,
                color: _kPrimary.withValues(alpha: 0.04),
                letterSpacing: -3.6,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _kPrimary,
                          borderRadius: BorderRadius.circular(9999),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 1,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF34D399),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${challenge.year} Active',
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _kSuccessBg,
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(
                            color: _kSuccessBorder.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isComplete
                                  ? Icons.check_circle
                                  : Icons.trending_up,
                              size: 12,
                              color: const Color(0xFF047857),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isComplete ? 'Goal Met!' : 'On Track',
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF047857),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () => _showEditChallengeDialog(challenge),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        child: const Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: _kSub,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Center content
              Row(
                children: [
                  SizedBox(
                    width: 112,
                    height: 112,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: booksProgress.clamp(0.0, 1.0),
                          strokeWidth: 10,
                          backgroundColor: _kTrack,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            _kPrimary,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$percentage%',
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: _kPrimary,
                              ),
                            ),
                            const Text(
                              'COMPLETED',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _kSub,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$booksRead',
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: _kText,
                                letterSpacing: -0.75,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'of $targetBooks books',
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _kSub,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$booksLeft books left to conquer this goal',
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildMetricPill(
                          Icons.auto_stories,
                          '~$monthlyPace bks / mo',
                        ),
                        const SizedBox(height: 6),
                        _buildMetricPill(
                          Icons.schedule,
                          ahead >= 0
                              ? 'Pacing +${ahead.toStringAsFixed(0)} bks ahead'
                              : 'Pacing ${ahead.toStringAsFixed(0)} bks behind',
                        ),
                        if (challenge.targetPages != null && targetPages > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: _buildMetricPill(
                              Icons.menu_book,
                              '$pagesRead / $targetPages pages',
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoCurrentYearCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.2)),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.08),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${DateTime.now().year} ${l10n.reading_goals}',
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.no_challenge_set_for_year(DateTime.now().year.toString()),
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              color: _kSub,
            ),
          ),
          const SizedBox(height: 20),
          _buildPrimaryButton(
            icon: Icons.add,
            label: 'Set ${DateTime.now().year} Goal',
            onTap: _showAddChallengeDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _kText),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _kText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _kPrimary,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(YearChallenge challenge) {
    final progress = _progressData[challenge.year] ?? {};
    final booksRead = progress['booksRead'] ?? 0;
    final targetBooks = progress['targetBooks'] ?? 0;
    final booksProgress = (progress['booksProgress'] ?? 0.0) as double;
    final isComplete = targetBooks > 0 && booksRead >= targetBooks;
    final percentage = targetBooks > 0 ? (booksProgress * 100).round() : 0;

    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: isComplete ? _kSuccessBg : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isComplete ? const Color(0xFF6EE7B7) : _kBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isComplete ? _kSuccessBg : _kPrimarySoft,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        isComplete
                            ? const Color(0xFF6EE7B7)
                            : _kPrimary.withValues(alpha: 0.2),
                  ),
                ),
                child: Center(
                  child:
                      isComplete
                          ? const Icon(
                            Icons.emoji_events,
                            size: 16,
                            color: _kSuccess,
                          )
                          : Text(
                            '${challenge.year % 100}',
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _kPrimary,
                            ),
                          ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${challenge.year} Challenge',
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _kText,
                            letterSpacing: -0.45,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isComplete
                                    ? _kSuccessBg
                                    : const Color(0xFFF7F1ED),
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(
                              color: isComplete ? _kSuccessBorder : _kBorder,
                            ),
                          ),
                          child: Text(
                            isComplete ? 'Goal Met!' : '$percentage% met',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color:
                                  isComplete ? const Color(0xFF065F46) : _kSub,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Finished Dec 31, ${challenge.year}',
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: _kSub,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () => _deleteChallenge(challenge),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: isComplete ? _kSuccess : _kSub,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$booksRead of $targetBooks books',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isComplete ? const Color(0xFF064E3B) : _kSub,
                ),
              ),
              Text(
                '$booksRead / $targetBooks',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isComplete ? const Color(0xFF065F46) : _kText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: LinearProgressIndicator(
              value: booksProgress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor:
                  isComplete
                      ? const Color(0xFFD1FAE5).withValues(alpha: 0.8)
                      : _kTrack,
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete ? _kSuccess : _kPrimary.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(AppLocalizations l10n) {
    final nextYear = DateTime.now().year + 1;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kBorder),
            boxShadow: [
              BoxShadow(
                color: _kPrimary.withValues(alpha: 0.08),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: _kPrimary.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: _kPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Plan Ahead',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _kText,
                        ),
                      ),
                      Text(
                        'Set $nextYear Challenge',
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: _kSub,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Material(
                color: _kPrimary,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: _showAddChallengeDialog,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _kPrimary.withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.add, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          l10n.new_challenge,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

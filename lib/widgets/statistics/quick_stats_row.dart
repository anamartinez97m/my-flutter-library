import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myrandomlibrary/helpers/statistics_calculator.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';

/// Definition of an available quick stat.
class QuickStatDefinition {
  final String key;
  final IconData icon;
  final Color color;
  final String Function(BuildContext) labelBuilder;
  final String Function(StatisticsData) valueBuilder;

  const QuickStatDefinition({
    required this.key,
    required this.icon,
    required this.color,
    required this.labelBuilder,
    required this.valueBuilder,
  });
}

/// A row of 4 user-configurable stat tiles.
class QuickStatsRow extends StatefulWidget {
  final StatisticsData data;

  const QuickStatsRow({super.key, required this.data});

  @override
  State<QuickStatsRow> createState() => _QuickStatsRowState();
}

class _QuickStatsRowState extends State<QuickStatsRow> {
  static const String _prefsKey = 'quick_stats_keys';
  static const List<String> _defaultKeys = [
    'books_read_this_year',
    'average_rating',
    'current_streak',
    'reading_velocity',
  ];

  List<String> _selectedKeys = List.from(_defaultKeys);
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    if (stored != null) {
      try {
        final List<dynamic> decoded = jsonDecode(stored);
        final keys = decoded.cast<String>();
        if (keys.length == 4) {
          _selectedKeys = keys;
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _isLoaded = true);
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_selectedKeys));
  }

  List<QuickStatDefinition> _getAllDefinitions() {
    return [
      QuickStatDefinition(
        key: 'total_books_owned',
        icon: Icons.library_books,
        color: Colors.blue,
        labelBuilder: (ctx) => AppLocalizations.of(ctx)!.quick_stat_total_owned,
        valueBuilder: (d) => '${d.totalCount}',
      ),
      QuickStatDefinition(
        key: 'total_books_read',
        icon: Icons.menu_book,
        color: Colors.green,
        labelBuilder: (ctx) => AppLocalizations.of(ctx)!.quick_stat_total_read,
        valueBuilder: (d) => '${d.totalBooksRead}',
      ),
      QuickStatDefinition(
        key: 'books_read_this_year',
        icon: Icons.calendar_today,
        color: Colors.teal,
        labelBuilder: (ctx) => AppLocalizations.of(ctx)!.quick_stat_this_year,
        valueBuilder: (d) => '${d.booksReadThisYear}',
      ),
      QuickStatDefinition(
        key: 'average_rating',
        icon: Icons.star,
        color: Colors.amber,
        labelBuilder: (ctx) => AppLocalizations.of(ctx)!.quick_stat_avg_rating,
        valueBuilder: (d) => d.averageRating > 0 ? d.averageRating.toStringAsFixed(1) : '-',
      ),
      QuickStatDefinition(
        key: 'current_streak',
        icon: Icons.local_fire_department,
        color: Colors.orange,
        labelBuilder: (ctx) => AppLocalizations.of(ctx)!.quick_stat_streak,
        valueBuilder: (d) => '${d.currentStreak}d',
      ),
      QuickStatDefinition(
        key: 'longest_streak',
        icon: Icons.whatshot,
        color: Colors.deepOrange,
        labelBuilder: (ctx) => AppLocalizations.of(ctx)!.quick_stat_best_streak,
        valueBuilder: (d) => '${d.longestStreak}d',
      ),
      QuickStatDefinition(
        key: 'reading_velocity',
        icon: Icons.speed,
        color: Colors.indigo,
        labelBuilder: (ctx) => AppLocalizations.of(ctx)!.quick_stat_velocity,
        valueBuilder: (d) => d.readingVelocity > 0 ? '${d.readingVelocity.toStringAsFixed(1)}p/d' : '-',
      ),
      QuickStatDefinition(
        key: 'avg_days_to_finish',
        icon: Icons.timer,
        color: Colors.purple,
        labelBuilder: (ctx) => AppLocalizations.of(ctx)!.quick_stat_avg_days,
        valueBuilder: (d) => d.averageDaysToFinish > 0 ? '${d.averageDaysToFinish.toStringAsFixed(0)}d' : '-',
      ),
      QuickStatDefinition(
        key: 'avg_books_per_year',
        icon: Icons.trending_up,
        color: Colors.cyan,
        labelBuilder: (ctx) => AppLocalizations.of(ctx)!.quick_stat_books_year,
        valueBuilder: (d) => d.averageBooksPerYear > 0 ? d.averageBooksPerYear.toStringAsFixed(1) : '-',
      ),
      QuickStatDefinition(
        key: 'dnf_count',
        icon: Icons.close,
        color: Colors.red,
        labelBuilder: (ctx) => AppLocalizations.of(ctx)!.quick_stat_dnf,
        valueBuilder: (d) => '${d.dnfCount}',
      ),
      QuickStatDefinition(
        key: 'reread_count',
        icon: Icons.replay,
        color: Colors.teal,
        labelBuilder: (ctx) => AppLocalizations.of(ctx)!.quick_stat_rereads,
        valueBuilder: (d) => '${d.rereadCount}',
      ),
      QuickStatDefinition(
        key: 'series_count',
        icon: Icons.collections_bookmark,
        color: Colors.indigo,
        labelBuilder: (ctx) => AppLocalizations.of(ctx)!.quick_stat_series,
        valueBuilder: (d) => '${d.seriesCount}',
      ),
      QuickStatDefinition(
        key: 'sagas_completed',
        icon: Icons.check_circle,
        color: Colors.green,
        labelBuilder: (ctx) => AppLocalizations.of(ctx)!.quick_stat_sagas_done,
        valueBuilder: (d) => '${d.completedSagas}',
      ),
      QuickStatDefinition(
        key: 'next_milestone_owned',
        icon: Icons.flag,
        color: Colors.green,
        labelBuilder: (ctx) => AppLocalizations.of(ctx)!.quick_stat_milestone_owned,
        valueBuilder: (d) => '${d.booksToMilestoneOwned}',
      ),
      QuickStatDefinition(
        key: 'next_milestone_read',
        icon: Icons.flag_outlined,
        color: Colors.blue,
        labelBuilder: (ctx) => AppLocalizations.of(ctx)!.quick_stat_milestone_read,
        valueBuilder: (d) => '${d.booksToMilestoneRead}',
      ),
    ];
  }

  QuickStatDefinition? _findDefinition(String key) {
    final allDefs = _getAllDefinitions();
    try {
      return allDefs.firstWhere((d) => d.key == key);
    } catch (_) {
      return null;
    }
  }

  void _showStatPicker(int slotIndex) {
    final allDefs = _getAllDefinitions();
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
                  AppLocalizations.of(context)!.quick_stat_choose,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: allDefs.length,
                  itemBuilder: (ctx, index) {
                    final def = allDefs[index];
                    final isSelected = _selectedKeys.contains(def.key);
                    return ListTile(
                      leading: Icon(def.icon, color: def.color),
                      title: Text(def.labelBuilder(context)),
                      trailing: isSelected
                          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedKeys[slotIndex] = def.key;
                        });
                        _savePreferences();
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) return const SizedBox.shrink();

    return Row(
      children: List.generate(4, (index) {
        final def = _findDefinition(_selectedKeys[index]);
        if (def == null) return const Expanded(child: SizedBox.shrink());
        final value = def.valueBuilder(widget.data);
        final label = def.labelBuilder(context);
        return Expanded(
          child: GestureDetector(
            onLongPress: () => _showStatPicker(index),
            child: Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(def.icon, color: def.color, size: 20),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

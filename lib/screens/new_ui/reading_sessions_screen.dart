import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/model/reading_session.dart';
import 'package:myrandomlibrary/repositories/reading_session_repository.dart';

const _kText = Color(0xFF1C1B1A);
const _kSub = Color(0xFF514348);
const _kBg = Color(0xFFFDF8F6);
const _kPrimary = Color(0xFF5D2641);

/// v2 full-screen list of all reading sessions for a single book.
///
/// Shows summary stats (avg, longest, this week), a timeline of recent sessions,
/// and supports inline editing of a session's date, start time and duration.
class ReadingSessionsScreen extends StatefulWidget {
  final Book book;

  const ReadingSessionsScreen({super.key, required this.book});

  @override
  State<ReadingSessionsScreen> createState() => _ReadingSessionsScreenState();
}

class _ReadingSessionsScreenState extends State<ReadingSessionsScreen> {
  List<ReadingSession> _sessions = [];
  bool _isLoading = true;

  int? _editingSessionId;
  ReadingSession? _draftSession;
  late DateTime _editDate;
  late TimeOfDay _editTime;
  late TextEditingController _editDurationController;

  final ScrollController _scrollController = ScrollController();
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final repository = ReadingSessionRepository(db);
      final sessions = await repository.getSessionsForBook(widget.book.bookId!);
      sessions.sort((a, b) {
        final aTime = a.clickedAt ?? a.startTime;
        final bTime = b.clickedAt ?? b.startTime;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
        );
      }
    }
  }

  int get _totalSeconds {
    return _sessions.fold<int>(0, (sum, s) => sum + (s.durationSeconds ?? 0));
  }

  int? get _avgSeconds {
    final withDuration =
        _sessions.where((s) => (s.durationSeconds ?? 0) > 0).toList();
    if (withDuration.isEmpty) return null;
    final total = withDuration.fold<int>(
      0,
      (sum, s) => sum + (s.durationSeconds ?? 0),
    );
    return total ~/ withDuration.length;
  }

  int? get _longestSeconds {
    final withDuration =
        _sessions.where((s) => (s.durationSeconds ?? 0) > 0).toList();
    if (withDuration.isEmpty) return null;
    return withDuration
        .map((s) => s.durationSeconds ?? 0)
        .reduce((a, b) => a > b ? a : b);
  }

  int get _thisWeekSeconds {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return _sessions
        .where(
          (s) =>
              (s.startTime?.isAfter(weekAgo) ?? false) ||
              (s.clickedAt?.isAfter(weekAgo) ?? false),
        )
        .fold<int>(0, (sum, s) => sum + (s.durationSeconds ?? 0));
  }

  bool _isPersonalBest(ReadingSession session) {
    final longest = _longestSeconds;
    if (longest == null || longest == 0) return false;
    return (session.durationSeconds ?? 0) == longest;
  }

  void _startEditing(ReadingSession session) {
    final startTime = session.startTime ?? DateTime.now();
    final clickedAt = session.clickedAt ?? startTime;
    _editDate = DateTime(startTime.year, startTime.month, startTime.day);
    _editTime = TimeOfDay.fromDateTime(clickedAt);
    _editDurationController = TextEditingController(
      text: _formatDurationHms(session.durationSeconds ?? 0),
    );
    setState(() {
      _editingSessionId = session.sessionId;
      _draftSession = session.copyWith();
    });
  }

  void _cancelEditing() {
    _editDurationController.dispose();
    setState(() {
      _editingSessionId = null;
      _draftSession = null;
    });
  }

  bool get _hasEditChanges {
    if (_editingSessionId == null || _draftSession == null) return false;
    final original = _sessions.firstWhere(
      (s) => s.sessionId == _editingSessionId,
      orElse: () => _draftSession!,
    );
    final origStart = original.startTime ?? DateTime.now();
    final origClicked = original.clickedAt ?? origStart;
    final origDate = DateTime(origStart.year, origStart.month, origStart.day);
    final origTime = TimeOfDay.fromDateTime(origClicked);
    final origDuration = _formatDurationHms(original.durationSeconds ?? 0);
    if (_editDate != origDate) return true;
    if (_editTime != origTime) return true;
    if (_editDurationController.text.trim() != origDuration) return true;
    return false;
  }

  void _revertEditing() {
    if (_draftSession == null) return;
    // Find the original session from the list
    final original = _sessions.firstWhere(
      (s) => s.sessionId == _editingSessionId,
      orElse: () => _draftSession!,
    );
    final startTime = original.startTime ?? DateTime.now();
    final clickedAt = original.clickedAt ?? startTime;
    setState(() {
      _editDate = DateTime(startTime.year, startTime.month, startTime.day);
      _editTime = TimeOfDay.fromDateTime(clickedAt);
      _editDurationController.text = _formatDurationHms(
        original.durationSeconds ?? 0,
      );
      _draftSession = original.copyWith();
    });
  }

  Future<void> _saveEditing() async {
    if (_draftSession == null) return;

    final duration = _parseDurationHms(_editDurationController.text.trim());
    if (duration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context)!.error}: invalid duration format',
          ),
        ),
      );
      return;
    }

    final clickedAt = DateTime(
      _editDate.year,
      _editDate.month,
      _editDate.day,
      _editTime.hour,
      _editTime.minute,
    );
    final updated = _draftSession!.copyWith(
      startTime: DateTime(_editDate.year, _editDate.month, _editDate.day),
      clickedAt: clickedAt,
      durationSeconds: duration,
    );

    try {
      final db = await DatabaseHelper.instance.database;
      final repository = ReadingSessionRepository(db);
      await repository.updateSession(updated);
      await _loadSessions();
      _cancelEditing();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.reading_session_saved),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
        );
      }
    }
  }

  Future<void> _deleteSession(ReadingSession session) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.delete),
            content: Text(l10n.confirm_delete_session),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: Text(l10n.delete),
              ),
            ],
          ),
    );

    if (confirmed == true && session.sessionId != null) {
      try {
        final db = await DatabaseHelper.instance.database;
        final repository = ReadingSessionRepository(db);
        await repository.deleteSession(session.sessionId!);
        await _loadSessions();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${l10n.error}: $e')));
        }
      }
    }
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m ${secs.toString().padLeft(2, '0')}s';
    } else if (minutes > 0) {
      return '${minutes}m ${secs.toString().padLeft(2, '0')}s';
    }
    return '${secs}s';
  }

  String _formatDurationShort(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    return '${minutes}m';
  }

  String _formatDurationHms(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  int? _parseDurationHms(String text) {
    final parts = text.split(':');
    if (parts.length == 3) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final s = int.tryParse(parts[2]);
      if (h != null && m != null && s != null) {
        return h * 3600 + m * 60 + s;
      }
    } else if (parts.length == 2) {
      final m = int.tryParse(parts[0]);
      final s = int.tryParse(parts[1]);
      if (m != null && s != null) {
        return m * 60 + s;
      }
    }
    return null;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '--';
    return DateFormat('d MMM y').format(date);
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '--:--';
    return DateFormat.Hm().format(date);
  }

  Future<void> _pickEditDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _editDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: AppLocalizations.of(context)!.select_date,
    );
    if (picked != null) {
      setState(() {
        _editDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _pickEditTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _editTime,
      helpText: AppLocalizations.of(context)!.select_time,
    );
    if (picked != null) {
      setState(() {
        _editTime = picked;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    if (_editingSessionId != null) {
      _editDurationController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: _kPrimary),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.reading_sessions_title,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _kPrimary,
              ),
            ),
            Text(
              l10n.reading_sessions_subtitle(
                _sessions.length.toString(),
                _formatDuration(_totalSeconds),
              ),
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _kPrimary,
              ),
            ),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          // Stats row – single container with dividers
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F3F0),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0x22D5C2C7),
                              ),
                            ),
                            child: IntrinsicHeight(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _StatCell(
                                      label: l10n.avg_session,
                                      value: _formatDurationShort(
                                        _avgSeconds ?? 0,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    color: const Color(0x33D5C2C7),
                                  ),
                                  Expanded(
                                    child: _StatCell(
                                      label: l10n.longest_session,
                                      value: _formatDurationShort(
                                        _longestSeconds ?? 0,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    color: const Color(0x33D5C2C7),
                                  ),
                                  Expanded(
                                    child: _StatCell(
                                      label: l10n.this_week,
                                      value: _formatDurationShort(
                                        _thisWeekSeconds,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Recent sessions header with divider
                          Row(
                            children: [
                              Text(
                                l10n.recent_sessions.toUpperCase(),
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                  color: _kSub,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: const Color(0x33D5C2C7),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                    // Scrollable timeline
                    Expanded(
                      child:
                          _sessions.isEmpty
                              ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Text(
                                    l10n.no_reading_sessions,
                                    style: const TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 14,
                                      color: _kSub,
                                    ),
                                  ),
                                ),
                              )
                              : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                itemCount: _sessions.length,
                                itemBuilder: (context, index) {
                                  final session = _sessions[index];
                                  final isEditing =
                                      session.sessionId == _editingSessionId;
                                  final isLast = index == _sessions.length - 1;
                                  final isHovered = _hoveredIndex == index;
                                  return MouseRegion(
                                    onEnter:
                                        (_) => setState(
                                          () => _hoveredIndex = index,
                                        ),
                                    onExit:
                                        (_) => setState(
                                          () => _hoveredIndex = null,
                                        ),
                                    child: _TimelineItem(
                                      isLast: isLast,
                                      isHovered: isHovered,
                                      child:
                                          isEditing
                                              ? _EditingSessionCard(
                                                sessionNumber:
                                                    _sessions.length - index,
                                                editDate: _editDate,
                                                editTime: _editTime,
                                                durationController:
                                                    _editDurationController,
                                                onDateTap: _pickEditDate,
                                                onTimeTap: _pickEditTime,
                                                onDurationChanged:
                                                    (value) => setState(() {}),
                                                canRevert: _hasEditChanges,
                                                onRevert: _revertEditing,
                                                onDone: _saveEditing,
                                              )
                                              : _SessionCard(
                                                session: session,
                                                isPersonalBest: _isPersonalBest(
                                                  session,
                                                ),
                                                onEdit:
                                                    () =>
                                                        _startEditing(session),
                                                onDelete:
                                                    () =>
                                                        _deleteSession(session),
                                                formatDuration: _formatDuration,
                                                formatDate: _formatDate,
                                                formatTime: _formatTime,
                                              ),
                                    ),
                                  );
                                },
                              ),
                    ),
                  ],
                ),
              ),
    );
  }
}

/// A single stat cell inside the unified stats row.
class _StatCell extends StatelessWidget {
  final String label;
  final String value;

  const _StatCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: _kSub,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final bool isLast;
  final bool isHovered;
  final Widget child;

  const _TimelineItem({
    required this.isLast,
    required this.child,
    this.isHovered = false,
  });

  @override
  Widget build(BuildContext context) {
    const dotColor = Color(0xFF5D2641);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isHovered ? 16 : 10,
                  height: isHovered ? 16 : 10,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border:
                        isHovered
                            ? Border.all(
                              color: dotColor.withValues(alpha: 0.3),
                              width: 3,
                            )
                            : null,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: dotColor.withValues(alpha: 0.4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final ReadingSession session;
  final bool isPersonalBest;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String Function(int) formatDuration;
  final String Function(DateTime?) formatDate;
  final String Function(DateTime?) formatTime;

  const _SessionCard({
    required this.session,
    this.isPersonalBest = false,
    required this.onEdit,
    required this.onDelete,
    required this.formatDuration,
    required this.formatDate,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    final date = session.startTime ?? session.clickedAt;
    final time = session.clickedAt ?? session.startTime;
    final duration = session.durationSeconds ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x33D5C2C7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First row: duration badge + edit/delete
          Row(
            children: [
              // Duration badge with clock icon
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      isPersonalBest
                          ? Theme.of(
                            context,
                          ).colorScheme.secondary.withValues(alpha: 0.15)
                          : const Color(0xFFF7F3F0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isPersonalBest
                            ? Theme.of(context).colorScheme.secondary
                            : const Color(0xFFD5C2C7),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: Color(0xFF5D2641),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formatDuration(duration),
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF5D2641),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onEdit,
                child: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: _kPrimary,
                ),
              ),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: _kPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Second row: date · time
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 13, color: _kSub),
              const SizedBox(width: 5),
              Text(
                formatDate(date),
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _kSub,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '·',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kSub.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const Icon(Icons.access_time, size: 13, color: _kSub),
              const SizedBox(width: 5),
              Text(
                formatTime(time),
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _kSub,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditingSessionCard extends StatelessWidget {
  final int sessionNumber;
  final DateTime editDate;
  final TimeOfDay editTime;
  final TextEditingController durationController;

  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;
  final ValueChanged<String> onDurationChanged;
  final bool canRevert;
  final VoidCallback onRevert;
  final VoidCallback onDone;

  const _EditingSessionCard({
    required this.sessionNumber,
    required this.editDate,
    required this.editTime,
    required this.durationController,

    required this.onDateTap,
    required this.onTimeTap,
    required this.onDurationChanged,
    this.canRevert = false,
    required this.onRevert,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kPrimary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: dot + "EDITING SESSION" + revert/done icons
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: _kPrimary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.editing_session,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: _kPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: canRevert ? onRevert : null,
                child: Icon(
                  Icons.undo,
                  size: 18,
                  color:
                      canRevert ? _kPrimary : _kPrimary.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: onDone,
                child: const Icon(Icons.check, size: 18, color: _kPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Date and Start Time side by side
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.date_label.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                        color: _kSub,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: onDateTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F3F0),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0x33D5C2C7)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 15,
                              color: _kPrimary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('yyyy-MM-dd').format(editDate),
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _kText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.start_time.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                        color: _kSub,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: onTimeTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F3F0),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0x33D5C2C7)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 15,
                              color: _kPrimary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              editTime.format(context),
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _kText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Duration
          Text(
            l10n.duration_label.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: _kSub,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F3F0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD5C2C7)),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: _kPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: durationController,
                    textAlign: TextAlign.left,
                    keyboardType: TextInputType.datetime,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
                    ],
                    onChanged: onDurationChanged,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

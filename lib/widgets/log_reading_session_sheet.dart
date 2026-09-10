import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/repositories/reading_session_repository.dart';

/// v2 bottom sheet for logging a reading session manually.
///
/// Displays a date picker, time picker, an interactive duration slider with
/// quick-add presets and a pair of discard/log actions. The live stopwatch,
/// book info header, pages-read and session-note fields from the previous
/// timer-based v2 sheet have been intentionally removed.
class LogReadingSessionSheet extends StatefulWidget {
  final int bookId;
  final VoidCallback? onSessionComplete;

  const LogReadingSessionSheet({
    super.key,
    required this.bookId,
    this.onSessionComplete,
  });

  @override
  State<LogReadingSessionSheet> createState() => _LogReadingSessionSheetState();
}

class _LogReadingSessionSheetState extends State<LogReadingSessionSheet> {
  static const _kBg = Color(0xFFFDF8F6);
  static const _kPrimary = Color(0xFF5D2641);
  static const _kText = Color(0xFF1C1B1A);
  static const _kSub = Color(0xFF514348);
  static const _kCardBg = Color(0xFFF7F3F0);
  static const _kBorder = Color(0xFFD5C2C7);

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late final TextEditingController _customMinutesController;
  int _durationMinutes = 35;
  bool _isCustomMode = false;
  bool _isSaving = false;

  static const int _minDuration = 5;
  static const int _maxDuration = 120;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _selectedTime = TimeOfDay.fromDateTime(now);
    _customMinutesController = TextEditingController(
      text: _durationMinutes.toString(),
    );
  }

  @override
  void dispose() {
    _customMinutesController.dispose();
    super.dispose();
  }

  DateTime get _sessionStartTime {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  String get _formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = _selectedDate == today;

    if (isToday) {
      return AppLocalizations.of(context)!.today;
    }
    final month = DateFormat.MMM().format(_selectedDate);
    final day = _selectedDate.day.toString();
    return '$month $day';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: AppLocalizations.of(context)!.select_date,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      helpText: AppLocalizations.of(context)!.select_time,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _setDuration(int minutes) {
    setState(() {
      _durationMinutes = minutes.clamp(_minDuration, _maxDuration);
      _isCustomMode = false;
      _customMinutesController.text = _durationMinutes.toString();
    });
  }

  void _toggleCustomMode() {
    setState(() {
      _isCustomMode = !_isCustomMode;
      if (_isCustomMode) {
        _customMinutesController.text = _durationMinutes.toString();
      }
    });
  }

  void _onCustomMinutesChanged(String value) {
    final parsed = int.tryParse(value.trim());
    if (parsed != null && parsed > 0) {
      setState(() {
        _durationMinutes = parsed;
      });
    }
  }

  Future<void> _logSession() async {
    if (_durationMinutes <= 0) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      final repository = ReadingSessionRepository(db);
      await repository.createCustomSession(
        widget.bookId,
        _sessionStartTime,
        didRead: true,
        durationSeconds: _durationMinutes * 60,
      );

      if (mounted) {
        widget.onSessionComplete?.call();
        Navigator.pop(context);
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
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _discard() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: const BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 48,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0x80D5C2C7),
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
          ),
          SafeArea(
            top: false,
            left: false,
            right: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.reading_log.toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                              color: _kSub,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.log_reading_session,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: _kText,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: _discard,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _kCardBg,
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(
                              color: _kBorder.withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: _kText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Date & Time pickers
                  Row(
                    children: [
                      Expanded(
                        child: _PickerButton(
                          icon: Icons.calendar_today_outlined,
                          label: _formattedDate,
                          onTap: _pickDate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PickerButton(
                          icon: Icons.access_time,
                          label: _selectedTime.format(context),
                          onTap: _pickTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Duration card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _kCardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0x33D5C2C7)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${_durationMinutes}m',
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 40,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.reading_duration.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: _kSub,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: _kPrimary,
                            inactiveTrackColor: const Color(0xFFD5C2C7),
                            thumbColor: _kPrimary,
                            overlayColor: _kPrimary.withValues(alpha: 0.1),
                            trackHeight: 6,
                          ),
                          child: Slider(
                            value:
                                _durationMinutes
                                    .clamp(_minDuration, _maxDuration)
                                    .toDouble(),
                            min: _minDuration.toDouble(),
                            max: _maxDuration.toDouble(),
                            divisions: 23,
                            onChanged: (value) {
                              setState(() {
                                _durationMinutes = value.round();
                                _isCustomMode = false;
                                _customMinutesController.text =
                                    _durationMinutes.toString();
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            _DurationLabel('5m'),
                            _DurationLabel('15m'),
                            _DurationLabel('30m'),
                            _DurationLabel('45m'),
                            _DurationLabel('60m'),
                            _DurationLabel('90+'),
                          ],
                        ),
                        const SizedBox(height: 20),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            const gap = 8.0;
                            final columnWidth =
                                (constraints.maxWidth - 3 * gap) / 4;
                            final twoColumnWidth = columnWidth * 2 + gap;

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      width: columnWidth,
                                      child: _DurationChip(
                                        label: '+5m',
                                        isSelected:
                                            !_isCustomMode &&
                                            _durationMinutes == 5,
                                        onTap: () => _setDuration(5),
                                      ),
                                    ),
                                    const SizedBox(width: gap),
                                    SizedBox(
                                      width: columnWidth,
                                      child: _DurationChip(
                                        label: '+15m',
                                        isSelected:
                                            !_isCustomMode &&
                                            _durationMinutes == 15,
                                        onTap: () => _setDuration(15),
                                      ),
                                    ),
                                    const SizedBox(width: gap),
                                    SizedBox(
                                      width: columnWidth,
                                      child: _DurationChip(
                                        label: '+30m',
                                        isSelected:
                                            !_isCustomMode &&
                                            _durationMinutes == 30,
                                        onTap: () => _setDuration(30),
                                      ),
                                    ),
                                    const SizedBox(width: gap),
                                    SizedBox(
                                      width: columnWidth,
                                      child: _DurationChip(
                                        label: '1h',
                                        isSelected:
                                            !_isCustomMode &&
                                            _durationMinutes == 60,
                                        onTap: () => _setDuration(60),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: gap),
                                Row(
                                  children: [
                                    SizedBox(
                                      width: twoColumnWidth,
                                      child: _DurationChip(
                                        label: l10n.custom,
                                        isSelected: _isCustomMode,
                                        onTap: _toggleCustomMode,
                                      ),
                                    ),
                                    const SizedBox(width: gap),
                                    SizedBox(
                                      width: twoColumnWidth,
                                      child: Container(
                                        height: 40,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color:
                                              _isCustomMode
                                                  ? Colors.white
                                                  : _kCardBg,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color:
                                                _isCustomMode
                                                    ? const Color(0xFF5D2641)
                                                    : const Color(0xFFD5C2C7),
                                          ),
                                        ),
                                        child: TextField(
                                          controller: _customMinutesController,
                                          enabled: _isCustomMode,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          onChanged: _onCustomMinutesChanged,
                                          textAlign: TextAlign.center,
                                          decoration: InputDecoration(
                                            hintText: l10n.minutes_short,
                                            border: InputBorder.none,
                                            isDense: true,
                                            contentPadding: EdgeInsets.zero,
                                            hintStyle: TextStyle(
                                              color:
                                                  _isCustomMode
                                                      ? const Color(
                                                        0xFF5D2641,
                                                      ).withValues(alpha: 0.5)
                                                      : const Color(
                                                        0xFF514348,
                                                      ).withValues(alpha: 0.5),
                                            ),
                                          ),
                                          style: const TextStyle(
                                            fontFamily: 'Manrope',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF5D2641),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : _discard,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _kText,
                            side: const BorderSide(color: _kBorder),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: Text(l10n.discard),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _isSaving ? null : _logSession,
                          style: FilledButton.styleFrom(
                            backgroundColor: _kPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isSaving)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              else
                                const Icon(Icons.check, size: 18),
                              const SizedBox(width: 8),
                              Text(l10n.log_session),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F3F0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x33D5C2C7)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF5D2641)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C1B1A),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: Color(0xFF514348),
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationLabel extends StatelessWidget {
  final String label;

  const _DurationLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: Color(0xFF514348),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DurationChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5D2641) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF5D2641) : const Color(0xFFD5C2C7),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF5D2641),
          ),
        ),
      ),
    );
  }
}

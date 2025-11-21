import 'dart:async';
import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/model/reading_session.dart';
import 'package:myrandomlibrary/repositories/reading_session_repository.dart';

class ChronometerWidget extends StatefulWidget {
  final int bookId;
  final VoidCallback? onSessionComplete;

  const ChronometerWidget({
    super.key,
    required this.bookId,
    this.onSessionComplete,
  });

  @override
  State<ChronometerWidget> createState() => _ChronometerWidgetState();
}

class _ChronometerWidgetState extends State<ChronometerWidget> {
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isRunning = false;
  ReadingSession? _activeSession;
  DateTime? _sessionStartTime;

  @override
  void initState() {
    super.initState();
    _loadActiveSession();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadActiveSession() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final repository = ReadingSessionRepository(db);
      final session = await repository.getActiveSession(widget.bookId);

      if (session != null && mounted) {
        setState(() {
          _activeSession = session;
          _sessionStartTime = session.startTime;
          _elapsedSeconds = session.durationSeconds ?? 0;
          if (session.isActive) {
            // Resume timer
            final now = DateTime.now();
            final additionalSeconds =
                now.difference(session.startTime).inSeconds;
            _elapsedSeconds += additionalSeconds;
            _startTimer();
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading active session: $e');
    }
  }

  void _startTimer() {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _sessionStartTime ??= DateTime.now();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  Future<void> _stopAndSaveSession() async {
    try {
      _timer?.cancel();
      
      // Save the duration before resetting
      final savedDuration = _elapsedSeconds;

      final db = await DatabaseHelper.instance.database;
      final repository = ReadingSessionRepository(db);

      if (_activeSession != null) {
        // Update existing session
        await repository.endSession(
          _activeSession!.sessionId!,
          DateTime.now(),
          _elapsedSeconds,
        );
      } else if (_sessionStartTime != null) {
        // Create new session
        await repository.createSession(
          ReadingSession(
            bookId: widget.bookId,
            startTime: _sessionStartTime!,
            endTime: DateTime.now(),
            durationSeconds: _elapsedSeconds,
            isActive: false,
          ),
        );
      }

      setState(() {
        _isRunning = false;
        _elapsedSeconds = 0;
        _activeSession = null;
        _sessionStartTime = null;
      });

      widget.onSessionComplete?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reading session saved: ${_formatDuration(savedDuration)}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving session: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createNewSession() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final repository = ReadingSessionRepository(db);

      final now = DateTime.now();
      final session = ReadingSession(
        bookId: widget.bookId,
        startTime: now,
        isActive: true,
        clickedAt: now, // Save when the chronometer was clicked
      );

      final sessionId = await repository.createSession(session);

      setState(() {
        _activeSession = session.copyWith(sessionId: sessionId);
        _sessionStartTime = now;
        _elapsedSeconds = 0;
      });

      _startTimer();
    } catch (e) {
      debugPrint('Error creating session: $e');
    }
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  Future<bool> _handleBackButton() async {
    if (_isRunning) {
      // Show confirmation dialog if timer is running
      final shouldClose = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Stop Timer?'),
          content: const Text('Do you want to stop the reading timer?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Stop'),
            ),
          ],
        ),
      );
      
      if (shouldClose == true) {
        _timer?.cancel();
        return true;
      }
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _handleBackButton();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Reading Timer',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () async {
                  if (_isRunning) {
                    // Show confirmation dialog if timer is running
                    final shouldClose = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Timer is Running'),
                        content: const Text(
                          'The timer is still counting. Are you sure you want to exit without stopping it?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Exit'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    );
                    if (shouldClose == true && mounted) {
                      Navigator.pop(context);
                    }
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Timer display
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _formatDuration(_elapsedSeconds),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (!_isRunning && _elapsedSeconds == 0)
                ElevatedButton.icon(
                  onPressed: _createNewSession,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              if (_isRunning)
                ElevatedButton.icon(
                  onPressed: _pauseTimer,
                  icon: const Icon(Icons.pause),
                  label: const Text('Pause'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              if (!_isRunning && _elapsedSeconds > 0)
                ElevatedButton.icon(
                  onPressed: _startTimer,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Resume'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              if (_elapsedSeconds > 0)
                ElevatedButton.icon(
                  onPressed: _stopAndSaveSession,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop & Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 50),
        ],
      ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:myrandomlibrary/config/themes/app_theme_palette.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/providers/theme_provider.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/repositories/reading_session_repository.dart';
import 'package:myrandomlibrary/services/notification_service.dart';
import 'package:myrandomlibrary/utils/home_widget_snapshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the Android "Currently reading" home widget in sync with the app.
class HomeWidgetService {
  HomeWidgetService._();
  static final HomeWidgetService instance = HomeWidgetService._();

  static const _channel = MethodChannel('com.anamm.mylibrary/home_widget');
  static const _chronoPrefix = 'chronometer_session_';

  /// Book id whose timer was changed from the widget or its notification.
  final ValueNotifier<int?> timerChanges = ValueNotifier<int?>(null);

  Timer? _debounce;
  Future<void> _syncing = Future.value();

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  void initialize() {
    if (!_supported) return;
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'openBook':
          await NotificationService().navigateToBook(call.arguments as int);
        case 'timerChanged':
          await (await SharedPreferences.getInstance()).reload();
          timerChanges.value = null;
          timerChanges.value = call.arguments as int;
      }
    });
  }

  /// Opens the book the app was launched for from the widget, if any.
  Future<void> handleLaunch() async {
    if (!_supported) return;
    try {
      final bookId = await _channel.invokeMethod<int>('consumeLaunchBookId');
      if (bookId != null) await NotificationService().navigateToBook(bookId);
    } catch (e) {
      debugPrint('Home widget launch failed: $e');
    }
  }

  /// Schedules a sync, merging calls made close together.
  void requestRefresh() {
    if (!_supported) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), refresh);
  }

  Future<void> refresh() {
    if (!_supported) return Future.value();
    _debounce?.cancel();
    return _syncing = _syncing.then((_) => _sync()).catchError((Object e) {
      debugPrint('Home widget sync failed: $e');
    });
  }

  Future<void> _sync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final l10n = lookupAppLocalizations(
      Locale(prefs.getString('language_code') ?? 'en'),
    );

    final db = await DatabaseHelper.instance.database;
    final bookRepo = BookRepository(db);
    final sessionRepo = ReadingSessionRepository(db);

    final started = await bookRepo.getStartedBooks();
    final lastActivity = <int, DateTime?>{};
    for (final book in started) {
      lastActivity[book.bookId!] = await sessionRepo.getLastReadingActivityDate(
        book.bookId!,
      );
    }
    final ordered = [...started]..sort((a, b) {
      final da = lastActivity[a.bookId!];
      final db = lastActivity[b.bookId!];
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });

    // Books with a timer in progress stay listed so the notification keeps
    // their title even after they stop being Started.
    final timerBookIds =
        prefs
            .getKeys()
            .where((k) => k.startsWith(_chronoPrefix))
            .map((k) => int.tryParse(k.substring(_chronoPrefix.length)))
            .whereType<int>()
            .toSet();
    final books = {for (final b in ordered) b.bookId!: b};
    for (final id in timerBookIds.difference(books.keys.toSet())) {
      final book = await bookRepo.getBookById(id);
      if (book != null) books[id] = book;
    }

    final coverDir = Directory(
      '${(await getApplicationSupportDirectory()).path}/widget_covers',
    );
    final booksJson = <String, dynamic>{};
    for (final book in books.values) {
      final snapshot = HomeWidgetSnapshot.fromBook(
        book,
        timedSeconds: await sessionRepo.getTotalReadingTime(book.bookId!),
        l10n: l10n,
      );
      booksJson['${book.bookId}'] = {
        'title': snapshot.title,
        'subtitle': snapshot.subtitle,
        'progressText': snapshot.progressText,
        'percent': snapshot.percent,
        'remaining': snapshot.remaining,
        'cover': await _cachedCover(coverDir, book.bookId!, book.coverUrl),
      };
    }
    await _deleteUnusedCovers(
      coverDir,
      booksJson.values.map((b) => b['cover']).whereType<String>().toSet(),
    );

    final family = AppThemeFamily.values.firstWhere(
      (f) => f.name == prefs.getString('theme_family'),
      orElse: () => AppThemeFamily.main,
    );
    final payload = {
      'books': booksJson,
      'started': ordered.map((b) => b.bookId).toList(),
      'theme': {
        'mode': prefs.getString('theme_mode') ?? AppThemeMode.system.name,
        'light': _colors(family.lightPalette),
        'dark': _colors(family.darkPalette),
      },
      'strings': {
        'header': l10n.widget_header,
        'startTimer': l10n.widget_start_timer,
        'noBooks': l10n.widget_no_books,
        'openApp': l10n.widget_open_app,
        'pickTitle': l10n.widget_pick_title,
        'pickEmpty': l10n.widget_pick_empty,
        'timerRunning': l10n.widget_timer_running('%s'),
        'sessionSaved': l10n.widget_session_saved('%s'),
        'paused': l10n.widget_paused,
        'pause': l10n.pause,
        'resume': l10n.resume,
        'stop': l10n.stop,
        'channel': l10n.widget_timer_channel,
      },
    };
    await _channel.invokeMethod('sync', jsonEncode(payload));
  }

  Map<String, int> _colors(AppThemePalette p) => {
    'background': p.background.toARGB32(),
    'text': p.textPrimary.toARGB32(),
    'textMuted': p.textMuted.toARGB32(),
    'header': p.secondary.toARGB32(),
    'primary': p.primary.toARGB32(),
    'onPrimary': p.onPrimary.toARGB32(),
    'track': p.control.toARGB32(),
  };

  /// Downloads the cover once per URL; the file name carries the URL hash.
  Future<String?> _cachedCover(Directory dir, int bookId, String? url) async {
    final trimmed = url?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    final file = File(
      '${dir.path}/${bookId}_${trimmed.hashCode.toUnsigned(32)}.img',
    );
    if (await file.exists()) return file.path;
    if (!trimmed.startsWith('http')) {
      return await File(trimmed).exists() ? trimmed : null;
    }
    try {
      final response = await http
          .get(Uri.parse(trimmed.replaceFirst('http://', 'https://')))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        return null;
      }
      await dir.create(recursive: true);
      await file.writeAsBytes(response.bodyBytes);
      return file.path;
    } catch (e) {
      debugPrint('Widget cover download failed for book $bookId: $e');
      return null;
    }
  }

  Future<void> _deleteUnusedCovers(Directory dir, Set<String> keep) async {
    if (!await dir.exists()) return;
    await for (final entity in dir.list()) {
      if (!keep.contains(entity.path)) await entity.delete();
    }
  }
}

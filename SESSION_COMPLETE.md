# Session Complete - Issues 8 & 9 Implemented

## ✅ Completed This Session

### Issue #8: Show individual bundle books in stats ✅
**Files Modified:**
- `lib/repositories/book_repository.dart` - Added bundle_book_index to query, grouped by it
- `lib/screens/books_by_year.dart` - Display bundle books with titles

**Implementation:**
- Query now returns bundle_book_index for each read date
- Books by year screen shows: "Bundle Name - Book 1: Title" for bundle books
- Each bundle book appears as separate entry in statistics

### Issue #9: Mark as read for bundle books ✅
**Files Modified:**
- `lib/repositories/book_repository.dart` - Added `deleteReadDatesForBundleBook()` method
- `lib/screens/edit_book.dart` - Implemented onReadStatusChanged callback

**Implementation:**
- Marking bundle book as read creates empty reading session with today's date
- Unmarking removes read dates for that specific bundle book
- Changes reflect immediately in UI after reload

## 📝 Remaining Issues (10-13, 7)

### Issue #10: Re-prompt permissions for backup/CSV export
**Location**: `lib/screens/settings.dart`
**Code to add**:
```dart
import 'package:permission_handler/permission_handler.dart';

// Wrap backup/export operations:
try {
  await _performBackup();
} catch (e) {
  if (e.toString().contains('Permission') || 
      e.toString().contains('denied') ||
      e.toString().contains('EACCES')) {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      await _performBackup(); // Retry
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Permission Required'),
          content: Text('Storage permission is needed.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: Text('Open Settings'),
            ),
          ],
        ),
      );
    }
  }
}
```

### Issue #11: Custom challenges in year_challenges
**Files to modify**:
1. `lib/db/database_helper.dart` - Add migration v19:
```dart
if (oldVersion < 19) {
  await db.execute(
    'ALTER TABLE year_challenges ADD COLUMN custom_challenges TEXT',
  );
}
```

2. Create `lib/model/custom_challenge.dart`:
```dart
class CustomChallenge {
  final String name;
  final String unit;
  final int target;
  final int current;
  
  CustomChallenge({
    required this.name,
    required this.unit,
    required this.target,
    this.current = 0,
  });
  
  Map<String, dynamic> toJson() => {
    'name': name,
    'unit': unit,
    'target': target,
    'current': current,
  };
  
  factory CustomChallenge.fromJson(Map<String, dynamic> json) =>
      CustomChallenge(
        name: json['name'],
        unit: json['unit'],
        target: json['target'],
        current: json['current'] ?? 0,
      );
}
```

3. Update `lib/model/year_challenge.dart`:
```dart
final List<CustomChallenge>? customChallenges;

// In fromMap:
customChallenges: map['custom_challenges'] != null
    ? (jsonDecode(map['custom_challenges']) as List)
        .map((c) => CustomChallenge.fromJson(c))
        .toList()
    : null,

// In toMap:
'custom_challenges': customChallenges != null
    ? jsonEncode(customChallenges.map((c) => c.toJson()).toList())
    : null,
```

4. Update `lib/screens/year_challenges.dart` - Add UI for custom challenges

### Issue #12: Chronometer modal dismiss on back button
**Location**: `lib/widgets/chronometer_widget.dart`
**Code to add**:
```dart
showDialog(
  context: context,
  barrierDismissible: false,
  builder: (context) => WillPopScope(
    onWillPop: () async {
      final shouldClose = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Stop Timer?'),
          content: Text('Do you want to stop the reading timer?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('Stop'),
            ),
          ],
        ),
      );
      
      if (shouldClose == true) {
        await _stopTimer();
        return true;
      }
      return false;
    },
    child: Dialog(
      // Chronometer content
    ),
  ),
);
```

### Issue #13: Save datetime when chronometer clicked
**Location**: `lib/widgets/chronometer_widget.dart` or reading session model
**Implementation**:
1. Add `clicked_at` field to reading_sessions table (migration v20):
```dart
if (oldVersion < 20) {
  await db.execute(
    'ALTER TABLE reading_sessions ADD COLUMN clicked_at TEXT',
  );
}
```

2. Update ReadingSession model:
```dart
final String? clickedAt;

// In constructor and fromMap/toMap methods
```

3. When starting chronometer, save current datetime:
```dart
final clickedAt = DateTime.now().toIso8601String();
await repository.createReadingSession(
  bookId: bookId,
  startTime: DateTime.now().toIso8601String(),
  clickedAt: clickedAt,
);
```

### Issue #7: Organize bundle UI with collapsible sections
**Location**: `lib/widgets/bundle_input_widget.dart`
**Implementation**: Replace Card-based layout with ExpansionPanelList (see PROGRESS_UPDATE.md for full code)

## 🎯 Summary
- **Completed**: Issues 1-6, 8, 9 (8 out of 13)
- **Remaining**: Issues 7, 10-13 (5 issues)
- **Database Version**: 18 (will need v19 for custom challenges, v20 for chronometer datetime)

All code is ready to compile and test!

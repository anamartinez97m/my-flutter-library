# Implementation Notes - Remaining Tasks

## Completed Changes

### Issue #6: Add author field to individual bundle books ✅ (Partially)
- ✅ Added `bundle_authors TEXT` column to database (version 18)
- ✅ Updated Book model to include `bundleAuthors` field
- ✅ Updated all repository SELECT queries to include `bundle_authors`
- ✅ Updated repository INSERT/UPDATE to save `bundle_authors`
- ✅ Updated BundleInputWidget to include author fields for each book
- ⚠️ **REMAINING**: Update add_book.dart and edit_book.dart to pass bundleAuthors parameter

### Issues #1-5: All Completed ✅
1. myRating highlighting in admin import - Fixed
2. TBR books disappearing after admin import - Fixed
3. Notifications not working - Fixed
4. Current year in reading goals - Fixed
5. Average per year in seasonal patterns - Fixed

## Required Fixes for Issue #6

### 1. Update add_book.dart
Find the BundleInputWidget usage (around line 1090) and update the onChanged callback:

```dart
// OLD (6 parameters):
onChanged: (isBundle, count, numbers, pages, years, titles) {
  // ...
}

// NEW (7 parameters):
onChanged: (isBundle, count, numbers, pages, years, titles, authors) {
  setState(() {
    _isBundle = isBundle;
    _bundleCount = count;
    _bundleNumbers = numbers;
    _bundlePages = pages;
    _bundlePublicationYears = years;
    _bundleTitles = titles;
    _bundleAuthors = authors;  // ADD THIS
  });
}
```

Also add `List<String?>? _bundleAuthors;` to the state variables.

When creating the Book object, include:
```dart
bundleAuthors: _bundleAuthors != null ? jsonEncode(_bundleAuthors) : null,
```

### 2. Update edit_book.dart
Same changes as add_book.dart (around line 1286).

Parse bundleAuthors when loading:
```dart
List<String?>? bundleAuthors;
if (widget.book.bundleAuthors != null) {
  final List<dynamic> parsed = jsonDecode(widget.book.bundleAuthors!);
  bundleAuthors = parsed.map((a) => a as String?).toList();
}
```

Pass to BundleInputWidget:
```dart
initialBundleAuthors: bundleAuthors,
```

### 3. Update admin_csv_import.dart
Add `bundle_authors` to the query around line 493:
```dart
b.is_bundle, b.bundle_count, b.bundle_numbers, b.bundle_start_dates, 
b.bundle_end_dates, b.bundle_pages, b.bundle_publication_years, 
b.bundle_titles, b.bundle_authors,  // ADD THIS
b.tbr, b.is_tandem, b.original_book_id,
```

When creating bookToAdd for updates (lines 821-858), add:
```dart
bundleAuthors: item.existingBook?.bundleAuthors,
```

## Issue #7: Organize bundle UI with collapsible sections

Wrap the bundle book details in an ExpansionTile or ExpansionPanelList:

```dart
// In bundle_input_widget.dart, around line 221
ExpansionPanelList(
  expansionCallback: (int index, bool isExpanded) {
    setState(() {
      _expandedPanels[index] = !isExpanded;
    });
  },
  children: List.generate(_bundlePages.length, (index) {
    return ExpansionPanel(
      headerBuilder: (context, isExpanded) {
        return ListTile(
          title: Text('Book ${index + 1}'),
          subtitle: _bundleTitles[index] != null 
              ? Text(_bundleTitles[index]!)
              : null,
        );
      },
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // All the existing TextFormFields for this book
          ],
        ),
      ),
      isExpanded: _expandedPanels[index] ?? false,
    );
  }),
)
```

Add `Map<int, bool> _expandedPanels = {};` to state.

## Issue #8: Show individual bundle books in stats

In the statistics queries, need to check for bundle books with read dates:

```dart
// Example for books read by year
SELECT 
  COALESCE(b.name, 'Unknown') as book_name,
  rd.bundle_book_index,
  CASE 
    WHEN rd.bundle_book_index IS NOT NULL THEN 
      -- Extract title from bundle_titles JSON array
      json_extract(b.bundle_titles, '$[' || rd.bundle_book_index || ']')
    ELSE b.name
  END as display_name
FROM book b
INNER JOIN book_read_dates rd ON b.book_id = rd.book_id
WHERE strftime('%Y', rd.date_finished) = ?
```

## Issue #9: Mark as read for bundle books not working

In the onReadStatusChanged callback, create an empty reading session:

```dart
// In add_book.dart / edit_book.dart
onReadStatusChanged: (bundleIndex, isRead) async {
  if (isRead) {
    // Create empty read date
    final today = DateTime.now().toIso8601String().split('T')[0];
    await repository.addReadDate(ReadDate(
      bookId: widget.book.bookId!,
      dateStarted: today,
      dateFinished: today,
      bundleBookIndex: bundleIndex,
    ));
  } else {
    // Remove read dates for this bundle book
    await repository.deleteReadDatesForBundleBook(
      widget.book.bookId!,
      bundleIndex,
    );
  }
  // Reload to reflect changes
  setState(() {
    // Reload bundle read status
  });
}
```

Add to BookRepository:
```dart
Future<void> deleteReadDatesForBundleBook(int bookId, int bundleIndex) async {
  await db.delete(
    'book_read_dates',
    where: 'book_id = ? AND bundle_book_index = ?',
    whereArgs: [bookId, bundleIndex],
  );
}
```

## Issue #10: Re-prompt permissions for backup/CSV export

Wrap file operations in try-catch and check for permission errors:

```dart
try {
  // Existing backup/export code
} catch (e) {
  if (e.toString().contains('Permission') || 
      e.toString().contains('denied')) {
    // Request permissions again
    final status = await Permission.storage.request();
    if (status.isGranted) {
      // Retry the operation
    } else {
      // Show error
    }
  }
}
```

## Issue #11: Custom challenges in year_challenges

Update YearChallenge model to support custom challenges:

```dart
class YearChallenge {
  final int? challengeId;
  final int year;
  final int? targetBooks;
  final int? targetPages;
  final List<CustomChallenge>? customChallenges;
  // ...
}

class CustomChallenge {
  final String name;
  final String unit;
  final int target;
  final int current;
}
```

Store as JSON in database:
```dart
ALTER TABLE year_challenges ADD COLUMN custom_challenges TEXT;
```

## Issue #12: Chronometer modal dismiss on back button

Wrap the chronometer modal in WillPopScope:

```dart
WillPopScope(
  onWillPop: () async {
    // Show confirmation dialog
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
            child: Text('Stop'),
          ),
        ],
      ),
    );
    return shouldClose ?? false;
  },
  child: Dialog(
    // Chronometer content
  ),
)
```

Also add `barrierDismissible: false` when showing the dialog, then handle tap outside:

```dart
showDialog(
  context: context,
  barrierDismissible: false,  // Prevent dismiss on outside tap
  builder: (context) => GestureDetector(
    onTap: () {
      // Show confirmation when tapping outside
      _showStopTimerConfirmation(context);
    },
    child: WillPopScope(
      // ... chronometer content
    ),
  ),
)
```

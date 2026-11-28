# Android "Currently Reading" home widget: Implementation Plan

> Source: thread in `#devin-my-book-vault` ("how difficult is to implement a widget for android?").
> Status: **plan only, no code yet**. Open questions are in §7.
> Mockups: option **B** (Medium 4×2) was chosen from the four options shared in the thread.

---

## 0. Summary

A 4×2 Android home-screen widget for one book you are reading: cover, title, author, saga, progress bar and a ▶ button. The ▶ button starts the chronometer **from the widget, without opening the app** (option 2). Each widget is **pinned to one book**, which you pick when you add it. To follow two books, add two widgets.

| Phase | Scope |
|---|---|
| **0** | Widget layout (option B), book picker when the widget is added, tap → book detail, auto-refresh when progress, status or cover change |
| **1** | ▶ / ⏸ / ⏹ chronometer on the widget, running in the background and shared with the in-app chronometer |
| **2** | Polish: estimated time left, finished/removed-book states, theme handling, resize behaviour |

Decided in the thread:
- Layout: option B (Medium 4×2).
- Timer: option 2, which runs from the widget with a live counter and doesn't open the app.
- Book selection: each widget is pinned to one book.

---

## 1. Layout (option B)

```
┌──────────────────────────────────────────────┐
│ ┌──────┐  CURRENTLY READING                  │
│ │      │  The Name of the Wind               │
│ │cover │  Patrick Rothfuss · Kingkiller #1   │
│ │      │  ███████████░░░░░░░░░░░░  44%       │
│ │      │  p. 290 / 662                       │
│ └──────┘  [▶ Start timer]          ~6 h left │
└──────────────────────────────────────────────┘
```

- Progress text follows `Book.progressType`: `pages` → `p. 290 / 662` + %; `percentage` → `44%` only.
- Saga line shows `saga #nSaga` when the book has a saga; otherwise author only.
- Cover: `Book.coverUrl` is downloaded once, resized (~200 px tall) and cached as a file the widget reads. If there's no cover, a placeholder in the primary colour with the title on it.
- While a timer runs (phase 1), the bottom row becomes: `⏱ 00:12:34   [⏸] [⏹]`.
- Strings come from the ARB files (EN/ES).

## 2. Architecture

- **Package:** `home_widget` (Flutter ↔ Android widget bridge: shared data store, widget refresh, background callbacks, launch URIs).
- **Native side** (`android/app/src/main/kotlin/.../widget/`):
  - `ReadingWidgetProvider` (`AppWidgetProvider`) renders a `RemoteViews` XML layout (`res/layout/reading_widget.xml`), with `res/xml/reading_widget_info.xml` (4×2 min size, `configure` activity, preview image).
  - The live counter uses Android's `Chronometer` view inside `RemoteViews` (`setChronometer(base, null, running)`). It ticks by itself, so the app doesn't need to run to update it every second.
- **Flutter side:** new `lib/services/home_widget_service.dart`:
  - `refreshWidgetsForBook(bookId)`: loads the book and the active session, writes the widget data (`widget_<appWidgetId>_*` keys) and calls `HomeWidget.updateWidget`.
  - Called from the places that already change these fields: book save/edit (progress, status, cover), chronometer start/pause/stop, reading-progress updates, book delete.
- **Data per widget**: `appWidgetId → bookId` mapping, plus a precomputed display snapshot (title, author, saga, progress text, %, cover file path, timer state/base).

## 3. Adding a widget (book picker)

- Long-press home screen → Widgets → My Library → "Currently reading". Android opens a **configure screen**.
- The configure screen is a small Flutter route opened by the configure activity through a `mylibrary://widget/configure?id=<appWidgetId>` launch. It lists books with status **Started** (`status_helper`: `started`), with cover + title + progress, and a search box.
- Choosing a book saves `appWidgetId → bookId` and renders the widget. Cancelling cancels the widget add (standard Android behaviour).
- Changing the book later: on Android 12+, long-press the widget → "Reconfigure". On older Android, there's a small ⋯ icon on the widget (see Q4).

## 4. Tap → open the book

- Tapping anywhere except the buttons launches `mylibrary://book/<bookId>`.
- `MainActivity` is already `singleTop`, so it handles the launch URI and navigates to `NewBookDetailScreen`. This reuses the same navigation the notification payloads use today (`NotificationService._navigateToBookFromPayload`), including the cold-start "pending navigation" path.

## 5. Chronometer from the widget (phase 1)

Goal: the widget and the in-app `ChronometerWidget` are two views of **the same reading session** in `reading_sessions`.

- **▶ Start**: `HomeWidget` interactive background callback (Dart, headless, no UI) runs `ReadingSessionRepository.createSession(isActive: true, startTime: now)`. The same code path the sheet uses at `chronometer_widget.dart` "start".
  - It also writes the timer state to the shared store the sheet already reads from (`SharedPreferences` session-state keys used by `_saveSessionState`/`_loadSessionState`), then refreshes the widget so it shows the running `Chronometer`.
- **⏸ Pause**: background callback; same semantics as the sheet's pause (session stays active, elapsed time frozen). Widget shows the frozen time + ▶ (resume) + ⏹.
- **⏹ Stop**: background callback ends the session (`endSession`, `duration_seconds` = elapsed) exactly like the sheet's "finish". Then **opens the app on the book** so you can update the page (see Q2).
- **Opening the app while it runs**: the sheet already restores active sessions on open (`session.isActive && session.startTime != null` → resumes the counter), so opening the book and tapping the timer FAB shows the same running time. Pausing/stopping in the app refreshes the widget, and vice versa.
- **One timer at a time** across all widgets and the app (see Q3). Starting a second one asks first or is blocked.
- Existing rule kept: the sheet's X still asks for confirmation and **discards** the session. A running widget timer counts as "a session in progress".
- Optional: an ongoing notification while a timer runs (see Q6).

## 6. States and edge cases

| Situation | Widget shows |
|---|---|
| Book has no progress yet | Empty bar, `p. 0 / 662` (or `0%`) |
| Book has no pages and progress is in pages | Pages only, no % or bar |
| Book finished (status → read) | See Q1 |
| Book deleted | "Book not found, tap to choose another" → configure screen |
| App data restored/imported | All widgets refreshed after import/restore |
| Theme | See Q5 |
| Estimated time left | Based on your average reading speed for that book (pages ÷ timed seconds from `reading_sessions`). Hidden if there's no timed data or progress is in %. See Q7 |

Verification: emulator (Android 14) with the widget added. Check the picker, tap → detail, the progress refresh after editing the book, ▶/⏸/⏹ with the app killed, and the sheet ↔ widget sync. Plus unit tests for the snapshot builder (progress text, saga line, est. time).

---

## 7. Open questions

1. **Pinned book finished:** when the pinned book is marked as read, should the widget
   a) show a "Finished! 🎉 tap to choose your next book" card (opens the picker), or
   b) switch automatically to the Started book you read most recently?
2. **After ⏹ Stop:** open the app on the book so you can update your page (my default), or just save the session silently and stay on the home screen?
3. **One timer at a time:** if a timer is running for book A and you press ▶ on book B's widget, should it
   a) stop A (saving it) and start B, or
   b) do nothing and show "Timer already running for A"?
4. **Changing the pinned book:** is long-press → "Reconfigure" (Android 12+) enough, or do you also want a small ⋯ icon on the widget? Which Android version is your phone on?
5. **Theme:** should the widget follow the app's theme (Main/Ocean/Royal/Warm Earth + its light/dark setting) or the phone's light/dark mode with the Main colours?
6. **Ongoing notification:** while a widget timer runs, show a notification with the counter and ⏸/⏹ (useful from the lock screen), or keep everything on the widget only?
7. **"~6 h left":** keep the estimated time left, or use that space for something else (e.g. "42 min today")?
8. **Picker list:** only books with status **Started**, or also TBR books (so you can pin the next book before starting it)?

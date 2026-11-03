# Tropes — Implementation Plan

> Source: thread in `#devin-my-book-vault` ("what do you think about adding tropes to the books?").
> Status: **plan only, no code yet**. Open questions are at the end (§7). New UI only (`lib/screens/new_ui/`, plus the shared Add/Edit Book screens in their new-UI mode).

---

## 0. Summary

Tropes ("enemies to lovers", "found family", "chosen one"…) are a second, more specific way to tag a book next to genres. A book can have many tropes. The data model and UI follow the **genre** pattern: a lookup table, a many-to-many join table, a comma-joined `Book.trope` string and a chip field in Add/Edit Book.

| Phase | Scope |
|---|---|
| **0** | Data (+ 30 seeded tropes, editable/deletable), Add/Edit Book field, Book detail, Home search (genre search also matches tropes) |
| **1** | Random (filters + mood search), Lists ("Tropes" list type), Statistics |
| **1.5** | "Suggest tropes" from Hardcover (hardcover.app) in Add/Edit Book |
| **2** | CSV import/export. Before starting: verify that no existing import/export path breaks |

Decided in the thread:
- Start with ~30 common tropes. She can rename or delete them.
- The Tropes field goes **right after Genres** (Primary Info) in both Add Book and Edit Book.
- In the Home top-row search, **"Genre" searches genres and tropes together**. There is no separate "Trope" search option.

---

## 1. Phase 0: data, Add/Edit Book, Book detail, Home

### 1.1 Database (`lib/db/database_helper.dart`, version 46 → 47)

```sql
CREATE TABLE IF NOT EXISTS trope (
  trope_id INTEGER PRIMARY KEY AUTOINCREMENT,
  name VARCHAR(50) NOT NULL
);
CREATE TABLE IF NOT EXISTS books_by_trope (
  books_by_trope_id INTEGER PRIMARY KEY,
  trope_id INTEGER,
  book_id INTEGER,
  FOREIGN KEY (trope_id) REFERENCES trope (trope_id),
  FOREIGN KEY (book_id) REFERENCES book (book_id),
  UNIQUE (trope_id, book_id)
);
```

- One `createTropeTables(db)` helper, called from `_onCreate` and from `_onUpgrade` (`if (oldVersion < 47)`), same as `createUserListTables`.
- **Seeding** happens only when the table is created, never on later launches, so tropes she deletes don't come back. It runs on fresh installs and on upgrade.
- Backup/restore and Firebase sync copy the whole SQLite file, so the new tables are included automatically. Restoring an older backup runs `_onUpgrade`, which creates and seeds the tables.
- `PRAGMA foreign_keys` is OFF, so child rows must be deleted manually: `deleteBook`, `deleteBundleBooks` and the "update = clear links + re-link" branch of `addBook` also clear `books_by_trope`. Deleting a trope in Manage Dropdowns also deletes its `books_by_trope` rows.

Seed list (30, English, see §7 Q1):

| | | |
|---|---|---|
| Enemies to lovers | Friends to lovers | Slow burn |
| Forced proximity | Fake dating | Second chance |
| Grumpy x sunshine | Love triangle | Forbidden love |
| Only one bed | Marriage of convenience | Found family |
| Chosen one | Morally grey | Villain origin story |
| Redemption arc | Quest | Heist |
| Revenge | Hidden identity | Lost heir |
| Magic academy | Dark academia | Portal fantasy |
| Time travel | Unreliable narrator | Locked-room mystery |
| Small town | Coming of age | Retelling |

### 1.2 Model and repository

- `Book` (`lib/model/book.dart`): new `final String? trope;` (comma-joined, like `genre`), in the constructor, `fromMap`, `toMap` (not written to the `book` table, only used for linking) and `toString`.
- `BookRepository`:
  - `_linkTropes(bookId, tropesStr)`, a copy of `_linkGenres` that uses `_getOrInsertLookupId('trope', 'name', …)`, so new tropes typed in the form are created.
  - Every book query that returns `GROUP_CONCAT(DISTINCT g.name) as genre` (`searchBooks`, `getAllBooks`, `getTBRBooks`, `getStartedBooks`, `getTandemBooks`, `getBooksReadInYear`, `getBundleBooks`, `getBookById`, `getBooksWithEmptyField`, `getBooksWithoutFieldValue`, `getBooksByUniverse`, and the one in `admin_csv_import.dart`) also returns `trope`. This uses a correlated subquery `(SELECT GROUP_CONCAT(t.name, ',') FROM books_by_trope bbt JOIN trope t … WHERE bbt.book_id = b.book_id) AS trope`, so the existing author/genre joins don't multiply rows.
  - `addBook` links tropes after genres. An update clears the old links first, like genres.
  - `getLookupValues('trope')`, `addLookupValue`, `updateLookupValue` and `deleteLookupValue` work for the new table.
- **Preserving tropes in existing flows (part of Phase 0, not Phase 2):** some flows rebuild a `Book` and call `deleteBook` + `addBook`, or `addBook` with an id. If they don't carry `trope`, tropes are silently wiped. Every place that builds a `Book` from another one must pass `trope` through: `edit_book.dart` (3 spots), `add_book.dart`, `admin_csv_import.dart` (6 spots, CSV update keeps the existing tropes), `csv_import_helper.dart`, `settings.dart`, `updateBookWithNewData`, `new_book_detail.dart`.
- **Commas:** tropes are stored comma-joined, like genres. A trope name can't contain a comma, so the chip field and Manage Dropdowns reject it.

### 1.3 Manage Dropdowns (`lib/screens/manage_dropdowns.dart`)

- Add `trope` to the editable tables (label "Tropes"), with add / rename / delete like genres. This is where she edits or deletes the seeded tropes.
- Deleting asks for confirmation and shows how many books use the trope.

### 1.4 Add Book / Edit Book

- New `ChipAutocompleteField` right after Genres: label "Tropes", hint "Search or add a trope", suggestions from `getLookupValues('trope')`, state `_selectedTropes`, saved as `trope: _selectedTropes.join(', ')`.
- Same position in both screens (field-order rule). `EditBookScreen` is one inline `Column` and isn't `dart format`-clean, so it is formatted by hand.
- Add `_selectedTropes` to `AddBookScreen._formSnapshot()` so the unsaved-changes warning sees it.
- Reset on "save and add another", like genres.

### 1.5 Book detail (`new_book_detail.dart`)

- New "Tropes" row right after the Genre row, with the same styling. Tapping it opens a books-by-trope list. This reuses `BooksByGenreScreen`, generalised with a `field` parameter, instead of a copied screen.
- Hidden when the book has no tropes.

### 1.6 Home (`new_home_screen.dart`, `BookProvider`)

- Top-row search, option **"Genre"** (`case 4` in `BookProvider`): matches if the normalized query is in `genre` **or** `trope`. Same accent-insensitive normalization. The label stays "Genre".
- Filter sheet "Genre" dropdown: see §7 Q2.

### 1.7 Localization

EN/ES ARB strings for: Tropes, Search or add a trope, the Manage Dropdowns label and the delete confirmation.

### 1.8 Verification

- Throwaway `flutter test` with an ffi DB: migration 46→47 creates and seeds exactly 30 tropes once (a second open doesn't re-seed, a deleted trope stays deleted); add/edit/delete a book with tropes; existing CSV update keeps tropes; Home genre search finds a book by trope only.
- Add/Edit field order checked by pumping both screens.
- `flutter analyze` and `dart format` on the changed files.

---

## 2. Phase 1: Random, Lists, Statistics

### 2.1 Random
- **Filters** (`new_random_filters_screen.dart`): Tropes include/exclude with AND/OR, like genres (`trope`, `excludedTropes`, `tropeUseAndLogic`), using `NewGenreSelectionScreen` generalised to tropes.
- **Mood search** (`lib/discovery`): new `DiscoveryField.trope` in `searchable_text_builder.dart` with weight ~0.9 (between title and genre). The concept catalog already has `enemies_to_lovers`, `found_family`… so these concepts start matching real trope tags.

### 2.2 Lists
- New `UserListType.trope` ("Tropes"), handled like `genre` in `user_list_repository.dart` (book counts, covers from `books_by_trope`), the list-type picker, the "add items" multi-select and the share card.

### 2.3 Statistics
- Library breakdown (`library_breakdown_screen.dart`): new "Tropes" breakdown (books per trope), like `_computeGenreCounts`.
- Top tropes by average rating (read books only, min. 3 books per trope), in Top rankings. See §7 Q3.

---

## 3. Phase 1.5: Suggest tropes from Hardcover

Hardcover's GraphQL API (`https://api.hardcover.app/v1/graphql`) exposes books with `cached_tags` (community tags grouped by category: genre, mood, content warning, tag), which often include tropes.

From the Hardcover docs:
- A personal API token from Account → Hardcover API, sent as an `authorization` header. Tokens have an expiration you pick, and "we may reset tokens without notice while in beta".
- Free plan: 5,000 requests/day, 60/min, burst 10. Enough for per-book suggestions.
- "Queries are not allowed to run in the browser": the feature is **mobile/desktop only and hidden on web** (the token would be exposed there).

Steps:
1. **Spike first.** She creates a token. I query ~10 of her books and report how many useful tropes Hardcover returns before building the UI.
2. `lib/services/hardcover_service.dart` (uses the existing `http` package): look up by ISBN, else title + author; read `cached_tags`; return tag names.
3. Matching: normalize with `TextNormalizer.normalize` (accents, case, `-`/`_` → space) and compare against her trope list plus a small alias map (e.g. `enemies-to-lovers`, `grumpy/sunshine`).
4. UI: a "Suggest tropes" button next to the Tropes field in Add/Edit Book opens a bottom sheet. Matched tropes are preselected and she confirms. See §7 Q4 for tags that don't match.
5. The token goes through `--dart-define=HARDCOVER_TOKEN=…` (she adds it herself, never committed). The button is hidden when no token is set, on web, or offline. Error SnackBars for 401 (token expired/reset) and 429 (limit).

---

## 4. Phase 2: Import / Export

### 4.1 Before starting: check that no existing import/export breaks
Round-trip checks (throwaway tests + one manual run) for every path, with a library that has tropes:
- Settings full CSV export (`_exportToCsv`) and import (`_importFromCsv`, `csv_import_helper.dart` format detection, import template `_downloadCsvImportTemplate`).
- Admin CSV import (`admin_csv_import.dart`): add, update (deleteBook + re-add), duplicates.
- Admin "Export/Import prices & genres" (`book_fields_csv.dart`, `planBookFieldsUpdate`/`applyBookFieldsUpdate`).
- Backup/restore + Firebase sync (whole DB file).

Each must still work and **must not drop tropes** when the CSV has no Tropes column (old files stay valid).

### 4.2 Add tropes
- Full CSV export/import + template: optional `Tropes` column after `Genre`, comma-separated. A missing column means unchanged. Format detection isn't affected.
- `book_fields_csv.dart`: `Tropes` column after `Genre`. Same rules as genre: match on Book ID only, UPDATE only, empty cell = unchanged, a non-empty cell replaces that book's tropes. New tropes are created.

---

## 5. Files touched (overview)

| Phase | Files |
|---|---|
| 0 | `database_helper.dart`, `book.dart`, `book_repository.dart`, `book_provider.dart`, `add_book.dart`, `edit_book.dart`, `new_book_detail.dart`, `books_by_genre.dart`, `manage_dropdowns.dart`, `new_home_screen.dart`, `admin_csv_import.dart`, `csv_import_helper.dart`, `settings.dart`, ARB files |
| 1 | `new_random_filters_screen.dart`, `new_genre_selection_screen.dart`, `searchable_text_builder.dart`, `user_list.dart`, `user_list_repository.dart`, list screens, `library_breakdown_screen.dart`, `top_rankings_screen.dart`, `statistics_calculator.dart` |
| 1.5 | `hardcover_service.dart` (new), `add_book.dart`, `edit_book.dart`, new suggestion bottom sheet widget |
| 2 | `settings.dart`, `csv_import_helper.dart`, `admin_csv_import.dart`, `book_fields_csv.dart`, `book_repository.dart` |

One PR per phase.

---

## 6. Out of scope (for now)
- Trope descriptions or emoji per trope.
- Spoiler tropes / hiding tropes.
- Bilingual trope names (tropes are user data, like genres).

---

## 7. Open questions

1. **Seed language:** the 30 seeded tropes in English (the usual names on BookTok/Goodreads), or in Spanish?
2. **Home filter sheet:** "genres and tropes in the same top-row filter under genre" is planned for the top-row search. Should the Genre dropdown in the filter sheet also list tropes (e.g. a "Tropes" section below the genres), or stay genres only?
3. **Stats (Phase 1):** are "books per trope" + "top tropes by average rating" right, or do you want something else (e.g. tropes per year, a trope column in the seasonal card)?
4. **Hardcover tags that don't match your tropes (Phase 1.5):** ignore them, or show them unchecked under "New tropes" so you can add them to your list in one tap?
5. **Hardcover bulk (Phase 1.5):** besides the per-book button, do you want an admin tool "Suggest tropes for all books without tropes" (reviewed book by book, ~60 books/min)?

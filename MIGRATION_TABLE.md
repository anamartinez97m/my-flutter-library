# Migration Tracker

Items that have **not** been migrated to v2 yet.

## Screens

* `fill_empty_wizard_screen`
  * Used in `settings` screen. It bulk-fills empty metadata fields (genre, format, language, place, editorial, format saga) on books grouped by author/saga.
* `get_started_screen`
  * Used in `main.dart`. It shows the onboarding tutorial for first-time users before navigating to the main navigation screen.
* `reverse_assign_screen`
  * Used in `settings` screen. It reverse-assigns a selected field value to a chosen set of books.
* `smart_suggestions_screen`
  * Used in `settings` screen. It generates and applies smart suggestions for missing book metadata.
* `statistics_section_screen`
  * Used in `statistics` screen. It is a generic carousel screen that displays a list of stat cards as swipeable pages with a dot indicator.

## Modals / Dialogs

* `goodreads_import_dialog`
  * Not used anywhere. It was a dialog for importing books from Goodreads either in full or filtered by a tag.
* `quick_add_book_dialog`
  * Used in `books_by_saga` screen. It lets the user quickly search existing books and add them to the current saga or universe.
* `status_mapping_dialog`
  * Used in `settings` screen (CSV import flow). It maps the user's custom CSV status values to the app's predefined statuses.

## Components / Widgets

* `autocomplete_text_field`
  * Used in `add_book` and `edit_book` screens. Generic autocomplete text input for saga and saga-universe fields.
* `book_clubs_card`
  * Used in the old `book_detail` screen. It displays the reading clubs associated with a book.
* `booklist`
  * Used in the old `home` screen. It renders the list of books with configurable card fields.
* `bundle_read_dates_widget`
  * Not used anywhere. It manages read dates for each individual book within a bundle.
* `chip_autocomplete_field`
  * Used in `add_book`, `edit_book`, `random`, and `new_random` screens. Autocomplete input that renders selected values as removable chips.
* `heart_rating_input`
  * Used in `add_book` and `edit_book` screens. Heart-icon rating input widget.
* `random_shimmer`
  * Used in `new_random` screen. Shimmer loading placeholder for the random book picker.

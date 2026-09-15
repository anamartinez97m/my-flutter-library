# Migration Progress

> Tracker for removing v1 code. An item is **complete** when the v2 replacement exists **and** the old v1 file/code paths are gone.

## At a glance

| Status | Count |
|---|---|
| ✅ Done | 27 |
| 🟡 Partial | 12 |
| ❌ Not started | 21 |
| **Total** | **60** |

## Legend

| Icon | Meaning |
|---|---|
| ✅ | v2 exists and the v1 file/code paths have already been removed (or there was never a v1 counterpart). |
| 🟡 | v2 implementation exists in the same file via `useNewUi`, but the old v1 code paths are still present. |
| ❌ | v1 still exists and no v2 replacement has been built yet, or the v2 replacement exists but the old v1 file still remains. |

---

## Screens

### ❌ Not started

| v2 Replacement | v1 To Remove |
|---|---|
| `new_ui/new_book_competition_screen` | `book_competition_screen` |
| `new_ui/new_monthly_winner_selection_screen` | `monthly_winner_selection_screen` |
| `new_ui/new_my_books_screen` | `my_books` |
| `new_ui/new_quarterly_winner_selection_screen` | `quarterly_winner_selection_screen` |
| `new_ui/new_random_screen` | `random` |
| — | `reverse_assign_screen` |
| `new_ui/new_saga_completion_detail_screen` | `saga_completion_detail` |
| `new_ui/new_semifinal_winner_selection_screen` | `semifinal_winner_selection_screen` |
| — | `smart_suggestions_screen` |
| — | `statistics_section_screen` |
| `new_ui/new_year_challenges_screen_2` | `year_challenges` |
| `new_ui/new_yearly_winner_selection_screen` | `yearly_winner_selection_screen` |

### 🟡 Partial

| v2 Replacement | v1 To Remove |
|---|---|
| `add_book` (`useNewUi`) | `add_book` old code paths |
| `admin_csv_import` (`useNewUi`) | `admin_csv_import` old code paths |
| `books_by_author` (`useNewUi`) | `books_by_author` old code paths |
| `manage_club_names` (`useNewUi`) | `manage_club_names` old code paths |
| `manage_dropdowns` (`useNewUi`) | `manage_dropdowns` old code paths |
| `manage_rating_fields` (`useNewUi`) | `manage_rating_fields` old code paths |
| `settings` (`useNewUi`) | `settings` old code paths |
| `statistics` (`useNewUi`) | `statistics` old code paths |
| `tutorial_screen` (`useNewUi`) | `tutorial_screen` old code paths |

### ✅ Done

| v2 Replacement | v1 To Remove |
|---|---|
| `books_by_decade` | — |
| `books_by_editorial` | — |
| `books_by_genre` | — |
| `books_by_saga` | — |
| `books_by_year` | — |
| `library_breakdown_screen` | — |
| `price_statistics_screen` | — |
| `ratings_pages_screen` | — |
| `reading_activity_screen` | — |
| `reading_patterns_screen` | — |
| `rereads_detail` | — |
| `sagas_series_screen` | — |
| `top_rankings_screen` | — |
| `new_ui/new_book_detail` | `book_detail` |
| `new_ui/new_genre_selection_screen` | — |
| `new_ui/new_home_screen` | `home` |
| `new_ui/new_navigation_screen` | `navigation` |
| `new_ui/new_option_selection_screen` | — |
| `new_ui/new_past_years_competition_screen` | — |
| `new_ui/reading_sessions_screen` | — |
| `new_ui/universe_reading_order_screen` | — |

---

## Modals / Dialogs

### ❌ Not started

| v2 Replacement | v1 To Remove |
|---|---|
| — | `goodreads_import_dialog` |
| — | `quick_add_book_dialog` |
| — | `status_mapping_dialog` |

### ✅ Done

| v2 Replacement | v1 To Remove |
|---|---|
| `reading_club_dialog` | — |
| `log_reading_session_sheet` | — |

---

## Components / Widgets

### ❌ Not started

| v2 Replacement | v1 To Remove |
|---|---|
| `bundle_input_widget_v2` | `bundle_input_widget` |
| — | `autocomplete_text_field` |
| — | `bundle_read_dates_widget` |
| — | `chip_autocomplete_field` |
| — | `heart_rating_input` |
| — | `random_shimmer` |

### 🟡 Partial

| v2 Replacement | v1 To Remove |
|---|---|
| `read_dates_widget` (`useNewUi`) | `read_dates_widget` old code paths |
| `chronometer_widget` (`useNewUi`) | `chronometer_widget` old code paths |
| `tbr_limit_setting` (`useNewUi`) | `tbr_limit_setting` old code paths |

### ✅ Done

| v2 Replacement | v1 To Remove |
|---|---|
| `book_card_v2` | — |
| `shimmer_loading` | — |

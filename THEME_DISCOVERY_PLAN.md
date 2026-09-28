# Theme & Semantic Book Discovery — Implementation Plan

> Source: feature spec posted in `#devin-my-book-vault` (5 messages, sections 1–17).
> Scope: **Phase 1** (local, deterministic keyword/concept matching) fully implemented, plus clean extension points for **Phase 2** (semantic/embedding matching). No code has been written yet — this document is the plan.

---

## 0. Summary

Add a "What are you in the mood for?" discovery screen that takes free text (e.g. `Halloween`, `romance with witches`, `dark fantasy with vampires`) and returns ranked books **from the user's existing library only**, each with a relevance % and the concepts that explain the match.

Pipeline:

```
DiscoveryQuery (raw text)
      ↓
BookDiscoveryService          (orchestrates matchers, merges + ranks)
      ↓
BookMatcher (interface)
  ├── KeywordBookMatcher      (Phase 1)
  └── SemanticBookMatcher     (Phase 2 — stub/extension point only)
      ↓
DiscoveryResult { book, relevance 0..1, matchedConcepts, reasons }
      ↓
Theme discovery card (top of NewRandomScreen) → existing BookCardV2 + small relevance/concept row
```

The UI only ever sees `DiscoveryResult` — it never knows which matcher produced it.

---

## 1. Existing architecture (what we reuse)

| Concern | Existing component | How it's reused |
|---|---|---|
| Book data | `lib/model/book.dart` (`Book`) | Matched directly. No new book model, no duplicated data. Fields used: `name`, `author`, `description`, `genre` (comma-joined via `GROUP_CONCAT` in `BookRepository`), `saga`, `sagaUniverse`, `bundleTitles`, `notes`/`myReview` (optional, low weight). |
| Book loading | `BookProvider.allBooks` (`lib/providers/book_provider.dart`) | Source of the book list; already loaded in memory by `loadBooks()`. No new queries. |
| State management | `provider` / `ChangeNotifier` | Screen uses local `State` + the service; no new state-management package. |
| Pure-Dart engines | `lib/helpers/suggestion_engine.dart` (`SuggestionEngine`) | Precedent for a Flutter-free, testable engine over `List<Book>`. Discovery engine follows the same style. |
| Book UI | `lib/widgets/book_card_v2.dart` (`BookCardV2`) | Renders cover/title/author/saga. We add a small match footer (relevance + concept chips) around it, not inside it. |
| Design tokens | `_kPrimary`, `_kText`, `_kBorder`, `_kDivider` (v2 tokens), `lib/config/app_theme.dart`, Manrope font | Same palette/typography/spacing as other `new_ui` screens. |
| Entry point | `lib/screens/new_ui/new_random_screen.dart` (`NewRandomScreen`) | New card placed **above `_buildSelectBooksCard`** in `build()`, reusing the screen's card styling (`_kCardBg`, `_kCardBorder`, `_kCardShadow`, 40px circular icon header like the Select Books card). **New UI only** — the v1 `random` screen is not touched. No new bottom-nav tab, no Home screen changes. |
| Localization | `lib/l10n/app_en.arb`, `app_es.arb` | All new UI strings added to both ARB files. |
| Database | `DatabaseHelper` / sqflite | **Not touched in Phase 1.** Everything is derived in memory. |

No new dependencies are needed (`dart:async` `Timer` for debounce; diacritic folding done with a small in-house map, not a package).

---

## 2. Proposed files

New feature module (kept self-contained so the matcher can be swapped later):

```
lib/discovery/
  model/
    discovery_query.dart          # DiscoveryQuery (raw text + normalized tokens/phrases)
    discovery_result.dart         # DiscoveryResult, ConceptMatch, MatchReason, MatchField
    theme_concept.dart            # ThemeConcept (id, displayName, emoji/icon, category, keywords, aliases, relatedConceptIds, negativeKeywords)
  catalog/
    concept_catalog.dart          # ConceptCatalog: loads/validates/indexes concepts (keyword → concept lookup, related graph)
    concept_catalog_data.dart     # the curated concept list (pure data, no logic)
  matching/
    book_matcher.dart             # abstract BookMatcher { Future<List<BookMatch>> match(DiscoveryQuery, BookIndex) }
    keyword_book_matcher.dart     # Phase 1 implementation
    semantic_book_matcher.dart    # Phase 2 placeholder (interface-only / not registered)
  index/
    searchable_book.dart          # SearchableBook: cached normalized fields per book
    book_index.dart               # BookIndex: builds/caches SearchableBook list, invalidates on library change
    searchable_text_builder.dart  # builds the text blob per book (reused by Phase 2 embeddings)
  text/
    text_normalizer.dart          # lowercase, diacritics, punctuation, whitespace, simple singular/plural stemming
  book_discovery_service.dart     # orchestrates matchers, merges scores, ranks, thresholds

lib/widgets/theme_discovery_card.dart            # the card shown at the top of NewRandomScreen (search field + results)
lib/widgets/discovery_result_card.dart           # BookCardV2 + relevance + concept chips + "why this matches"

test/discovery/
  text_normalizer_test.dart
  concept_catalog_test.dart
  keyword_book_matcher_test.dart
  book_discovery_service_test.dart
```

Modified files (minimal):
- `lib/screens/new_ui/new_random_screen.dart` — insert `ThemeDiscoveryCard` + `SizedBox(height: 16)` above `_buildSelectBooksCard(l10n)` (plus any wiring decided in §15 Q2).
- `lib/l10n/app_en.arb`, `lib/l10n/app_es.arb` (+ regenerated `app_localizations*.dart` via `flutter gen-l10n`) — new strings.

Nothing else is modified. No DB migration.

> Naming follows project conventions (snake_case files, `new_ui/` for v2 screens, `*_screen.dart`, `*V2` widgets). If the reviewer prefers, `lib/discovery/` can live under `lib/helpers/discovery/` next to `suggestion_engine.dart`.

---

## 3. Concept catalog

### 3.1 Representation

```dart
class ThemeConcept {
  final String id;                    // 'halloween', 'dark_academia'
  final String displayName;           // 'Halloween'
  final String? emoji;                // '🎃' — shown in chips, comes from data, not UI
  final String category;              // 'seasonal', 'supernatural', 'fantasy', ...
  final List<String> keywords;        // strong direct signals
  final List<String> aliases;         // alternate names for the concept itself ('romcom', 'rom-com')
  final List<String> relatedConceptIds;
  final List<String> negativeKeywords; // optional, e.g. for 'something spooky but NOT horror'
}
```

- Stored as **pure data** in `concept_catalog_data.dart` (a `const List<ThemeConcept>`). The matcher never references a concept by id — it only consumes `ConceptCatalog` generically.
- Kept in Dart rather than a JSON asset so tests don't need the asset bundle and it's compile-time checked. The `ConceptCatalog` constructor takes a `List<ThemeConcept>`, so swapping to a JSON asset (or a remote/user-editable catalog) later is a one-line change.
- `ConceptCatalog` builds, once:
  - `Map<String normalizedPhrase, Set<conceptId>>` for keywords + aliases + displayName,
  - the related-concept adjacency map,
  - normalized/stemmed forms of every keyword (cached; see §7).

### 3.2 Initial concepts (from the spec)

| Category | Concepts |
|---|---|
| Seasonal & Holiday | Halloween, Christmas, Autumn, Winter, Summer, Spring |
| Supernatural & Paranormal | Witches, Vampires, Werewolves, Ghosts, Demons, Angels, Supernatural |
| Fantasy & Magic | Fantasy, Epic Fantasy, Urban Fantasy, Magic, Dragons, Fae |
| Romance | Romance, Romantic Comedy, Dark Romance, Fantasy Romance, Enemies to Lovers, Friends to Lovers |
| Mystery & Thriller | Mystery, Thriller, Psychological Thriller, Crime, Serial Killer |
| Science Fiction | Science Fiction, Space, Aliens, Dystopian, Post-Apocalyptic, Cyberpunk |
| Historical & Period | Historical, Historical Romance, Medieval, Victorian |
| Adventure & Action | Adventure, Action, Survival, Pirates |
| Cozy & Atmosphere | Cozy, Small Town, Found Family, Dark Academia |
| Social & Character | Friendship, Coming of Age, Family, Political Intrigue, War |
| Mythology | Mythology, Greek Mythology, Norse Mythology |

Keywords and related lists are copied verbatim from the spec.

### 3.3 Unresolved related references (decision needed)

The spec's "Related" lists reference names that are **not** defined as concepts. These must be resolved so the related-concept graph is consistent:

| Referenced name | Proposed resolution |
|---|---|
| paranormal | alias of **Supernatural** |
| suspense | alias of **Thriller** |
| detective | keyword only (already in Mystery/Crime) — drop as related id, link to **Mystery** |
| contemporary romance | alias of **Romance** (or new light concept) |
| horror, occult, dark fantasy, gothic, contemporary, psychological horror | **add as new concepts** (small keyword lists) — they appear frequently and are central to queries like "spooky", "dark fantasy with vampires" |
| travel, nature, technology, artificial intelligence, space opera, vikings, ancient world, royalty, relationships, politics, workplace, psychological, dark | add as **lightweight concepts** (displayName + a few keywords) so they can participate in related scoring |

A `concept_catalog_test.dart` test asserts every `relatedConceptId` resolves to a concept, so the catalog can't silently drift.

Default in the implementation: follow the table above unless told otherwise.

### 3.4 Localization of concepts

The app ships English + Spanish. Phase 1: concept `displayName` stays in the catalog (English), with an optional `displayNameEs` / keyword list per locale added later. Spanish keywords (e.g. `bruja`, `vampiro`, `navidad`) can be appended to `keywords` now at no cost since matching is language-agnostic after normalization. **Open question:** include Spanish keywords in Phase 1?

---

## 4. Text normalization (`TextNormalizer`)

Applied identically to query, book fields and catalog keywords:

1. Lowercase.
2. Diacritic folding (`á→a`, `ñ→n`, `ç→c`, `ü→u`, …) via a static map.
3. Punctuation → space; hyphens treated as spaces (`rom-com` ≡ `rom com`, `enemies-to-lovers` ≡ `enemies to lovers`). Apostrophes removed (`valentine's` → `valentines`).
4. Collapse whitespace.
5. Tokenize; light stemming for plurals: `-ies→-y`, `-ves→-f`/`-fe` (`werewolves→werewolf`), `-es`/`-s` (guarded: min length, not `-ss`). Both surface and stemmed forms are kept.
6. Phrase matching on token boundaries (so `war` doesn't match `warrior`, `ice` doesn't match `police`).
7. Stop words (`a`, `with`, `but`, `something`, `books`, `for`, `the`, `not`, …) dropped from **free-text** query terms, but `not`/`no`/`without` are detected first to build negations.

---

## 5. Query interpretation (`DiscoveryQuery`)

The query is always free text, never assumed to be a concept id.

```
"something spooky but not horror"
  → normalized: "something spooky but not horror"
  → directConcepts:   {halloween}           (via keyword 'spooky')
  → negatedConcepts:  {horror}              (term after 'not'/'but not'/'without')
  → freeTerms:        {spooky}              (residual tokens for raw text matching)
```

Steps:
1. Normalize.
2. Longest-phrase-first scan of the catalog phrase index (`dark academia` before `dark`, `fantasy romance` before `fantasy`).
3. Each hit → **direct query concept** (weight 1.0).
4. For each direct concept, expand `relatedConceptIds` one hop → **related query concepts** (weight ≈ 0.4). Not transitive (prevents `halloween → witches → magic → fantasy` from reaching every book).
5. Negation window (`not X`, `but not X`, `without X`, `no X`) → `negatedConcepts` / negated terms.
6. Remaining non-stop-word tokens → `freeTerms`, matched literally against book fields (so unknown words like an author or saga name still work).

Multi-concept queries (`romance with witches`) produce multiple direct concepts; books matching more of them rank higher (see §6.3).

---

## 6. Matching & relevance

### 6.1 Per-book searchable fields (cached)

| Field | Source | Weight |
|---|---|---|
| title | `name`, `bundleTitles` | **1.00** (strongest) |
| genre | `genre` (split on `,`) | **0.85** (strong) |
| saga / universe | `saga`, `sagaUniverse` | 0.70 |
| description | `description` | **0.55** (medium) |
| author | `author` | **0.25** (weak) |
| notes/review | `notes`, `myReview` | 0.20 (optional) |

### 6.2 Signal types

| Signal | Multiplier |
|---|---|
| Direct concept hit (a keyword/alias of a direct query concept found in a field) | ×1.0 |
| Free-term hit (literal query word in a field) | ×0.9 |
| Related concept hit (keyword of a *related* concept found in a field) | ×0.4 |

Contribution of one hit = `fieldWeight × signalMultiplier`.

This gives the required ordering:

```
direct title (1.00) > direct genre (0.85) > direct description (0.55) > related genre (0.34) > related description (0.22)
```

### 6.3 Aggregating per book

For each query concept (and each free term), take the **max** contribution across fields (avoids a book with "witch" 12× in the description dominating), plus a small diminishing bonus for additional distinct fields (`+0.1 × second-best`, capped).

```
conceptScore(c) = max_field(contrib) + 0.1 × secondBest(contrib)
rawScore        = Σ_directConcepts conceptScore
                + Σ_relatedConcepts conceptScore   (already down-weighted)
                + Σ_freeTerms termScore
coverage        = (#direct concepts matched) / (#direct concepts in query)
```

- **Negation**: if a book matches a negated concept directly in genre/title, it is excluded; in description, it is heavily penalized (×0.3). Negative keywords in the catalog work the same way at concept level.
- **Related-only guard**: a book that matches *only* related concepts (no direct hit, no free-term hit) is capped at a low ceiling (e.g. 0.45) — this implements "Fantasy ≠ Halloween", "Winter ≠ Christmas", "Historical ≠ Medieval": relationships influence relevance but never guarantee a strong match.

### 6.4 Normalization to 0..1 (UI %)

```
ideal       = Σ over direct query concepts of 1.0 (title weight)  (+ free terms)
relevance   = clamp( (rawScore / ideal) × (0.6 + 0.4 × coverage), 0, 1 )
```

- Score is **relative to the query**, not to other books → stable %, not a "rating".
- Minimum threshold (e.g. `< 0.15`) → dropped; `0.15–0.35` → shown in a collapsed "Loosely related" group (see §9 edge cases).
- Ties broken by: coverage ↓, number of distinct matched concepts ↓, title A→Z.

### 6.5 Explanation ("why this matched")

Every hit records a `MatchReason { conceptId?, term, field, isRelated }`. `DiscoveryResult` exposes:

```dart
class DiscoveryResult {
  final Book book;
  final double relevance;                 // 0..1 → UI shows 92%
  final List<ConceptMatch> matchedConcepts; // ordered by contribution; concept + isDirect
  final List<MatchReason> reasons;          // e.g. (witches, 'witch', description)
}
```

The UI renders chips from `matchedConcepts` (emoji + displayName from the catalog), and a short line from the top 1–2 `reasons`, e.g. *"'witch' in description · Fantasy genre"*. Nothing is hard-coded in the book UI.

---

## 7. Performance

- **BookIndex**: builds `SearchableBook` (normalized + tokenized + stemmed fields) once per library load; rebuilt only when `BookProvider` notifies with a changed list (compare length + max `bookId`/hash, or rebuild lazily on next query).
- **ConceptCatalog**: normalized phrase index built once (lazy singleton).
- Per-query cost: O(books × query-concepts × fields) with pre-tokenized sets — fine for thousands of books.
- **Debounce** input by ~300 ms in the screen; skip queries shorter than 2 chars.
- Run the match inside `compute()` / isolate **only if** profiling shows jank with large libraries (not by default — keeps it simple).
- Bundle children (`bundleParentId != null`) excluded by default, as in `SuggestionEngine`; placeholders (`isPlaceholder`) excluded.

---

## 8. UI (`ThemeDiscoveryCard` on `NewRandomScreen`)

- Location: top of the new-UI Random screen, directly above the **Select Books** card. v1 UI unchanged.
- Card header mirrors `_buildSelectBooksCard`: 40px `_kPrimary` circle icon (e.g. `Icons.auto_awesome`), 20px title, 14px subtitle, divider.
- Follows `new_ui` v2 look (tokens, Manrope, card borders, shadows of `NewRandomScreen`).
- **Search area**: prominent `TextField` — label *"What are you in the mood for?"*, hint *"Halloween, witches, cozy autumn…"*; clear button.
- **Suggestion chips** under the field when empty: a few catalog concepts (Halloween, Cozy, Dark Academia, Romantasy…) pulled from the catalog, tapping fills the query.
- **Results**: rendered inside the card (non-scrolling `Column`, since the Random screen is already a `SingleChildScrollView`), top N shown with "Show more" — or in a pushed full screen, depending on §15 Q1. Each item is a `DiscoveryResultCard` = existing `BookCardV2` (cover, title, author, saga/universe) + footer row:
  - subtle relevance indicator: `92% match` text + thin bar (explicitly *not* stars/hearts, to avoid looking like a rating),
  - matched-concept chips (`🧙 Witches  🔮 Magic  🌙 Paranormal  🎃 Halloween`),
  - optional one-line "Why this matches".
- Tapping a result opens the existing book detail (`new_book_detail.dart`) exactly as `BookCardV2` does today (pending §15 Q7).
- Optional integration with the random picker (pending §15 Q2).
- Not a chatbot: single input, list of books, no conversation history.

---

## 9. Edge cases

| Case | Handling |
|---|---|
| Empty query | Show suggestion chips + helper text; no search run. |
| Very short query (<2 chars) | No search; helper text. |
| No matches | Empty state: "No books in your library match *X*" + suggestion chips. |
| Very low relevance | Below threshold hidden; low band grouped under "Loosely related" (collapsed). |
| Missing description / genre / author | Null-safe `SearchableBook` (empty token sets); never throws. |
| Duplicate keywords (in catalog or across concepts) | Catalog index is a `Set`; hits deduped per (concept, field). |
| Capitalization / accents / punctuation | `TextNormalizer` (§4). |
| Singular/plural | Stemming (§4) on both sides. |
| Multiple matching concepts | All recorded; chips ordered by contribution. |

---

## 10. Phase 2 — semantic extension points (not implemented)

- `BookMatcher` interface is the only contract `BookDiscoveryService` depends on. It returns per-book raw scores + reasons; the service normalizes/merges.
- `BookDiscoveryService(matchers: [KeywordBookMatcher(...)])` — adding `SemanticBookMatcher` later is a constructor change; merging uses weighted max/blend per book.
- `SearchableTextBuilder.build(Book)` already produces the canonical text (title, author, description, genres, saga, universe) that a future embedding step would consume:
  ```
  Book → SearchableTextBuilder → text → Embedder → vector → (cache) → cosine vs query vector
  ```
- `semantic_book_matcher.dart` contains only the class skeleton + an `Embedder` abstract interface; it is **not registered** and adds no dependency.
- Future persistence (if embeddings are ever cached) would be a new table in the existing sqflite DB via `DatabaseHelper` migrations — explicitly out of scope now.
- `MatchReason` has a `source` enum (`keyword`, `semantic`) kept internal; the UI never displays it.

---

## 11. Database

- No schema changes, no new tables, no second database.
- All derived data (normalized text, token sets) lives in memory in `BookIndex` and is recomputed from existing `Book` objects.

---

## 12. Testing

Pure Dart unit tests (no widgets) under `test/discovery/`, using small in-memory `Book` fixtures. Mapped to the spec's required list:

| # | Test | File |
|---|---|---|
| 1 | Exact title match ranks first | `keyword_book_matcher_test.dart` |
| 2 | Genre match | " |
| 3 | Description match | " |
| 4 | Direct concept match (`spooky` → Halloween) | " |
| 5 | Related concept match scores lower than direct | " |
| 6 | Case-insensitive | `text_normalizer_test.dart` + matcher |
| 7 | Accent/diacritic normalization (`Brujería` ≡ `brujeria`) | " |
| 8 | Singular/plural (`witch`/`witches`, `werewolf`/`werewolves`) | " |
| 9 | Missing metadata (null description/genre/author) doesn't crash | matcher |
| 10 | No matches → empty list | service |
| 11 | Multiple matching concepts exposed | matcher |
| 12 | Ranking by relevance (title > genre > description > related) | service |
| 13 | Multi-concept query (`romance with witches`) prefers books matching both | service |
| 14 | Match via metadata, not title | matcher |
| 15 | Halloween matches a witch book | service |
| 16 | Halloween does **not** strongly match a generic fantasy book (below threshold / capped) | service |
| 17 | Winter does **not** automatically match every Christmas book | service |
| 18 | Dark Academia matches via `university` / `secret society` in description | service |
| 19 | Results expose responsible concepts + reasons | service |
| + | Catalog integrity: every `relatedConceptId` resolves; no empty keyword lists | `concept_catalog_test.dart` |
| + | Negation: `spooky but not horror` excludes horror-genre books | service |
| + | Word-boundary: `war` doesn't match `warrior`, `ice` not in `police` | normalizer/matcher |

Commands:

```
/home/ubuntu/flutter/bin/flutter test test/discovery
/home/ubuntu/flutter/bin/dart format --output=none --set-exit-if-changed lib/discovery lib/screens/new_ui/theme_discovery_screen.dart lib/widgets/discovery_result_card.dart test/discovery
/home/ubuntu/flutter/bin/flutter analyze --no-fatal-infos lib/discovery lib/screens/new_ui/theme_discovery_screen.dart lib/widgets/discovery_result_card.dart
```

Full `flutter test` run before finishing to confirm no regressions (note: `test/widget_test.dart` smoke test already fails on `main` because `MyApp` is missing `ThemeProvider` — pre-existing, unrelated).

---

## 13. Implementation order

1. `TextNormalizer` + tests.
2. `ThemeConcept`, `concept_catalog_data.dart` (all concepts from §3.2 + resolutions from §3.3), `ConceptCatalog` + integrity test.
3. `SearchableBook`, `SearchableTextBuilder`, `BookIndex`.
4. `DiscoveryQuery` parsing (phrases, related expansion, negation, free terms).
5. `BookMatcher` interface, `KeywordBookMatcher`, scoring (§6).
6. `BookDiscoveryService` (merge, normalize, threshold, rank) + full test matrix (§12).
7. `semantic_book_matcher.dart` skeleton + `Embedder` interface (unregistered).
8. l10n strings (en + es), `flutter gen-l10n`.
9. `DiscoveryResultCard` (wraps `BookCardV2`) and `ThemeDiscoveryCard` (debounce, empty/no-results states).
10. Insert the card at the top of `NewRandomScreen` (above Select Books) + random-picker wiring per §15 Q2.
11. Format, analyze, full test run; manual check on device/emulator.
12. PR with the deliverables write-up required by §17 of the spec (architecture, reused components, catalog, matching, weighting, relevance, UI exposure, embedding path, file list, test results, confirmation existing features unchanged).

---

## 14. Explicit non-goals (from spec §16)

No chatbot UI · no external AI/API calls · no Google Books/OpenLibrary fetching · no duplicate `Book` model · no parallel DB · no unrelated feature changes or redesign · no new state-management library · no Halloween-specific (or any concept-specific) logic in the engine · relevance never shown as a quality rating · embeddings never exposed to the user.

---

## 15. Decisions & open questions

### Decided

- **Placement:** top of the new-UI Random screen (`NewRandomScreen`), above the *Select Books* card. **New UI only** (for now). No Home screen or v1 changes.

### Open (asked in Slack)

1. **Presentation:** results shown inline inside the card on the Random screen, or the card is a compact search field that opens a dedicated results screen?
2. **Random-picker integration:** discovery only, or add a "Pick a random book from these results" action / let results feed the *Select Books* custom list?
3. **Random screen filters:** should discovery results respect the Random screen's filters (format, language, genre, status/place, TBR, pages, decade, author, avoid), or search the whole library independently?
4. **Statuses:** include all books (read, reading, TBR, TBReleased…), or only unread/TBR?
5. **Unresolved related concepts** (§3.3): accept the proposal (aliases + add horror/occult/dark fantasy/gothic/contemporary/psychological horror + lightweight stubs), or only aliases and drop the rest?
6. **Spanish keywords** in the Phase 1 catalog (bruja, vampiro, navidad…)?
7. **Tap on a result:** open book detail, or add it to *Select Books*?
8. **Relevance display:** percentage (`92% match`), subtle bar only, or both?
9. **Concept chip icons:** emoji (🎃🧙) or Material icons?
10. **Low-relevance results:** collapsed "Loosely related" group, or hidden?
11. **Notes/reviews:** include the user's own `notes` / `myReview` in matching (low weight)?

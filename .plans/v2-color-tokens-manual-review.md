# V2 Color Tokens — Manual Review

> Generated after rebasing `feat/v2-design-system-centralization` onto `main`.
> The branch still contains **355 hardcoded `Color(0x…)` usages**. Most are intentional exceptions, but the ones below should be reviewed manually.

## 1. Clear candidates — map to existing V2 tokens

These colors have obvious `V2Colors` equivalents and should be replaced.

| Hardcoded value | V2 token | Where it appears |
|---|---|---|
| `Color(0xFFB3261E)` | `V2Colors.error` | `lib/screens/manage_club_names.dart`, `lib/screens/manage_dropdowns.dart`, `lib/screens/manage_rating_fields.dart`, `lib/screens/new_ui/reading_sessions_screen.dart`, `lib/screens/new_ui/universe_reading_order_screen.dart` |
| `Color(0xFF8B1A1A)` | `V2Colors.error` | `lib/widgets/chronometer_widget.dart` |
| `Color(0xFF34D399)` | `V2Colors.success` | `lib/screens/new_ui/new_year_challenges_screen_2.dart` |
| `Color(0xFF047857)` | `V2Colors.success` (dark) or keep as variant | `lib/screens/new_ui/new_year_challenges_screen_2.dart` |
| `Color(0xFF6EE7B7)` | `V2Colors.successBackground` / `successBorder` | `lib/screens/new_ui/new_year_challenges_screen_2.dart` |
| `Color(0xFF065F46)` | `V2Colors.success` (dark) | `lib/screens/new_ui/new_year_challenges_screen_2.dart` |
| `Color(0xFF064E3B)` | `V2Colors.success` (dark) | `lib/screens/new_ui/new_year_challenges_screen_2.dart` |
| `Color(0xFFD1FAE5)` | `V2Colors.successBackground` | `lib/screens/new_ui/new_year_challenges_screen_2.dart` |
| `Color(0xFF8A5A22)` | `V2Colors.warning` | `lib/screens/smart_suggestions_screen.dart` |
| `Color(0xFFA13A3A)` | `V2Colors.error` (or warning variant) | `lib/screens/smart_suggestions_screen.dart` |

## 2. Near-miss colors — decide if they should alias existing tokens

These are very close to existing `V2Colors` values. Review whether to unify them or keep the precise rendered value.

| Hardcoded | Near V2 token | File |
|---|---|---|
| `0xFF76666D` | `textMuted` / `textMutedAlt` | `lib/screens/new_ui/new_year_challenges_screen_2.dart` |
| `0xFFE8DED8` | `borderSoft` | `lib/screens/new_ui/new_year_challenges_screen_2.dart` |
| `0xFFEDE6E1` | `divider` / `chip` | `lib/screens/new_ui/new_year_challenges_screen_2.dart` |
| `0xFFF9F1F4` | `surfaceWarm` / `surfaceAlt` | `lib/screens/new_ui/new_year_challenges_screen_2.dart` |
| `0xFFF7F1ED` | `surfaceWarm` / `surfaceAlt` | `lib/screens/new_ui/new_year_challenges_screen_2.dart` |
| `0xFFF5F3F2` | `surfaceMuted` (exact) | `lib/widgets/book_card_v2.dart` |
| `0xFFF7F3F0` | `surfaceTimer` (exact) | `lib/screens/new_ui/new_my_books_screen.dart` |

## 3. Add new tokens or keep as documented exceptions

These are decorative/semantic colors with no current `V2Colors` equivalent. Either add tokens or leave as inline exceptions.

| Color / palette | Context | Files |
|---|---|---|
| `0xFFBC92A6` (tertiary accent) | Stats efficiency cards; already commented as `// Not represented in V2Colors.` | `lib/widgets/statistics/reading_efficiency_*.dart`, `lib/screens/top_rankings_screen.dart`, `lib/screens/reading_patterns_screen.dart`, `lib/screens/reading_activity_screen.dart`, `lib/screens/ratings_pages_screen.dart`, `lib/screens/price_statistics_screen.dart`, `lib/screens/library_breakdown_screen.dart`, `lib/screens/books_by_year.dart`, `lib/screens/books_by_decade.dart` |
| `0xFF8B4A3C`, `0xFFFFF0EC`, `0xFFE3A99C` | Avoid/exclusion palette in random filters | `lib/screens/new_ui/new_random_filters_screen.dart` |
| `0xFFD4A017`, `0xFFC98A2C` | Medal/gold colors | `lib/screens/new_ui/new_yearly_winner_selection_screen.dart`, `lib/screens/new_ui/new_past_years_competition_screen.dart`, `lib/screens/new_ui/new_book_competition_screen.dart` |
| Rich custom palettes | Gradients, lavenders, deep burgundies, competition-specific accents | `lib/screens/new_ui/new_book_competition_screen.dart`, `lib/screens/new_ui/new_past_years_competition_screen.dart`, `lib/screens/new_ui/universe_reading_order_screen.dart` |
| `0xFFFFF4E5`, `0xFFE7B86B`, `0xFF8A5700`, `0xFF6B4608` | Warning/notification palette in placeholders screen | `lib/screens/settings/universe_placeholders_screen.dart` |

## 4. Keep as-is

These are intentionally unmapped per the centralization commit and should generally not be touched.

| Pattern | Reason | Examples |
|---|---|---|
| Black-alpha drop shadows | Decorative shadows with no token | `0x0A000000`, `0x0F000000`, `0x1F000000` |
| `0x1A27231E` | `borderStrong` at 10% alpha — preserved rendered value | many card borders |
| `0x4DD5C2C7` | `border` at 30% alpha — already marked `// Exact alpha variant.` | `lib/screens/top_rankings_screen.dart`, etc. |
| Theme-provider custom palettes | User-facing theme customization, not design-system tokens | `lib/providers/theme_provider.dart` |

## Suggested order of review

1. **Clear error/success candidates** (section 1) — safest wins.
2. **Near-miss unification** (section 2) — decide whether visual fidelity or consistency is more important.
3. **New-token candidates** (section 3) — only if expanding `V2Colors` is desired.

## Notes

- Section 3 colors like `0xFFBC92A6` are already explicitly commented as exceptions in code. Updating them means either adding new tokens to `lib/config/v2_design_system.dart` or accepting them as permanent local constants.
- Before adding new tokens, consider whether the color is reused across multiple screens (good token candidate) or is screen-specific (better as a local constant).

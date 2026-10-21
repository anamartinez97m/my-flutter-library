# Web version improvements

Suggestions for making the web build of the app feel good on desktop browsers. Nothing here is implemented yet; the side navigation rail is in PR #34.

Recommended order: 1 (Firebase and files) → 2 (layout) → 5 (quick wins) → 3 → 4.

## 1. Things that are broken or missing on web

- **Firebase:** the app has no web `FirebaseOptions`, so Google sign-in, admin role, cloud backup and Storage are all off on web. It needs a web app in Firebase (`flutterfire configure`) and a Google Sign-In web client ID. The `signIn()` call `google_sign_in` uses also behaves differently on web.
- **Backup, restore and CSV import/export:** these read and write files through `dart:io` (`File`, `path_provider`) in `lib/services/backup_service.dart`, `lib/widgets/settings/backup_restore_section.dart`, `lib/screens/settings.dart` and `lib/screens/admin_csv_import.dart`, and none of that works in a browser. Switch to bytes (`file_picker` with `withData: true`) and trigger a browser download for exports.
- **Where the data lives:** on web the library sits in the browser's own storage, so clearing site data or switching browsers loses it. Add a clear warning plus easy cloud backup once Firebase works.
- **Features that don't apply on web:** hide or rework these:
  - the barcode scanner (`mobile_scanner`), which needs a camera and HTTPS; on desktop, typing the ISBN is better
  - notifications and in-app update settings
  - the wakelock on the chronometer
- **Book covers:** on web, loading a cover from Google Books or Open Library only works if that server allows it (CORS). Some covers may come up blank, so this needs testing; a small proxy through Firebase Functions fixes it if needed.

## 2. Layout for wide screens

- **Navigation:** side `NavigationRail` instead of the bottom bar (PR #34).
- **Width cap:** limit content to about 1000–1200px and centre it. Right now cards, lists and forms stretch across the whole monitor; only about 6 places in `lib/screens/new_ui/` set a max width.
- **Grids:** switch to responsive grids on wide screens. My Books as a cover grid, Home bento cards and Quick Stats in 2–3 columns, stats charts side by side.
- **List plus detail:** on wide screens, show the book list on the left and the book detail on the right, instead of pushing a full-screen page.
- **Dialogs:** show a centred dialog with a max width instead of a bottom sheet on wide screens (there are about 11 `showModalBottomSheet` calls).
- **Add/Edit book form:** two columns on wide screens.
- **Full-height hub screens (like Random):** their cards fill the whole height, so they'll look huge on a desktop. Cap their height on web.

## 3. Mouse and keyboard

- Hover effects, a pointer cursor on anything clickable, and tooltips on icon-only buttons.
- **Long-press and swipe:** there are about 14 long-press and swipe (`onLongPress` / `Dismissible`) actions, and mouse users won't find them. Add a visible "⋮" menu or right-click menu.
- **Horizontal rows:** Flutter web doesn't let you drag-scroll these with a mouse by default, so the Quick Stats and carousels need that turned on (`ScrollConfiguration` drag devices), plus visible scrollbars.
- **Keyboard:** Enter to save, Esc to close dialogs, sensible Tab order, and a search shortcut (`/` or Ctrl+K).
- **Text selection:** let people select and copy text on Book detail (titles, ISBN, notes), e.g. with `SelectionArea`.

## 4. URLs and browser behaviour

- **URLs:** switch to clean URLs (no `#`) with `usePathUrlStrategy()`.
- **Named routes:** navigation is about 83 unnamed `MaterialPageRoute`s, so refreshing the page always lands on Home and you can't bookmark or share a book or screen. Named routes, or `go_router`, would fix that. It's the biggest refactor here, so it's optional.

## 5. Polish

- **Browser tab, icon and install info:** `web/index.html` and `web/manifest.json` still have the Flutter defaults:
  - title "mylibrary" and description "A flutter library project."
  - Flutter-blue theme colour `#0175C2`, which should be burgundy `#43102B`
  - a lock to portrait orientation (`portrait-primary`)
  - the default favicon
- **Loading screen:** a branded one instead of a blank screen while the app loads.
- **Build and hosting:** try the `--wasm` build for speed, and host on Firebase Hosting with the right caching for `sqlite3.wasm`.

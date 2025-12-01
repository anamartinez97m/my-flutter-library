import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// My Book Vault
  ///
  /// In en, this message translates to:
  /// **'My Book Vault'**
  String get app_title;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @random.
  ///
  /// In en, this message translates to:
  /// **'Random'**
  String get random;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @search_by_title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get search_by_title;

  /// No description provided for @search_by_isbn.
  ///
  /// In en, this message translates to:
  /// **'ISBN/ASIN'**
  String get search_by_isbn;

  /// No description provided for @search_by_author.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get search_by_author;

  /// No description provided for @search_label.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search_label;

  /// No description provided for @search_hint.
  ///
  /// In en, this message translates to:
  /// **'Search for books...'**
  String get search_hint;

  /// No description provided for @add_book.
  ///
  /// In en, this message translates to:
  /// **'Add Book'**
  String get add_book;

  /// No description provided for @edit_book.
  ///
  /// In en, this message translates to:
  /// **'Edit Book'**
  String get edit_book;

  /// No description provided for @delete_book.
  ///
  /// In en, this message translates to:
  /// **'Delete Book'**
  String get delete_book;

  /// No description provided for @unknown_title.
  ///
  /// In en, this message translates to:
  /// **'Unknown Title'**
  String get unknown_title;

  /// No description provided for @book_name.
  ///
  /// In en, this message translates to:
  /// **'Book Name'**
  String get book_name;

  /// No description provided for @isbn.
  ///
  /// In en, this message translates to:
  /// **'ISBN'**
  String get isbn;

  /// ISBN with colon
  ///
  /// In en, this message translates to:
  /// **'ISBN: {isbn}'**
  String isbn_with_colon(Object isbn);

  /// No description provided for @author.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get author;

  /// Author with colon
  ///
  /// In en, this message translates to:
  /// **'Author: {author}'**
  String author_with_colon(Object author);

  /// No description provided for @saga.
  ///
  /// In en, this message translates to:
  /// **'Saga'**
  String get saga;

  /// No description provided for @saga_universe.
  ///
  /// In en, this message translates to:
  /// **'Saga Universe'**
  String get saga_universe;

  /// Saga with colon
  ///
  /// In en, this message translates to:
  /// **'Saga: {saga}'**
  String saga_with_colon(Object saga);

  /// No description provided for @saga_number.
  ///
  /// In en, this message translates to:
  /// **'Saga Number'**
  String get saga_number;

  /// No description provided for @pages.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get pages;

  /// No description provided for @publication_year.
  ///
  /// In en, this message translates to:
  /// **'Publication Year'**
  String get publication_year;

  /// No description provided for @editorial.
  ///
  /// In en, this message translates to:
  /// **'Editorial'**
  String get editorial;

  /// No description provided for @genre.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get genre;

  /// Genre with colon
  ///
  /// In en, this message translates to:
  /// **'Genre: {genre}'**
  String genre_with_colon(Object genre);

  /// No description provided for @place.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get place;

  /// No description provided for @format.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get format;

  /// Format with colon
  ///
  /// In en, this message translates to:
  /// **'Format: {format}'**
  String format_with_colon(Object format);

  /// No description provided for @format_saga.
  ///
  /// In en, this message translates to:
  /// **'Format Saga'**
  String get format_saga;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Reading Status'**
  String get status;

  /// No description provided for @loaned.
  ///
  /// In en, this message translates to:
  /// **'Loaned'**
  String get loaned;

  /// No description provided for @date_created.
  ///
  /// In en, this message translates to:
  /// **'Created Date'**
  String get date_created;

  /// Language with colon
  ///
  /// In en, this message translates to:
  /// **'Language: {language}'**
  String language_with_colon(Object language);

  /// No description provided for @my_rating.
  ///
  /// In en, this message translates to:
  /// **'My Rating'**
  String get my_rating;

  /// No description provided for @times_read.
  ///
  /// In en, this message translates to:
  /// **'Times Read'**
  String get times_read;

  /// No description provided for @date_started_reading.
  ///
  /// In en, this message translates to:
  /// **'Date Started Reading'**
  String get date_started_reading;

  /// No description provided for @date_finished_reading.
  ///
  /// In en, this message translates to:
  /// **'Date Finished Reading'**
  String get date_finished_reading;

  /// No description provided for @my_review.
  ///
  /// In en, this message translates to:
  /// **'My Review'**
  String get my_review;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @import_csv.
  ///
  /// In en, this message translates to:
  /// **'Import from CSV'**
  String get import_csv;

  /// No description provided for @export_csv.
  ///
  /// In en, this message translates to:
  /// **'Export to CSV'**
  String get export_csv;

  /// No description provided for @create_backup.
  ///
  /// In en, this message translates to:
  /// **'Create Backup'**
  String get create_backup;

  /// No description provided for @backup_canceled.
  ///
  /// In en, this message translates to:
  /// **'Backup Canceled'**
  String get backup_canceled;

  /// Backup created successfully
  ///
  /// In en, this message translates to:
  /// **'Backup created successfully!\n {backup_path}'**
  String backup_created_successfully(Object backup_path);

  /// No description provided for @replace_database.
  ///
  /// In en, this message translates to:
  /// **'Replace Database'**
  String get replace_database;

  /// No description provided for @database_restored_successfully.
  ///
  /// In en, this message translates to:
  /// **'Database restored successfully!'**
  String get database_restored_successfully;

  /// Import backup error
  ///
  /// In en, this message translates to:
  /// **'Error importing backup: {error}'**
  String import_backup_error(Object error);

  /// Error importing backup
  ///
  /// In en, this message translates to:
  /// **'Error importing backup: {error}'**
  String error_importing_backup(Object error);

  /// No description provided for @import_backup.
  ///
  /// In en, this message translates to:
  /// **'Import Backup'**
  String get import_backup;

  /// No description provided for @import_database_backup.
  ///
  /// In en, this message translates to:
  /// **'Import Database Backup'**
  String get import_database_backup;

  /// No description provided for @import_backup_confirmation.
  ///
  /// In en, this message translates to:
  /// **'This will replace your current database with the backup. All current data will be lost. Are you sure?'**
  String get import_backup_confirmation;

  /// No description provided for @select_backup_file.
  ///
  /// In en, this message translates to:
  /// **'Select backup file'**
  String get select_backup_file;

  /// No description provided for @delete_all_data.
  ///
  /// In en, this message translates to:
  /// **'Delete All Data'**
  String get delete_all_data;

  /// No description provided for @creating_backup.
  ///
  /// In en, this message translates to:
  /// **'Creating Backup...'**
  String get creating_backup;

  /// No description provided for @importing_books.
  ///
  /// In en, this message translates to:
  /// **'Importing Books...'**
  String get importing_books;

  /// No description provided for @importing_backup.
  ///
  /// In en, this message translates to:
  /// **'Importing Backup...'**
  String get importing_backup;

  /// No description provided for @deleting_all_data.
  ///
  /// In en, this message translates to:
  /// **'Deleting All Data...'**
  String get deleting_all_data;

  /// No description provided for @delete_all_data_confirmation.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete ALL books from your library. This action cannot be undone!\n\nAre you sure you want to continue?'**
  String get delete_all_data_confirmation;

  /// Deleted books
  ///
  /// In en, this message translates to:
  /// **'Deleted {count} books successfully'**
  String deleted_books(Object count);

  /// Error creating backup
  ///
  /// In en, this message translates to:
  /// **'Error creating backup: {error}'**
  String error_creating_backup(Object error);

  /// Error importing CSV
  ///
  /// In en, this message translates to:
  /// **'Error importing CSV: {error}'**
  String error_importing_csv(Object error);

  /// Error deleting data
  ///
  /// In en, this message translates to:
  /// **'Error deleting data: {error}'**
  String error_deleting_data(Object error);

  /// Import completed
  ///
  /// In en, this message translates to:
  /// **'Import completed!\nImported: {importedCount} books\nSkipped: {skippedCount} rows'**
  String import_completed(Object importedCount, Object skippedCount);

  /// No description provided for @import_completed_with_duplicates.
  ///
  /// In en, this message translates to:
  /// **'Import completed with duplicates!'**
  String get import_completed_with_duplicates;

  /// Imported books
  ///
  /// In en, this message translates to:
  /// **'Imported: {importedCount} books'**
  String imported_books(Object importedCount);

  /// Skipped rows
  ///
  /// In en, this message translates to:
  /// **'Skipped: {skippedCount} rows'**
  String skipped_rows(Object skippedCount);

  /// Duplicates found
  ///
  /// In en, this message translates to:
  /// **'Duplicates found: {duplicateCount} books'**
  String duplicates_found(Object duplicateCount);

  /// No description provided for @duplicate_books_not_imported.
  ///
  /// In en, this message translates to:
  /// **'Duplicate books (not imported):'**
  String get duplicate_books_not_imported;

  /// No description provided for @books_already_exist.
  ///
  /// In en, this message translates to:
  /// **'These books already exist in your library. You can add them manually if needed.'**
  String get books_already_exist;

  /// No description provided for @more_books.
  ///
  /// In en, this message translates to:
  /// **'... and {count} more'**
  String more_books(Object count);

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @permanently_delete_all_books_from_the_database.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete all books from the database'**
  String get permanently_delete_all_books_from_the_database;

  /// No description provided for @light_theme_colors.
  ///
  /// In en, this message translates to:
  /// **'Light Theme Colors'**
  String get light_theme_colors;

  /// No description provided for @dark_theme_colors.
  ///
  /// In en, this message translates to:
  /// **'Dark Theme Colors'**
  String get dark_theme_colors;

  /// No description provided for @theme_mode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get theme_mode;

  /// No description provided for @create_database_backup.
  ///
  /// In en, this message translates to:
  /// **'Create Database Backup'**
  String get create_database_backup;

  /// No description provided for @save_a_copy_of_your_library_database.
  ///
  /// In en, this message translates to:
  /// **'Save a copy of your library database'**
  String get save_a_copy_of_your_library_database;

  /// No description provided for @manage_dropdown_values.
  ///
  /// In en, this message translates to:
  /// **'Manage Dropdown Values'**
  String get manage_dropdown_values;

  /// No description provided for @manage_dropdown_values_hint.
  ///
  /// In en, this message translates to:
  /// **'Manage dropdown values for status, language, place, format, and format saga.'**
  String get manage_dropdown_values_hint;

  /// No description provided for @import_from_csv_hint.
  ///
  /// In en, this message translates to:
  /// **'Expected columns: read, title, author, publisher, genre, saga, n_saga, format_saga, isbn13, number of pages, original publication year, language, place, binding, loaned'**
  String get import_from_csv_hint;

  /// No description provided for @import_from_csv_tbreleased.
  ///
  /// In en, this message translates to:
  /// **'For unreleased books use status tb_released'**
  String get import_from_csv_tbreleased;

  /// No description provided for @import_from_csv.
  ///
  /// In en, this message translates to:
  /// **'Import book from CSV'**
  String get import_from_csv;

  /// No description provided for @import_from_csv_file.
  ///
  /// In en, this message translates to:
  /// **'Import books from a CSV file'**
  String get import_from_csv_file;

  /// No description provided for @restore_a_copy_of_your_library_database.
  ///
  /// In en, this message translates to:
  /// **'Restore a copy of your library database'**
  String get restore_a_copy_of_your_library_database;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @theme_light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get theme_light;

  /// No description provided for @theme_dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get theme_dark;

  /// No description provided for @theme_system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get theme_system;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @spanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get spanish;

  /// No description provided for @total_books.
  ///
  /// In en, this message translates to:
  /// **'Total Books'**
  String get total_books;

  /// No description provided for @latest_book_added.
  ///
  /// In en, this message translates to:
  /// **'Latest Book Added'**
  String get latest_book_added;

  /// No description provided for @books_by_status.
  ///
  /// In en, this message translates to:
  /// **'Books by Status'**
  String get books_by_status;

  /// No description provided for @books_by_language.
  ///
  /// In en, this message translates to:
  /// **'Books by Language'**
  String get books_by_language;

  /// No description provided for @books_by_format.
  ///
  /// In en, this message translates to:
  /// **'Books by Format'**
  String get books_by_format;

  /// No description provided for @no_books_in_database.
  ///
  /// In en, this message translates to:
  /// **'No books in the database'**
  String get no_books_in_database;

  /// No description provided for @top_10_editorials.
  ///
  /// In en, this message translates to:
  /// **'Top 10 Editorials'**
  String get top_10_editorials;

  /// No description provided for @top_10_authors.
  ///
  /// In en, this message translates to:
  /// **'Top 10 Authors'**
  String get top_10_authors;

  /// No description provided for @get_random_book.
  ///
  /// In en, this message translates to:
  /// **'Get Random Book'**
  String get get_random_book;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @any.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get any;

  /// No description provided for @confirm_delete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this book?'**
  String get confirm_delete;

  /// No description provided for @confirm_delete_all.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete ALL books from your library. This action cannot be undone!\\n\\nAre you sure you want to continue?'**
  String get confirm_delete_all;

  /// No description provided for @book_added_successfully.
  ///
  /// In en, this message translates to:
  /// **'Book added successfully!'**
  String get book_added_successfully;

  /// No description provided for @book_updated_successfully.
  ///
  /// In en, this message translates to:
  /// **'Book updated successfully!'**
  String get book_updated_successfully;

  /// No description provided for @book_deleted_successfully.
  ///
  /// In en, this message translates to:
  /// **'Book deleted successfully!'**
  String get book_deleted_successfully;

  /// No description provided for @no_books_found.
  ///
  /// In en, this message translates to:
  /// **'No books found'**
  String get no_books_found;

  /// No description provided for @no_data.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get no_data;

  /// No description provided for @reading_information.
  ///
  /// In en, this message translates to:
  /// **'Reading Information (Optional)'**
  String get reading_information;

  /// No description provided for @add_read.
  ///
  /// In en, this message translates to:
  /// **'Add Read'**
  String get add_read;

  /// No description provided for @tap_hearts_to_rate.
  ///
  /// In en, this message translates to:
  /// **'Tap hearts to rate (tap again for half)'**
  String get tap_hearts_to_rate;

  /// No description provided for @top_5_genres.
  ///
  /// In en, this message translates to:
  /// **'Top 5 Genres'**
  String get top_5_genres;

  /// No description provided for @about_box_children.
  ///
  /// In en, this message translates to:
  /// **'Aplicación desarrollada con Flutter/Dart.\n Permite gestionar tu biblioteca personal y recibir recomendaciones de lectura personalizadas.'**
  String get about_box_children;

  /// No description provided for @sort_and_filter.
  ///
  /// In en, this message translates to:
  /// **'Sort & Filter'**
  String get sort_and_filter;

  /// No description provided for @empty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get empty;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @isbn_asin.
  ///
  /// In en, this message translates to:
  /// **'ISBN/ASIN'**
  String get isbn_asin;

  /// No description provided for @bundle.
  ///
  /// In en, this message translates to:
  /// **'Bundle'**
  String get bundle;

  /// No description provided for @tandem.
  ///
  /// In en, this message translates to:
  /// **'Tandem'**
  String get tandem;

  /// No description provided for @saga_format_without_saga.
  ///
  /// In en, this message translates to:
  /// **'Saga Format Without Saga'**
  String get saga_format_without_saga;

  /// No description provided for @saga_format_without_n_saga.
  ///
  /// In en, this message translates to:
  /// **'Saga Format Without N_Saga'**
  String get saga_format_without_n_saga;

  /// Pages with colon
  ///
  /// In en, this message translates to:
  /// **'Pages: {pages}'**
  String pages_with_colon(Object pages);

  /// No description provided for @max_tbr_books_description.
  ///
  /// In en, this message translates to:
  /// **'Maximum number of books you can mark as \'To Be Read\' at once:'**
  String get max_tbr_books_description;

  /// No description provided for @max_tbr_books_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Maximum books in \'To Be Read\': {tbrLimit}'**
  String max_tbr_books_subtitle(Object tbrLimit);

  /// No description provided for @set_tbr_limit.
  ///
  /// In en, this message translates to:
  /// **'Set TBR Limit'**
  String get set_tbr_limit;

  /// No description provided for @tbr_limit.
  ///
  /// In en, this message translates to:
  /// **'TBR Limit'**
  String get tbr_limit;

  /// No description provided for @books.
  ///
  /// In en, this message translates to:
  /// **'books'**
  String get books;

  /// No description provided for @please_enter_valid_number.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number greater than 0'**
  String get please_enter_valid_number;

  /// No description provided for @maximum_limit_200_books.
  ///
  /// In en, this message translates to:
  /// **'Maximum limit is 200 books'**
  String get maximum_limit_200_books;

  /// No description provided for @range_1_200_books.
  ///
  /// In en, this message translates to:
  /// **'Range: 1-200 books'**
  String get range_1_200_books;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}

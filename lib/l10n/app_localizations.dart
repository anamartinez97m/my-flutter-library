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

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @duration_label.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration_label;

  /// No description provided for @enter_valid_number.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number (1 or greater)'**
  String get enter_valid_number;

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
  /// **'Custom CSV columns: Title, Author, ISBN, ASIN, Saga, N_Saga, Saga Universe, Format Saga, Status, Editorial, Language, Place, Format, Genre, Pages, Original Publication Year, Loaned, Date Read Initial, Date Read Final, Read Count, My Rating, My Review, Notes, Price, Release Date, Is Bundle, Bundle Count, TBR, Is Tandem, Cover URL, Description, Created At'**
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

  /// No description provided for @saga_without_format_saga.
  ///
  /// In en, this message translates to:
  /// **'Saga Without Format Saga'**
  String get saga_without_format_saga;

  /// No description provided for @publication_year_empty.
  ///
  /// In en, this message translates to:
  /// **'Publication Year'**
  String get publication_year_empty;

  /// No description provided for @rating_filter.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating_filter;

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

  /// No description provided for @this_is_a_bundle.
  ///
  /// In en, this message translates to:
  /// **'This is a bundle'**
  String get this_is_a_bundle;

  /// No description provided for @check_if_this_book_contains_multiple_books.
  ///
  /// In en, this message translates to:
  /// **'Check if this book contains multiple books in one volume'**
  String get check_if_this_book_contains_multiple_books;

  /// No description provided for @number_of_books_in_bundle.
  ///
  /// In en, this message translates to:
  /// **'Number of Books in Bundle'**
  String get number_of_books_in_bundle;

  /// No description provided for @saga_numbers_optional.
  ///
  /// In en, this message translates to:
  /// **'Saga Numbers (optional)'**
  String get saga_numbers_optional;

  /// No description provided for @saga_number_n_saga.
  ///
  /// In en, this message translates to:
  /// **'Saga Number (N_Saga)'**
  String get saga_number_n_saga;

  /// No description provided for @book_title.
  ///
  /// In en, this message translates to:
  /// **'Book Title'**
  String get book_title;

  /// No description provided for @authors.
  ///
  /// In en, this message translates to:
  /// **'Author(s)'**
  String get authors;

  /// No description provided for @original_publication_year.
  ///
  /// In en, this message translates to:
  /// **'Original Publication Year'**
  String get original_publication_year;

  /// No description provided for @started.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get started;

  /// No description provided for @finished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get finished;

  /// No description provided for @search_books_by_title.
  ///
  /// In en, this message translates to:
  /// **'Search books by title'**
  String get search_books_by_title;

  /// No description provided for @stop_timer.
  ///
  /// In en, this message translates to:
  /// **'Stop Timer'**
  String get stop_timer;

  /// No description provided for @do_you_want_to_stop_the_reading_timer.
  ///
  /// In en, this message translates to:
  /// **'Do you want to stop the reading timer?'**
  String get do_you_want_to_stop_the_reading_timer;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @timer_is_running.
  ///
  /// In en, this message translates to:
  /// **'Timer is Running'**
  String get timer_is_running;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @stop_save.
  ///
  /// In en, this message translates to:
  /// **'Stop & Save'**
  String get stop_save;

  /// No description provided for @quick_add.
  ///
  /// In en, this message translates to:
  /// **'Quick Add'**
  String get quick_add;

  /// No description provided for @add_book_s.
  ///
  /// In en, this message translates to:
  /// **'Add {count} Book(s)'**
  String add_book_s(Object count);

  /// No description provided for @bundle_book_details.
  ///
  /// In en, this message translates to:
  /// **'Bundle Book Details'**
  String get bundle_book_details;

  /// No description provided for @select_label.
  ///
  /// In en, this message translates to:
  /// **'Select {label}'**
  String select_label(Object label);

  /// No description provided for @full_date.
  ///
  /// In en, this message translates to:
  /// **'Full Date'**
  String get full_date;

  /// No description provided for @year_only.
  ///
  /// In en, this message translates to:
  /// **'Year Only'**
  String get year_only;

  /// No description provided for @add_session.
  ///
  /// In en, this message translates to:
  /// **'Add Session'**
  String get add_session;

  /// No description provided for @enter_year.
  ///
  /// In en, this message translates to:
  /// **'Enter Year'**
  String get enter_year;

  /// No description provided for @please_enter_valid_year.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid year'**
  String get please_enter_valid_year;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @proceed.
  ///
  /// In en, this message translates to:
  /// **'Proceed'**
  String get proceed;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get info;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @stop_timer_question.
  ///
  /// In en, this message translates to:
  /// **'Stop Timer?'**
  String get stop_timer_question;

  /// No description provided for @confirm_restore.
  ///
  /// In en, this message translates to:
  /// **'Confirm Restore'**
  String get confirm_restore;

  /// No description provided for @confirm_restore_message.
  ///
  /// In en, this message translates to:
  /// **'This will replace your current database. Make sure you have a backup!'**
  String get confirm_restore_message;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @add_another.
  ///
  /// In en, this message translates to:
  /// **'Add Another'**
  String get add_another;

  /// No description provided for @go_to_home.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get go_to_home;

  /// No description provided for @missing_information.
  ///
  /// In en, this message translates to:
  /// **'Missing Information'**
  String get missing_information;

  /// No description provided for @enable_release_notification.
  ///
  /// In en, this message translates to:
  /// **'Enable Release Notification'**
  String get enable_release_notification;

  /// No description provided for @add_to_tbr.
  ///
  /// In en, this message translates to:
  /// **'Add to TBR (To Be Read)'**
  String get add_to_tbr;

  /// No description provided for @tbr_limit_reached.
  ///
  /// In en, this message translates to:
  /// **'TBR Limit Reached'**
  String get tbr_limit_reached;

  /// No description provided for @mark_as_tandem_book.
  ///
  /// In en, this message translates to:
  /// **'Mark as Tandem Book'**
  String get mark_as_tandem_book;

  /// No description provided for @scan_isbn.
  ///
  /// In en, this message translates to:
  /// **'Scan ISBN'**
  String get scan_isbn;

  /// No description provided for @customize_home_filters.
  ///
  /// In en, this message translates to:
  /// **'Customize Home Filters'**
  String get customize_home_filters;

  /// No description provided for @select_all.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get select_all;

  /// No description provided for @clear_all.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clear_all;

  /// No description provided for @books_removed_from_tbr.
  ///
  /// In en, this message translates to:
  /// **'{bookName} removed from TBR'**
  String books_removed_from_tbr(Object bookName);

  /// No description provided for @error_occurred.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String error_occurred(Object error);

  /// No description provided for @tbr_books_count.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String tbr_books_count(Object count);

  /// No description provided for @no_books_from_decade.
  ///
  /// In en, this message translates to:
  /// **'No books read from this decade'**
  String get no_books_from_decade;

  /// No description provided for @decade_book_count.
  ///
  /// In en, this message translates to:
  /// **'{decade} ({totalCount} books)'**
  String decade_book_count(Object decade, Object totalCount);

  /// No description provided for @migrate_bundle_books.
  ///
  /// In en, this message translates to:
  /// **'Migrate Bundle Books?'**
  String get migrate_bundle_books;

  /// No description provided for @migrate.
  ///
  /// In en, this message translates to:
  /// **'Migrate'**
  String get migrate;

  /// No description provided for @successful_migrations.
  ///
  /// In en, this message translates to:
  /// **'✅ Successful: {count}'**
  String successful_migrations(Object count);

  /// No description provided for @skipped_migrations.
  ///
  /// In en, this message translates to:
  /// **'⏭️  Skipped: {count}'**
  String skipped_migrations(Object count);

  /// No description provided for @failed_migrations.
  ///
  /// In en, this message translates to:
  /// **'❌ Failed: {count}'**
  String failed_migrations(Object count);

  /// No description provided for @import_from_goodreads.
  ///
  /// In en, this message translates to:
  /// **'Import from Goodreads'**
  String get import_from_goodreads;

  /// No description provided for @import_all_books.
  ///
  /// In en, this message translates to:
  /// **'Import all books'**
  String get import_all_books;

  /// No description provided for @import_books_from_tag.
  ///
  /// In en, this message translates to:
  /// **'Import books from a specific tag'**
  String get import_books_from_tag;

  /// No description provided for @add_dropdown_value.
  ///
  /// In en, this message translates to:
  /// **'Add {valueType}'**
  String add_dropdown_value(Object valueType);

  /// No description provided for @edit_dropdown_value.
  ///
  /// In en, this message translates to:
  /// **'Edit {valueType}'**
  String edit_dropdown_value(Object valueType);

  /// No description provided for @cannot_delete.
  ///
  /// In en, this message translates to:
  /// **'Cannot Delete'**
  String get cannot_delete;

  /// No description provided for @delete_value.
  ///
  /// In en, this message translates to:
  /// **'Delete Value'**
  String get delete_value;

  /// No description provided for @replace_with_existing_value.
  ///
  /// In en, this message translates to:
  /// **'Replace with existing value'**
  String get replace_with_existing_value;

  /// No description provided for @create_new_value.
  ///
  /// In en, this message translates to:
  /// **'Create new value'**
  String get create_new_value;

  /// No description provided for @delete_completely.
  ///
  /// In en, this message translates to:
  /// **'Delete completely (may fail)'**
  String get delete_completely;

  /// No description provided for @new_year_challenge.
  ///
  /// In en, this message translates to:
  /// **'New Year Challenge'**
  String get new_year_challenge;

  /// No description provided for @edit_year_challenge.
  ///
  /// In en, this message translates to:
  /// **'Edit {year} Challenge'**
  String edit_year_challenge(Object year);

  /// No description provided for @delete_challenge.
  ///
  /// In en, this message translates to:
  /// **'Delete Challenge'**
  String get delete_challenge;

  /// No description provided for @year_challenges.
  ///
  /// In en, this message translates to:
  /// **'Year Challenges'**
  String get year_challenges;

  /// No description provided for @best_book_of_year.
  ///
  /// In en, this message translates to:
  /// **'Best Book of {year}'**
  String best_book_of_year(Object year);

  /// No description provided for @best_book_competition.
  ///
  /// In en, this message translates to:
  /// **'Best Book Competition'**
  String get best_book_competition;

  /// No description provided for @winner.
  ///
  /// In en, this message translates to:
  /// **'Winner'**
  String get winner;

  /// No description provided for @nominees.
  ///
  /// In en, this message translates to:
  /// **'Nominees'**
  String get nominees;

  /// No description provided for @tournament_tree.
  ///
  /// In en, this message translates to:
  /// **'Tournament Tree'**
  String get tournament_tree;

  /// No description provided for @quarterly_winners.
  ///
  /// In en, this message translates to:
  /// **'Quarterly Winners'**
  String get quarterly_winners;

  /// No description provided for @semifinals.
  ///
  /// In en, this message translates to:
  /// **'Semifinals'**
  String get semifinals;

  /// No description provided for @last.
  ///
  /// In en, this message translates to:
  /// **'Last'**
  String get last;

  /// No description provided for @monthly_winners.
  ///
  /// In en, this message translates to:
  /// **'Monthly Winners'**
  String get monthly_winners;

  /// No description provided for @no_books_read_year.
  ///
  /// In en, this message translates to:
  /// **'No books read in {year}'**
  String no_books_read_year(Object year);

  /// No description provided for @no_competition_data.
  ///
  /// In en, this message translates to:
  /// **'No competition data available'**
  String get no_competition_data;

  /// Error loading competition data
  ///
  /// In en, this message translates to:
  /// **'Error loading competition data: {error}'**
  String error_loading_competition(Object error);

  /// No description provided for @update_available_title.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get update_available_title;

  /// No description provided for @update_available_message.
  ///
  /// In en, this message translates to:
  /// **'A new version of My Book Vault is available. Update now to get the latest features and improvements.'**
  String get update_available_message;

  /// No description provided for @update_now.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update_now;

  /// No description provided for @update_later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get update_later;

  /// No description provided for @admin_mode.
  ///
  /// In en, this message translates to:
  /// **'Admin Mode'**
  String get admin_mode;

  /// No description provided for @admin_mode_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable advanced features like admin CSV import'**
  String get admin_mode_subtitle;

  /// No description provided for @admin_csv_import.
  ///
  /// In en, this message translates to:
  /// **'Admin CSV Import'**
  String get admin_csv_import;

  /// No description provided for @admin_csv_import_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Review and edit each book before importing'**
  String get admin_csv_import_subtitle;

  /// No description provided for @default_values.
  ///
  /// In en, this message translates to:
  /// **'Default Values'**
  String get default_values;

  /// No description provided for @default_values_subtitle.
  ///
  /// In en, this message translates to:
  /// **'TBR Limit, Sort Order, Home Filters, Card Fields'**
  String get default_values_subtitle;

  /// No description provided for @import_export.
  ///
  /// In en, this message translates to:
  /// **'Import/Export'**
  String get import_export;

  /// No description provided for @import_export_subtitle.
  ///
  /// In en, this message translates to:
  /// **'CSV & Database Backup'**
  String get import_export_subtitle;

  /// No description provided for @customize_home_filters_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Select which filters to show in the home screen'**
  String get customize_home_filters_subtitle;

  /// No description provided for @customize_card_fields.
  ///
  /// In en, this message translates to:
  /// **'Customize Card Fields'**
  String get customize_card_fields;

  /// No description provided for @customize_card_fields_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Select which data to show in book cards'**
  String get customize_card_fields_subtitle;

  /// No description provided for @fields_selected.
  ///
  /// In en, this message translates to:
  /// **'{count} fields selected'**
  String fields_selected(Object count);

  /// No description provided for @default_sort_order.
  ///
  /// In en, this message translates to:
  /// **'Default Sort Order'**
  String get default_sort_order;

  /// No description provided for @default_sort_order_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Set the default order for your book list'**
  String get default_sort_order_subtitle;

  /// No description provided for @sort_by.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sort_by;

  /// No description provided for @date_added.
  ///
  /// In en, this message translates to:
  /// **'Date Added'**
  String get date_added;

  /// No description provided for @ascending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get ascending;

  /// No description provided for @descending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get descending;

  /// No description provided for @export_to_csv.
  ///
  /// In en, this message translates to:
  /// **'Export to CSV'**
  String get export_to_csv;

  /// No description provided for @export_to_excel.
  ///
  /// In en, this message translates to:
  /// **'Export to Excel'**
  String get export_to_excel;

  /// No description provided for @preparing_csv_export.
  ///
  /// In en, this message translates to:
  /// **'Preparing CSV export...'**
  String get preparing_csv_export;

  /// No description provided for @no_books_to_export.
  ///
  /// In en, this message translates to:
  /// **'No books to export'**
  String get no_books_to_export;

  /// No description provided for @export_canceled.
  ///
  /// In en, this message translates to:
  /// **'Export canceled'**
  String get export_canceled;

  /// No description provided for @exported_books.
  ///
  /// In en, this message translates to:
  /// **'Exported {count} books to:\n{path}'**
  String exported_books(Object count, Object path);

  /// No description provided for @error_exporting_csv.
  ///
  /// In en, this message translates to:
  /// **'Error exporting to CSV: {error}'**
  String error_exporting_csv(Object error);

  /// No description provided for @permission_required.
  ///
  /// In en, this message translates to:
  /// **'Permission Required'**
  String get permission_required;

  /// No description provided for @storage_permission_backup.
  ///
  /// In en, this message translates to:
  /// **'Storage permission is needed to create backups. Would you like to grant permission?'**
  String get storage_permission_backup;

  /// No description provided for @storage_permission_export.
  ///
  /// In en, this message translates to:
  /// **'Storage permission is needed to export CSV files. Would you like to grant permission?'**
  String get storage_permission_export;

  /// No description provided for @grant_permission.
  ///
  /// In en, this message translates to:
  /// **'Grant Permission'**
  String get grant_permission;

  /// No description provided for @select_folder_save_backup.
  ///
  /// In en, this message translates to:
  /// **'Select folder to save backup'**
  String get select_folder_save_backup;

  /// No description provided for @select_csv_file.
  ///
  /// In en, this message translates to:
  /// **'Select CSV file'**
  String get select_csv_file;

  /// No description provided for @select_folder_save_csv.
  ///
  /// In en, this message translates to:
  /// **'Select folder to save CSV'**
  String get select_folder_save_csv;

  /// No description provided for @select_folder_save_excel_csv.
  ///
  /// In en, this message translates to:
  /// **'Select folder to save Excel CSV'**
  String get select_folder_save_excel_csv;

  /// No description provided for @please_select_csv_file.
  ///
  /// In en, this message translates to:
  /// **'Please select a CSV file'**
  String get please_select_csv_file;

  /// No description provided for @importing_books_from_csv.
  ///
  /// In en, this message translates to:
  /// **'Importing books from CSV...'**
  String get importing_books_from_csv;

  /// No description provided for @import_completed_title.
  ///
  /// In en, this message translates to:
  /// **'Import Completed'**
  String get import_completed_title;

  /// No description provided for @import_result_message.
  ///
  /// In en, this message translates to:
  /// **'Imported: {imported} books\nUpdated: {updated} books\nSkipped: {skipped} rows'**
  String import_result_message(Object imported, Object updated, Object skipped);

  /// No description provided for @select_tag.
  ///
  /// In en, this message translates to:
  /// **'Select tag'**
  String get select_tag;

  /// No description provided for @deleting_all_books.
  ///
  /// In en, this message translates to:
  /// **'Deleting all books...'**
  String get deleting_all_books;

  /// No description provided for @goodreads_csv_hint.
  ///
  /// In en, this message translates to:
  /// **'Goodreads CSV columns: Title, Author, ISBN13, ASIN, My Rating, Publisher, Binding, Number of Pages, Original Publication Year, Date Read, Date Added, Bookshelves, Exclusive Shelf, My Review, Read Count. Books must have \"owned\" or \"read-loaned\" in bookshelves to be imported'**
  String get goodreads_csv_hint;

  /// No description provided for @manage_rating_field_names.
  ///
  /// In en, this message translates to:
  /// **'Manage Rating Field Names'**
  String get manage_rating_field_names;

  /// No description provided for @manage_rating_field_names_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Add, edit, or remove rating criterion names'**
  String get manage_rating_field_names_subtitle;

  /// No description provided for @manage_club_names.
  ///
  /// In en, this message translates to:
  /// **'Manage Club Names'**
  String get manage_club_names;

  /// No description provided for @manage_club_names_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Rename or delete reading clubs'**
  String get manage_club_names_subtitle;

  /// No description provided for @migrate_bundle_books_title.
  ///
  /// In en, this message translates to:
  /// **'Migrate Bundle Books'**
  String get migrate_bundle_books_title;

  /// No description provided for @migrate_bundle_books_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Convert old bundles to new system'**
  String get migrate_bundle_books_subtitle;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @migrate_reading_sessions.
  ///
  /// In en, this message translates to:
  /// **'Migrate Reading Sessions'**
  String get migrate_reading_sessions;

  /// No description provided for @migrate_reading_sessions_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Move reading sessions to individual books'**
  String get migrate_reading_sessions_subtitle;

  /// No description provided for @migrate_reading_sessions_question.
  ///
  /// In en, this message translates to:
  /// **'Migrate Reading Sessions?'**
  String get migrate_reading_sessions_question;

  /// No description provided for @no_sessions_to_migrate.
  ///
  /// In en, this message translates to:
  /// **'No reading sessions to migrate. All sessions are already on individual books!'**
  String get no_sessions_to_migrate;

  /// No description provided for @migrating_reading_sessions.
  ///
  /// In en, this message translates to:
  /// **'Migrating reading sessions...'**
  String get migrating_reading_sessions;

  /// No description provided for @migration_successful.
  ///
  /// In en, this message translates to:
  /// **'Migration Successful!'**
  String get migration_successful;

  /// No description provided for @migration_completed_with_errors.
  ///
  /// In en, this message translates to:
  /// **'Migration Completed with Errors'**
  String get migration_completed_with_errors;

  /// No description provided for @what_will_happen.
  ///
  /// In en, this message translates to:
  /// **'What will happen:'**
  String get what_will_happen;

  /// No description provided for @migration_description.
  ///
  /// In en, this message translates to:
  /// **'• Reading sessions will be copied to individual books\n• Old bundle reading sessions will be deleted\n• This fixes inconsistencies in bundle reading history'**
  String get migration_description;

  /// No description provided for @migration_safe_info.
  ///
  /// In en, this message translates to:
  /// **'ℹ️ This is safe and can be run multiple times'**
  String get migration_safe_info;

  /// No description provided for @successful_bundles.
  ///
  /// In en, this message translates to:
  /// **'✅ Successful: {count} bundles'**
  String successful_bundles(Object count);

  /// No description provided for @skipped_bundles.
  ///
  /// In en, this message translates to:
  /// **'⏭️  Skipped: {count} bundles'**
  String skipped_bundles(Object count);

  /// No description provided for @failed_bundles.
  ///
  /// In en, this message translates to:
  /// **'❌ Failed: {count} bundles'**
  String failed_bundles(Object count);

  /// No description provided for @total_sessions_migrated.
  ///
  /// In en, this message translates to:
  /// **'📚 Total sessions migrated: {count}'**
  String total_sessions_migrated(Object count);

  /// No description provided for @errors_label.
  ///
  /// In en, this message translates to:
  /// **'Errors:'**
  String get errors_label;

  /// No description provided for @error_migrating_reading_sessions.
  ///
  /// In en, this message translates to:
  /// **'Error migrating reading sessions: {error}'**
  String error_migrating_reading_sessions(Object error);

  /// No description provided for @warm_earth.
  ///
  /// In en, this message translates to:
  /// **'Warm Earth'**
  String get warm_earth;

  /// No description provided for @vibrant_sunset.
  ///
  /// In en, this message translates to:
  /// **'Vibrant Sunset'**
  String get vibrant_sunset;

  /// No description provided for @soft_pastel.
  ///
  /// In en, this message translates to:
  /// **'Soft Pastel'**
  String get soft_pastel;

  /// No description provided for @deep_ocean.
  ///
  /// In en, this message translates to:
  /// **'Deep Ocean'**
  String get deep_ocean;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @mystic_purple.
  ///
  /// In en, this message translates to:
  /// **'Mystic Purple'**
  String get mystic_purple;

  /// No description provided for @deep_sea.
  ///
  /// In en, this message translates to:
  /// **'Deep Sea'**
  String get deep_sea;

  /// No description provided for @warm_autumn.
  ///
  /// In en, this message translates to:
  /// **'Warm Autumn'**
  String get warm_autumn;

  /// No description provided for @edit_custom_light_palette.
  ///
  /// In en, this message translates to:
  /// **'Edit Custom Light Palette'**
  String get edit_custom_light_palette;

  /// No description provided for @edit_custom_dark_palette.
  ///
  /// In en, this message translates to:
  /// **'Edit Custom Dark Palette'**
  String get edit_custom_dark_palette;

  /// No description provided for @primary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get primary;

  /// No description provided for @secondary.
  ///
  /// In en, this message translates to:
  /// **'Secondary'**
  String get secondary;

  /// No description provided for @tertiary.
  ///
  /// In en, this message translates to:
  /// **'Tertiary'**
  String get tertiary;

  /// No description provided for @pick_a_color.
  ///
  /// In en, this message translates to:
  /// **'Pick a Color'**
  String get pick_a_color;

  /// No description provided for @pick_a_custom_color.
  ///
  /// In en, this message translates to:
  /// **'Pick a Custom Color'**
  String get pick_a_custom_color;

  /// No description provided for @hue.
  ///
  /// In en, this message translates to:
  /// **'Hue'**
  String get hue;

  /// No description provided for @application_name.
  ///
  /// In en, this message translates to:
  /// **'My Random Library'**
  String get application_name;

  /// No description provided for @application_legalese.
  ///
  /// In en, this message translates to:
  /// **'© 2025 Ana Martínez Montañez. All rights reserved.'**
  String get application_legalese;

  /// No description provided for @books_by_decade.
  ///
  /// In en, this message translates to:
  /// **'Books by Decade'**
  String get books_by_decade;

  /// No description provided for @decade_label.
  ///
  /// In en, this message translates to:
  /// **'Decade: '**
  String get decade_label;

  /// No description provided for @re_read_books.
  ///
  /// In en, this message translates to:
  /// **'Re-read Books'**
  String get re_read_books;

  /// No description provided for @authors_title.
  ///
  /// In en, this message translates to:
  /// **'Authors'**
  String get authors_title;

  /// No description provided for @saga_completion.
  ///
  /// In en, this message translates to:
  /// **'Saga Completion'**
  String get saga_completion;

  /// No description provided for @books_by_saga.
  ///
  /// In en, this message translates to:
  /// **'Books by Saga'**
  String get books_by_saga;

  /// No description provided for @bundle_migration.
  ///
  /// In en, this message translates to:
  /// **'Bundle Migration'**
  String get bundle_migration;

  /// No description provided for @books_by_year.
  ///
  /// In en, this message translates to:
  /// **'Books by Year'**
  String get books_by_year;

  /// No description provided for @reading_status_required.
  ///
  /// In en, this message translates to:
  /// **'Reading Status *'**
  String get reading_status_required;

  /// No description provided for @status_is_required.
  ///
  /// In en, this message translates to:
  /// **'Status is required'**
  String get status_is_required;

  /// No description provided for @add_rating_criterion.
  ///
  /// In en, this message translates to:
  /// **'Add Rating Criterion'**
  String get add_rating_criterion;

  /// No description provided for @no_books_match_filters.
  ///
  /// In en, this message translates to:
  /// **'No books match the selected filters'**
  String get no_books_match_filters;

  /// No description provided for @specific_number_of_books.
  ///
  /// In en, this message translates to:
  /// **'Specific number of books'**
  String get specific_number_of_books;

  /// No description provided for @unknown_show_as_question.
  ///
  /// In en, this message translates to:
  /// **'Unknown (show as \"?\")'**
  String get unknown_show_as_question;

  /// No description provided for @for_sagas_unknown_length.
  ///
  /// In en, this message translates to:
  /// **'For sagas with unknown or variable length'**
  String get for_sagas_unknown_length;

  /// No description provided for @continue_label.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continue_label;

  /// No description provided for @confirm_delete_value.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{value}\"?'**
  String confirm_delete_value(Object value);

  /// No description provided for @this_will_fail_constraint.
  ///
  /// In en, this message translates to:
  /// **'This will fail if database constraints prevent it'**
  String get this_will_fail_constraint;

  /// No description provided for @field_name.
  ///
  /// In en, this message translates to:
  /// **'Field Name'**
  String get field_name;

  /// No description provided for @add_rating_field_name.
  ///
  /// In en, this message translates to:
  /// **'Add Rating Field Name'**
  String get add_rating_field_name;

  /// No description provided for @edit_rating_field_name.
  ///
  /// In en, this message translates to:
  /// **'Edit Rating Field Name'**
  String get edit_rating_field_name;

  /// No description provided for @delete_rating_field_name.
  ///
  /// In en, this message translates to:
  /// **'Delete Rating Field Name'**
  String get delete_rating_field_name;

  /// No description provided for @field_name_already_exists.
  ///
  /// In en, this message translates to:
  /// **'Field name \"{name}\" already exists'**
  String field_name_already_exists(Object name);

  /// No description provided for @added_value.
  ///
  /// In en, this message translates to:
  /// **'Added \"{value}\"'**
  String added_value(Object value);

  /// No description provided for @error_adding_field_name.
  ///
  /// In en, this message translates to:
  /// **'Error adding field name: {error}'**
  String error_adding_field_name(Object error);

  /// No description provided for @updated_value.
  ///
  /// In en, this message translates to:
  /// **'Updated \"{oldValue}\" to \"{newValue}\"'**
  String updated_value(Object oldValue, Object newValue);

  /// No description provided for @error_updating_field_name.
  ///
  /// In en, this message translates to:
  /// **'Error updating field name: {error}'**
  String error_updating_field_name(Object error);

  /// No description provided for @confirm_delete_field.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String confirm_delete_field(Object name);

  /// No description provided for @field_used_in_ratings.
  ///
  /// In en, this message translates to:
  /// **'This field is used in {count} rating(s). They will be deleted.'**
  String field_used_in_ratings(Object count);

  /// No description provided for @deleted_value.
  ///
  /// In en, this message translates to:
  /// **'Deleted \"{value}\"'**
  String deleted_value(Object value);

  /// No description provided for @error_deleting_field_name.
  ///
  /// In en, this message translates to:
  /// **'Error deleting field name: {error}'**
  String error_deleting_field_name(Object error);

  /// No description provided for @about_rating_fields.
  ///
  /// In en, this message translates to:
  /// **'About Rating Fields'**
  String get about_rating_fields;

  /// No description provided for @about_rating_fields_description.
  ///
  /// In en, this message translates to:
  /// **'These are the criterion names available when rating books. You can add custom names or edit existing ones. Changes will apply to all future ratings.'**
  String get about_rating_fields_description;

  /// No description provided for @no_rating_field_names.
  ///
  /// In en, this message translates to:
  /// **'No rating field names yet'**
  String get no_rating_field_names;

  /// No description provided for @default_suggestion.
  ///
  /// In en, this message translates to:
  /// **'Default suggestion'**
  String get default_suggestion;

  /// No description provided for @add_field_name.
  ///
  /// In en, this message translates to:
  /// **'Add Field Name'**
  String get add_field_name;

  /// No description provided for @rename_club.
  ///
  /// In en, this message translates to:
  /// **'Rename Club'**
  String get rename_club;

  /// No description provided for @club_name.
  ///
  /// In en, this message translates to:
  /// **'Club Name'**
  String get club_name;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @delete_club.
  ///
  /// In en, this message translates to:
  /// **'Delete Club'**
  String get delete_club;

  /// No description provided for @delete_club_message.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{clubName}\"?\n\nThis will remove {count} {bookWord} from this club.'**
  String delete_club_message(Object clubName, Object count, Object bookWord);

  /// No description provided for @club_already_exists.
  ///
  /// In en, this message translates to:
  /// **'Club \"{name}\" already exists'**
  String club_already_exists(Object name);

  /// No description provided for @renamed_club.
  ///
  /// In en, this message translates to:
  /// **'Renamed \"{oldName}\" to \"{newName}\"'**
  String renamed_club(Object oldName, Object newName);

  /// No description provided for @error_renaming_club.
  ///
  /// In en, this message translates to:
  /// **'Error renaming club: {error}'**
  String error_renaming_club(Object error);

  /// No description provided for @error_deleting_club.
  ///
  /// In en, this message translates to:
  /// **'Error deleting club: {error}'**
  String error_deleting_club(Object error);

  /// No description provided for @no_clubs_yet.
  ///
  /// In en, this message translates to:
  /// **'No clubs yet'**
  String get no_clubs_yet;

  /// No description provided for @add_books_to_clubs_hint.
  ///
  /// In en, this message translates to:
  /// **'Add books to clubs from book details'**
  String get add_books_to_clubs_hint;

  /// No description provided for @book_word.
  ///
  /// In en, this message translates to:
  /// **'book'**
  String get book_word;

  /// No description provided for @books_word.
  ///
  /// In en, this message translates to:
  /// **'books'**
  String get books_word;

  /// No description provided for @target_books_required.
  ///
  /// In en, this message translates to:
  /// **'Target Books *'**
  String get target_books_required;

  /// No description provided for @target_pages_optional.
  ///
  /// In en, this message translates to:
  /// **'Target Pages (optional)'**
  String get target_pages_optional;

  /// No description provided for @notes_optional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notes_optional;

  /// No description provided for @notes_hint.
  ///
  /// In en, this message translates to:
  /// **'Any notes about this challenge'**
  String get notes_hint;

  /// No description provided for @custom_challenges.
  ///
  /// In en, this message translates to:
  /// **'Custom Challenges'**
  String get custom_challenges;

  /// No description provided for @custom_challenges_hint.
  ///
  /// In en, this message translates to:
  /// **'Add custom reading goals (e.g., \"Read 5 classics\", \"Finish 3 series\")'**
  String get custom_challenges_hint;

  /// No description provided for @goal_name.
  ///
  /// In en, this message translates to:
  /// **'Goal name'**
  String get goal_name;

  /// No description provided for @goal_name_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Read 5 classics'**
  String get goal_name_hint;

  /// No description provided for @target.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get target;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @unit_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g., books, chapters, pages'**
  String get unit_hint;

  /// No description provided for @enter_valid_target_books.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid target books'**
  String get enter_valid_target_books;

  /// No description provided for @enter_valid_target_or_custom.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid target books or add custom challenges'**
  String get enter_valid_target_or_custom;

  /// No description provided for @challenge_created.
  ///
  /// In en, this message translates to:
  /// **'Challenge created successfully!'**
  String get challenge_created;

  /// No description provided for @error_creating_challenge.
  ///
  /// In en, this message translates to:
  /// **'Error creating challenge: {error}'**
  String error_creating_challenge(Object error);

  /// No description provided for @challenge_updated.
  ///
  /// In en, this message translates to:
  /// **'Challenge updated successfully!'**
  String get challenge_updated;

  /// No description provided for @error_updating_challenge.
  ///
  /// In en, this message translates to:
  /// **'Error updating challenge: {error}'**
  String error_updating_challenge(Object error);

  /// No description provided for @confirm_delete_challenge.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the {year} challenge?'**
  String confirm_delete_challenge(Object year);

  /// No description provided for @challenge_deleted.
  ///
  /// In en, this message translates to:
  /// **'Challenge deleted'**
  String get challenge_deleted;

  /// No description provided for @error_deleting_challenge.
  ///
  /// In en, this message translates to:
  /// **'Error deleting challenge: {error}'**
  String error_deleting_challenge(Object error);

  /// No description provided for @current_progress.
  ///
  /// In en, this message translates to:
  /// **'Current Progress'**
  String get current_progress;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @challenge_progress_updated.
  ///
  /// In en, this message translates to:
  /// **'Challenge progress updated!'**
  String get challenge_progress_updated;

  /// No description provided for @current_label.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current_label;

  /// No description provided for @books_label.
  ///
  /// In en, this message translates to:
  /// **'Books:'**
  String get books_label;

  /// No description provided for @pages_label.
  ///
  /// In en, this message translates to:
  /// **'Pages:'**
  String get pages_label;

  /// No description provided for @new_challenge.
  ///
  /// In en, this message translates to:
  /// **'New Challenge'**
  String get new_challenge;

  /// No description provided for @bundle_reading_sessions.
  ///
  /// In en, this message translates to:
  /// **'Bundle Reading Sessions'**
  String get bundle_reading_sessions;

  /// No description provided for @book_n.
  ///
  /// In en, this message translates to:
  /// **'Book {n}'**
  String book_n(Object n);

  /// No description provided for @session_n.
  ///
  /// In en, this message translates to:
  /// **'Session {n}'**
  String session_n(Object n);

  /// No description provided for @no_reading_sessions.
  ///
  /// In en, this message translates to:
  /// **'No reading sessions'**
  String get no_reading_sessions;

  /// No description provided for @not_set.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get not_set;

  /// No description provided for @start_date.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get start_date;

  /// No description provided for @end_date.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get end_date;

  /// No description provided for @started_reading.
  ///
  /// In en, this message translates to:
  /// **'Started reading!'**
  String get started_reading;

  /// No description provided for @marked_as_finished.
  ///
  /// In en, this message translates to:
  /// **'Marked as finished!'**
  String get marked_as_finished;

  /// No description provided for @marked_as_read.
  ///
  /// In en, this message translates to:
  /// **'Marked as read!'**
  String get marked_as_read;

  /// No description provided for @error_refetching_metadata.
  ///
  /// In en, this message translates to:
  /// **'Error refetching metadata: {error}'**
  String error_refetching_metadata(Object error);

  /// No description provided for @reading_history.
  ///
  /// In en, this message translates to:
  /// **'Reading History'**
  String get reading_history;

  /// No description provided for @reading_sessions.
  ///
  /// In en, this message translates to:
  /// **'Reading Sessions'**
  String get reading_sessions;

  /// No description provided for @no_reading_history.
  ///
  /// In en, this message translates to:
  /// **'No reading history'**
  String get no_reading_history;

  /// No description provided for @no_sessions_recorded.
  ///
  /// In en, this message translates to:
  /// **'No sessions recorded'**
  String get no_sessions_recorded;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @show_more.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get show_more;

  /// No description provided for @show_less.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get show_less;

  /// No description provided for @no_description_available.
  ///
  /// In en, this message translates to:
  /// **'No description available'**
  String get no_description_available;

  /// No description provided for @books_in_bundle.
  ///
  /// In en, this message translates to:
  /// **'Books in Bundle'**
  String get books_in_bundle;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @price_label.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price_label;

  /// No description provided for @original_book.
  ///
  /// In en, this message translates to:
  /// **'Original Book'**
  String get original_book;

  /// No description provided for @view_original.
  ///
  /// In en, this message translates to:
  /// **'View Original'**
  String get view_original;

  /// No description provided for @start_reading.
  ///
  /// In en, this message translates to:
  /// **'Start Reading'**
  String get start_reading;

  /// No description provided for @mark_as_finished.
  ///
  /// In en, this message translates to:
  /// **'Mark as Finished'**
  String get mark_as_finished;

  /// No description provided for @mark_as_read.
  ///
  /// In en, this message translates to:
  /// **'Mark as Read'**
  String get mark_as_read;

  /// No description provided for @confirm_finish_title.
  ///
  /// In en, this message translates to:
  /// **'Finish Reading'**
  String get confirm_finish_title;

  /// No description provided for @confirm_mark_read_title.
  ///
  /// In en, this message translates to:
  /// **'Mark as Read'**
  String get confirm_mark_read_title;

  /// No description provided for @reading_clubs.
  ///
  /// In en, this message translates to:
  /// **'Reading Clubs'**
  String get reading_clubs;

  /// No description provided for @add_to_club.
  ///
  /// In en, this message translates to:
  /// **'Add to Club'**
  String get add_to_club;

  /// No description provided for @new_club.
  ///
  /// In en, this message translates to:
  /// **'New Club'**
  String get new_club;

  /// No description provided for @enter_club_name.
  ///
  /// In en, this message translates to:
  /// **'Enter club name'**
  String get enter_club_name;

  /// No description provided for @remove_from_club.
  ///
  /// In en, this message translates to:
  /// **'Remove from club?'**
  String get remove_from_club;

  /// No description provided for @removed_from_club.
  ///
  /// In en, this message translates to:
  /// **'Removed from {club}'**
  String removed_from_club(Object club);

  /// No description provided for @added_to_club.
  ///
  /// In en, this message translates to:
  /// **'Added to {club}'**
  String added_to_club(Object club);

  /// No description provided for @total_bundles.
  ///
  /// In en, this message translates to:
  /// **'Total bundles: {count}'**
  String total_bundles(Object count);

  /// No description provided for @individual_books_created.
  ///
  /// In en, this message translates to:
  /// **'📚 Individual books created: {count}'**
  String individual_books_created(Object count);

  /// No description provided for @migration_failed.
  ///
  /// In en, this message translates to:
  /// **'Migration failed: {error}'**
  String migration_failed(Object error);

  /// No description provided for @pages_empty.
  ///
  /// In en, this message translates to:
  /// **'Pages Empty'**
  String get pages_empty;

  /// No description provided for @is_bundle.
  ///
  /// In en, this message translates to:
  /// **'Is Bundle'**
  String get is_bundle;

  /// No description provided for @is_tandem.
  ///
  /// In en, this message translates to:
  /// **'Is Tandem'**
  String get is_tandem;

  /// No description provided for @publication_year_empty_filter.
  ///
  /// In en, this message translates to:
  /// **'Publication Year Empty'**
  String get publication_year_empty_filter;

  /// No description provided for @publication_date.
  ///
  /// In en, this message translates to:
  /// **'Publication Date'**
  String get publication_date;

  /// No description provided for @read_count.
  ///
  /// In en, this message translates to:
  /// **'Read Count'**
  String get read_count;

  /// No description provided for @reading_progress.
  ///
  /// In en, this message translates to:
  /// **'Reading Progress'**
  String get reading_progress;

  /// No description provided for @enter_book_title.
  ///
  /// In en, this message translates to:
  /// **'Enter book title'**
  String get enter_book_title;

  /// No description provided for @enter_author_names.
  ///
  /// In en, this message translates to:
  /// **'Enter author name(s), separate with commas'**
  String get enter_author_names;

  /// No description provided for @select_month.
  ///
  /// In en, this message translates to:
  /// **'Select Month'**
  String get select_month;

  /// No description provided for @no_books_this_month.
  ///
  /// In en, this message translates to:
  /// **'No books read this month'**
  String get no_books_this_month;

  /// No description provided for @select_winner.
  ///
  /// In en, this message translates to:
  /// **'Select Winner'**
  String get select_winner;

  /// No description provided for @confirm_selection.
  ///
  /// In en, this message translates to:
  /// **'Confirm Selection'**
  String get confirm_selection;

  /// No description provided for @past_years_winners.
  ///
  /// In en, this message translates to:
  /// **'Past Years Winners'**
  String get past_years_winners;

  /// No description provided for @no_past_winners.
  ///
  /// In en, this message translates to:
  /// **'No past winners yet'**
  String get no_past_winners;

  /// No description provided for @migrate_sessions_description.
  ///
  /// In en, this message translates to:
  /// **'This will migrate {sessions} reading session(s) from {bundles} bundle(s) to individual books.'**
  String migrate_sessions_description(Object sessions, Object bundles);

  /// No description provided for @migrate_bundles_description.
  ///
  /// In en, this message translates to:
  /// **'This will convert {count} old-style bundles to the new system.\n\nIndividual book records will be created for each book in the bundle.\n\nThis cannot be undone.'**
  String migrate_bundles_description(Object count);

  /// No description provided for @import_from_tag.
  ///
  /// In en, this message translates to:
  /// **'Import from Tag'**
  String get import_from_tag;

  /// No description provided for @import_options.
  ///
  /// In en, this message translates to:
  /// **'Import Options ({format})'**
  String import_options(Object format);

  /// No description provided for @update_reading_progress.
  ///
  /// In en, this message translates to:
  /// **'Update Reading Progress'**
  String get update_reading_progress;

  /// No description provided for @percentage.
  ///
  /// In en, this message translates to:
  /// **'Percentage'**
  String get percentage;

  /// No description provided for @pages_label_short.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get pages_label_short;

  /// No description provided for @progress_percentage.
  ///
  /// In en, this message translates to:
  /// **'Progress (%)'**
  String get progress_percentage;

  /// No description provided for @current_page.
  ///
  /// In en, this message translates to:
  /// **'Current Page'**
  String get current_page;

  /// No description provided for @total_pages.
  ///
  /// In en, this message translates to:
  /// **'Total pages: {count}'**
  String total_pages(Object count);

  /// No description provided for @percentage_cannot_exceed_100.
  ///
  /// In en, this message translates to:
  /// **'Percentage cannot exceed 100'**
  String get percentage_cannot_exceed_100;

  /// No description provided for @page_cannot_exceed.
  ///
  /// In en, this message translates to:
  /// **'Page number cannot exceed {count}'**
  String page_cannot_exceed(Object count);

  /// No description provided for @progress_updated.
  ///
  /// In en, this message translates to:
  /// **'Progress updated!'**
  String get progress_updated;

  /// No description provided for @did_you_read_today.
  ///
  /// In en, this message translates to:
  /// **'I have read today'**
  String get did_you_read_today;

  /// No description provided for @did_you_read_this_book_today.
  ///
  /// In en, this message translates to:
  /// **'Did you read this book today?'**
  String get did_you_read_this_book_today;

  /// No description provided for @yes_label.
  ///
  /// In en, this message translates to:
  /// **'YES'**
  String get yes_label;

  /// No description provided for @no_label.
  ///
  /// In en, this message translates to:
  /// **'NO'**
  String get no_label;

  /// No description provided for @marked_read_today.
  ///
  /// In en, this message translates to:
  /// **'Marked as read today!'**
  String get marked_read_today;

  /// No description provided for @marked_not_read_today.
  ///
  /// In en, this message translates to:
  /// **'Marked as not read today.'**
  String get marked_not_read_today;

  /// No description provided for @edit_reading_sessions.
  ///
  /// In en, this message translates to:
  /// **'Edit Reading Sessions'**
  String get edit_reading_sessions;

  /// No description provided for @session_label.
  ///
  /// In en, this message translates to:
  /// **'Session {index}'**
  String session_label(Object index);

  /// No description provided for @date_label.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date_label;

  /// No description provided for @time_hhmmss.
  ///
  /// In en, this message translates to:
  /// **'Time (HH:MM)'**
  String get time_hhmmss;

  /// No description provided for @duration_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter duration as: 1h 30m 5s, 90m, or just seconds'**
  String get duration_hint;

  /// No description provided for @sessions_updated.
  ///
  /// In en, this message translates to:
  /// **'Sessions updated!'**
  String get sessions_updated;

  /// No description provided for @add_reading_session.
  ///
  /// In en, this message translates to:
  /// **'Add Reading Session'**
  String get add_reading_session;

  /// No description provided for @session_added.
  ///
  /// In en, this message translates to:
  /// **'Session added!'**
  String get session_added;

  /// No description provided for @reading_time.
  ///
  /// In en, this message translates to:
  /// **'Reading Time'**
  String get reading_time;

  /// No description provided for @reading_time_details.
  ///
  /// In en, this message translates to:
  /// **'Reading Time Details'**
  String get reading_time_details;

  /// No description provided for @book_took_days.
  ///
  /// In en, this message translates to:
  /// **'This book took {days} {dayWord} to read.'**
  String book_took_days(Object days, Object dayWord);

  /// No description provided for @calculation_method.
  ///
  /// In en, this message translates to:
  /// **'Calculation Method: {method}'**
  String calculation_method(Object method);

  /// No description provided for @days_with_time_tracking.
  ///
  /// In en, this message translates to:
  /// **'Days with time tracking: {count}'**
  String days_with_time_tracking(Object count);

  /// No description provided for @days_with_reading_flag.
  ///
  /// In en, this message translates to:
  /// **'Days with reading flag only: {count}'**
  String days_with_reading_flag(Object count);

  /// No description provided for @days_marked_as_read.
  ///
  /// In en, this message translates to:
  /// **'Days marked as read: {count}'**
  String days_marked_as_read(Object count);

  /// No description provided for @start_date_label.
  ///
  /// In en, this message translates to:
  /// **'Start date: {date}'**
  String start_date_label(Object date);

  /// No description provided for @end_date_label.
  ///
  /// In en, this message translates to:
  /// **'End date: {date}'**
  String end_date_label(Object date);

  /// No description provided for @bundle_books_calculated.
  ///
  /// In en, this message translates to:
  /// **'Bundle: {count} books calculated'**
  String bundle_books_calculated(Object count);

  /// No description provided for @confirm_delete_title.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirm_delete_title;

  /// No description provided for @book_details.
  ///
  /// In en, this message translates to:
  /// **'Book Details'**
  String get book_details;

  /// No description provided for @fetching_cover.
  ///
  /// In en, this message translates to:
  /// **'Fetching cover...'**
  String get fetching_cover;

  /// No description provided for @no_cover_image.
  ///
  /// In en, this message translates to:
  /// **'No cover image'**
  String get no_cover_image;

  /// No description provided for @failed_to_load_image.
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get failed_to_load_image;

  /// No description provided for @added_to_tbr.
  ///
  /// In en, this message translates to:
  /// **'Added to TBR'**
  String get added_to_tbr;

  /// No description provided for @removed_from_tbr.
  ///
  /// In en, this message translates to:
  /// **'Removed from TBR'**
  String get removed_from_tbr;

  /// No description provided for @remove_from_tbr.
  ///
  /// In en, this message translates to:
  /// **'Remove from TBR'**
  String get remove_from_tbr;

  /// No description provided for @add_to_tbr_short.
  ///
  /// In en, this message translates to:
  /// **'Add to TBR'**
  String get add_to_tbr_short;

  /// No description provided for @tap_to_update_progress.
  ///
  /// In en, this message translates to:
  /// **'Tap to update progress'**
  String get tap_to_update_progress;

  /// No description provided for @day_word.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get day_word;

  /// No description provided for @days_word.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days_word;

  /// No description provided for @original_publication_year_label.
  ///
  /// In en, this message translates to:
  /// **'Original Publication Year'**
  String get original_publication_year_label;

  /// No description provided for @original_publication_date_label.
  ///
  /// In en, this message translates to:
  /// **'Original Publication Date'**
  String get original_publication_date_label;

  /// No description provided for @confirm_finish_message.
  ///
  /// In en, this message translates to:
  /// **'Mark this book as finished?'**
  String get confirm_finish_message;

  /// No description provided for @confirm_mark_read_message.
  ///
  /// In en, this message translates to:
  /// **'Mark this book as read?'**
  String get confirm_mark_read_message;

  /// No description provided for @error_deleting_book.
  ///
  /// In en, this message translates to:
  /// **'Error deleting book: {error}'**
  String error_deleting_book(Object error);

  /// No description provided for @refresh_metadata.
  ///
  /// In en, this message translates to:
  /// **'Refresh metadata'**
  String get refresh_metadata;

  /// No description provided for @tbr_list_subtitle.
  ///
  /// In en, this message translates to:
  /// **'This book is in your TBR list'**
  String get tbr_list_subtitle;

  /// No description provided for @open_library.
  ///
  /// In en, this message translates to:
  /// **'Open Library'**
  String get open_library;

  /// No description provided for @google_books.
  ///
  /// In en, this message translates to:
  /// **'Google Books'**
  String get google_books;

  /// No description provided for @error_loading_bundle_books.
  ///
  /// In en, this message translates to:
  /// **'Error loading bundle books'**
  String get error_loading_bundle_books;

  /// No description provided for @no_books_in_bundle.
  ///
  /// In en, this message translates to:
  /// **'No books in bundle'**
  String get no_books_in_bundle;

  /// No description provided for @no_status.
  ///
  /// In en, this message translates to:
  /// **'No status'**
  String get no_status;

  /// No description provided for @created_label.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get created_label;

  /// No description provided for @bundle_timed_reading_sessions.
  ///
  /// In en, this message translates to:
  /// **'Bundle Timed Reading Sessions'**
  String get bundle_timed_reading_sessions;

  /// No description provided for @tbr_label.
  ///
  /// In en, this message translates to:
  /// **'To Be Read'**
  String get tbr_label;

  /// No description provided for @release_notification.
  ///
  /// In en, this message translates to:
  /// **'Release Notification'**
  String get release_notification;

  /// No description provided for @scheduled_for.
  ///
  /// In en, this message translates to:
  /// **'Scheduled for {date}'**
  String scheduled_for(Object date);

  /// No description provided for @my_rating_label.
  ///
  /// In en, this message translates to:
  /// **'My Rating'**
  String get my_rating_label;

  /// No description provided for @fetching_description.
  ///
  /// In en, this message translates to:
  /// **'Fetching description...'**
  String get fetching_description;

  /// No description provided for @total_reading_time.
  ///
  /// In en, this message translates to:
  /// **'Total reading time: {hours} hours'**
  String total_reading_time(Object hours);

  /// No description provided for @finish_book.
  ///
  /// In en, this message translates to:
  /// **'Finish Book'**
  String get finish_book;

  /// No description provided for @rating_breakdown.
  ///
  /// In en, this message translates to:
  /// **'Rating Breakdown'**
  String get rating_breakdown;

  /// No description provided for @manual_rating.
  ///
  /// In en, this message translates to:
  /// **'Manual rating'**
  String get manual_rating;

  /// No description provided for @auto_calculated.
  ///
  /// In en, this message translates to:
  /// **'Auto-calculated'**
  String get auto_calculated;

  /// No description provided for @read_today_check.
  ///
  /// In en, this message translates to:
  /// **'Read today ✓'**
  String get read_today_check;

  /// No description provided for @copied_to_clipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied: {value}'**
  String copied_to_clipboard(Object value);

  /// No description provided for @tandem_books.
  ///
  /// In en, this message translates to:
  /// **'Tandem Books'**
  String get tandem_books;

  /// No description provided for @read_together_with.
  ///
  /// In en, this message translates to:
  /// **'Read together with these books'**
  String get read_together_with;

  /// No description provided for @no_tandem_books.
  ///
  /// In en, this message translates to:
  /// **'No other tandem books in this saga'**
  String get no_tandem_books;

  /// No description provided for @rate_reading_experience.
  ///
  /// In en, this message translates to:
  /// **'Rate your reading experience:'**
  String get rate_reading_experience;

  /// No description provided for @no_rating_fields.
  ///
  /// In en, this message translates to:
  /// **'No rating fields available. You can add them in Settings.'**
  String get no_rating_fields;

  /// No description provided for @write_review_optional.
  ///
  /// In en, this message translates to:
  /// **'Write a review (optional):'**
  String get write_review_optional;

  /// No description provided for @share_your_thoughts.
  ///
  /// In en, this message translates to:
  /// **'Share your thoughts...'**
  String get share_your_thoughts;

  /// No description provided for @saga_completion_setup.
  ///
  /// In en, this message translates to:
  /// **'Saga Completion Setup'**
  String get saga_completion_setup;

  /// No description provided for @you_are_adding.
  ///
  /// In en, this message translates to:
  /// **'You are adding: \"{name}\"'**
  String you_are_adding(Object name);

  /// No description provided for @how_many_books_saga.
  ///
  /// In en, this message translates to:
  /// **'How many books should this saga show in statistics?'**
  String get how_many_books_saga;

  /// No description provided for @saga_completion_explanation.
  ///
  /// In en, this message translates to:
  /// **'The saga completion card will show \"X / Y\" where Y is the number you specify.'**
  String get saga_completion_explanation;

  /// No description provided for @number_of_books.
  ///
  /// In en, this message translates to:
  /// **'Number of books'**
  String get number_of_books;

  /// No description provided for @examples.
  ///
  /// In en, this message translates to:
  /// **'Examples:'**
  String get examples;

  /// No description provided for @value_label.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get value_label;

  /// No description provided for @value_added_successfully.
  ///
  /// In en, this message translates to:
  /// **'Value added successfully'**
  String get value_added_successfully;

  /// No description provided for @value_updated_successfully.
  ///
  /// In en, this message translates to:
  /// **'Value updated successfully'**
  String get value_updated_successfully;

  /// No description provided for @value_deleted_successfully.
  ///
  /// In en, this message translates to:
  /// **'Value deleted successfully'**
  String get value_deleted_successfully;

  /// No description provided for @core_status_warning.
  ///
  /// In en, this message translates to:
  /// **'Core status: Only the label will change, not the database value or logic.'**
  String get core_status_warning;

  /// No description provided for @core_format_saga_warning.
  ///
  /// In en, this message translates to:
  /// **'Core format saga: Only the label can be changed, this value cannot be deleted.'**
  String get core_format_saga_warning;

  /// No description provided for @core_status_cannot_delete.
  ///
  /// In en, this message translates to:
  /// **'This is a core status value and cannot be deleted. The app logic depends on these values: Yes, No, Started, TBReleased, Abandoned, Repeated, and Standby.'**
  String get core_status_cannot_delete;

  /// No description provided for @core_format_saga_cannot_delete.
  ///
  /// In en, this message translates to:
  /// **'This is a core format saga value and cannot be deleted. The app logic depends on these values: Standalone, Bilogy, Trilogy, Tetralogy, Pentalogy, Hexalogy, 6+, and Saga.'**
  String get core_format_saga_cannot_delete;

  /// No description provided for @core_value_cannot_delete.
  ///
  /// In en, this message translates to:
  /// **'Core value cannot be deleted'**
  String get core_value_cannot_delete;

  /// No description provided for @select_category.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get select_category;

  /// No description provided for @value_in_use.
  ///
  /// In en, this message translates to:
  /// **'The value \"{value}\" is used by {count} book(s).'**
  String value_in_use(Object value, Object count);

  /// No description provided for @what_would_you_like_to_do.
  ///
  /// In en, this message translates to:
  /// **'What would you like to do?'**
  String get what_would_you_like_to_do;

  /// No description provided for @replace_with_existing.
  ///
  /// In en, this message translates to:
  /// **'Replace with existing value'**
  String get replace_with_existing;

  /// No description provided for @select_replacement.
  ///
  /// In en, this message translates to:
  /// **'Select replacement'**
  String get select_replacement;

  /// No description provided for @new_value.
  ///
  /// In en, this message translates to:
  /// **'New value'**
  String get new_value;

  /// No description provided for @delete_may_fail.
  ///
  /// In en, this message translates to:
  /// **'This will fail if database constraints prevent it'**
  String get delete_may_fail;

  /// No description provided for @please_select_replacement.
  ///
  /// In en, this message translates to:
  /// **'Please select a replacement value'**
  String get please_select_replacement;

  /// No description provided for @please_enter_new_value.
  ///
  /// In en, this message translates to:
  /// **'Please enter a new value'**
  String get please_enter_new_value;

  /// No description provided for @year_label.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year_label;

  /// No description provided for @target_books.
  ///
  /// In en, this message translates to:
  /// **'Target Books'**
  String get target_books;

  /// No description provided for @target_pages.
  ///
  /// In en, this message translates to:
  /// **'Target Pages'**
  String get target_pages;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get optional;

  /// No description provided for @any_notes_about_challenge.
  ///
  /// In en, this message translates to:
  /// **'Any notes about this challenge'**
  String get any_notes_about_challenge;

  /// No description provided for @add_custom_reading_goals.
  ///
  /// In en, this message translates to:
  /// **'Add custom reading goals (e.g., \"Read 5 classics\", \"Finish 3 series\")'**
  String get add_custom_reading_goals;

  /// No description provided for @no_challenges_yet.
  ///
  /// In en, this message translates to:
  /// **'No challenges yet'**
  String get no_challenges_yet;

  /// No description provided for @create_first_challenge.
  ///
  /// In en, this message translates to:
  /// **'Create your first reading challenge!'**
  String get create_first_challenge;

  /// No description provided for @field_name_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Romance, Action, Suspense'**
  String get field_name_hint;

  /// No description provided for @updated_field_name.
  ///
  /// In en, this message translates to:
  /// **'Updated \"{oldName}\" to \"{newName}\"'**
  String updated_field_name(Object oldName, Object newName);

  /// No description provided for @confirm_delete_club.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{clubName}\"?\n\nThis will remove {count} book(s) from this club.'**
  String confirm_delete_club(Object clubName, Object count);

  /// No description provided for @book_count_label.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{book} other{books}}'**
  String book_count_label(num count);

  /// No description provided for @what_would_you_like_next.
  ///
  /// In en, this message translates to:
  /// **'What would you like to do next?'**
  String get what_would_you_like_next;

  /// No description provided for @reading_status.
  ///
  /// In en, this message translates to:
  /// **'Reading Status'**
  String get reading_status;

  /// No description provided for @original_book_required.
  ///
  /// In en, this message translates to:
  /// **'Original Book (required for Repeated status)'**
  String get original_book_required;

  /// No description provided for @missing_required_fields.
  ///
  /// In en, this message translates to:
  /// **'Missing Required Fields'**
  String get missing_required_fields;

  /// No description provided for @please_fill_required_fields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in the following required fields:'**
  String get please_fill_required_fields;

  /// No description provided for @tandem_requires_saga.
  ///
  /// In en, this message translates to:
  /// **'Tandem books must have a Saga or Saga Universe.\n\nPlease fill in at least one of these fields to mark this book as Tandem.'**
  String get tandem_requires_saga;

  /// No description provided for @search_original_book.
  ///
  /// In en, this message translates to:
  /// **'Search for the original book...'**
  String get search_original_book;

  /// No description provided for @original_book_is_required.
  ///
  /// In en, this message translates to:
  /// **'Original book is required'**
  String get original_book_is_required;

  /// No description provided for @asin.
  ///
  /// In en, this message translates to:
  /// **'ASIN'**
  String get asin;

  /// No description provided for @search_or_add_author.
  ///
  /// In en, this message translates to:
  /// **'Type to search or add new author'**
  String get search_or_add_author;

  /// No description provided for @select_publisher.
  ///
  /// In en, this message translates to:
  /// **'Select publisher'**
  String get select_publisher;

  /// No description provided for @genres.
  ///
  /// In en, this message translates to:
  /// **'Genre(s)'**
  String get genres;

  /// No description provided for @search_or_add_genre.
  ///
  /// In en, this message translates to:
  /// **'Type to search or add new genre'**
  String get search_or_add_genre;

  /// No description provided for @original_publication_date.
  ///
  /// In en, this message translates to:
  /// **'Original Publication Date (for notifications)'**
  String get original_publication_date;

  /// No description provided for @release_date.
  ///
  /// In en, this message translates to:
  /// **'Release Date'**
  String get release_date;

  /// No description provided for @select_release_date.
  ///
  /// In en, this message translates to:
  /// **'Select release date'**
  String get select_release_date;

  /// No description provided for @get_notified_when_released.
  ///
  /// In en, this message translates to:
  /// **'Get notified when this book is released'**
  String get get_notified_when_released;

  /// No description provided for @notification_date_time.
  ///
  /// In en, this message translates to:
  /// **'Notification Date & Time'**
  String get notification_date_time;

  /// No description provided for @select_notification_date.
  ///
  /// In en, this message translates to:
  /// **'Select notification date and time'**
  String get select_notification_date;

  /// No description provided for @book_lists.
  ///
  /// In en, this message translates to:
  /// **'Book Lists'**
  String get book_lists;

  /// No description provided for @mark_for_reading_list.
  ///
  /// In en, this message translates to:
  /// **'Mark this book for your reading list'**
  String get mark_for_reading_list;

  /// No description provided for @tbr_limit_message.
  ///
  /// In en, this message translates to:
  /// **'You have reached your TBR limit of {limit} books.\n\nPlease uncheck some books in the My Books screen to add more.'**
  String tbr_limit_message(Object limit);

  /// No description provided for @mark_as_tandem.
  ///
  /// In en, this message translates to:
  /// **'Mark as Tandem Book'**
  String get mark_as_tandem;

  /// No description provided for @tandem_description.
  ///
  /// In en, this message translates to:
  /// **'Read together with other books in this saga'**
  String get tandem_description;

  /// No description provided for @reading_information_optional.
  ///
  /// In en, this message translates to:
  /// **'Reading Information (Optional)'**
  String get reading_information_optional;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @no_ratings_yet.
  ///
  /// In en, this message translates to:
  /// **'No ratings yet'**
  String get no_ratings_yet;

  /// No description provided for @average.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get average;

  /// No description provided for @criterion.
  ///
  /// In en, this message translates to:
  /// **'Criterion'**
  String get criterion;

  /// No description provided for @general_rating.
  ///
  /// In en, this message translates to:
  /// **'General Rating'**
  String get general_rating;

  /// No description provided for @manual.
  ///
  /// In en, this message translates to:
  /// **'manual'**
  String get manual;

  /// No description provided for @override_auto_calculation.
  ///
  /// In en, this message translates to:
  /// **'Override auto-calculation'**
  String get override_auto_calculation;

  /// No description provided for @manually_set_rating.
  ///
  /// In en, this message translates to:
  /// **'Manually set the general rating'**
  String get manually_set_rating;

  /// No description provided for @write_your_thoughts.
  ///
  /// In en, this message translates to:
  /// **'Write your thoughts about this book...'**
  String get write_your_thoughts;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @enter_book_price.
  ///
  /// In en, this message translates to:
  /// **'Enter book price'**
  String get enter_book_price;

  /// No description provided for @add_notes_hint.
  ///
  /// In en, this message translates to:
  /// **'Add any additional notes about this book...'**
  String get add_notes_hint;

  /// No description provided for @point_camera_at_barcode.
  ///
  /// In en, this message translates to:
  /// **'Point camera at barcode'**
  String get point_camera_at_barcode;

  /// No description provided for @test_notification_sent.
  ///
  /// In en, this message translates to:
  /// **'Test notification sent!'**
  String get test_notification_sent;

  /// No description provided for @test_notification.
  ///
  /// In en, this message translates to:
  /// **'Test Notification'**
  String get test_notification;

  /// No description provided for @timed_reading_sessions.
  ///
  /// In en, this message translates to:
  /// **'Timed Reading Sessions'**
  String get timed_reading_sessions;

  /// No description provided for @update_book.
  ///
  /// In en, this message translates to:
  /// **'Update Book'**
  String get update_book;

  /// No description provided for @reading_session_saved.
  ///
  /// In en, this message translates to:
  /// **'Reading session saved'**
  String get reading_session_saved;

  /// No description provided for @stop_timer_confirm.
  ///
  /// In en, this message translates to:
  /// **'Do you want to stop the reading timer?'**
  String get stop_timer_confirm;

  /// No description provided for @reading_timer.
  ///
  /// In en, this message translates to:
  /// **'Reading Timer'**
  String get reading_timer;

  /// No description provided for @timer_exit_confirm.
  ///
  /// In en, this message translates to:
  /// **'The timer is still counting. Are you sure you want to exit without stopping it?'**
  String get timer_exit_confirm;

  /// No description provided for @exit_label.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit_label;

  /// No description provided for @stop_and_save.
  ///
  /// In en, this message translates to:
  /// **'Stop & Save'**
  String get stop_and_save;

  /// No description provided for @backup_created.
  ///
  /// In en, this message translates to:
  /// **'Backup created successfully'**
  String get backup_created;

  /// No description provided for @restore_canceled.
  ///
  /// In en, this message translates to:
  /// **'Restore canceled'**
  String get restore_canceled;

  /// No description provided for @restore_warning.
  ///
  /// In en, this message translates to:
  /// **'This will replace your current database. Make sure you have a backup!'**
  String get restore_warning;

  /// No description provided for @restore_database.
  ///
  /// In en, this message translates to:
  /// **'Restore Database'**
  String get restore_database;

  /// No description provided for @restore_from_backup.
  ///
  /// In en, this message translates to:
  /// **'Restore from a previous backup'**
  String get restore_from_backup;

  /// No description provided for @backup_restored_successfully.
  ///
  /// In en, this message translates to:
  /// **'Backup restored successfully'**
  String get backup_restored_successfully;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @session.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get session;

  /// No description provided for @book_already_in_club.
  ///
  /// In en, this message translates to:
  /// **'Book is already in \"{clubName}\"'**
  String book_already_in_club(Object clubName);

  /// No description provided for @club_membership_updated.
  ///
  /// In en, this message translates to:
  /// **'Club membership updated'**
  String get club_membership_updated;

  /// No description provided for @remove_book_from_club.
  ///
  /// In en, this message translates to:
  /// **'Remove this book from \"{clubName}\"?'**
  String remove_book_from_club(Object clubName);

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @not_in_any_clubs.
  ///
  /// In en, this message translates to:
  /// **'Not in any clubs yet'**
  String get not_in_any_clubs;

  /// No description provided for @bundle_description.
  ///
  /// In en, this message translates to:
  /// **'Check if this book contains multiple books in one volume'**
  String get bundle_description;

  /// No description provided for @eg_3.
  ///
  /// In en, this message translates to:
  /// **'e.g., 3'**
  String get eg_3;

  /// No description provided for @eg_1_or_1_5.
  ///
  /// In en, this message translates to:
  /// **'e.g., 1 or 1.5'**
  String get eg_1_or_1_5;

  /// No description provided for @eg_2020.
  ///
  /// In en, this message translates to:
  /// **'e.g., 2020'**
  String get eg_2020;

  /// No description provided for @map_status_values.
  ///
  /// In en, this message translates to:
  /// **'Map Status Values'**
  String get map_status_values;

  /// No description provided for @match_csv_status_values.
  ///
  /// In en, this message translates to:
  /// **'Match your CSV status values to app statuses:'**
  String get match_csv_status_values;

  /// No description provided for @leave_empty_if_not_used.
  ///
  /// In en, this message translates to:
  /// **'Leave empty if not used in your CSV'**
  String get leave_empty_if_not_used;

  /// No description provided for @continue_import.
  ///
  /// In en, this message translates to:
  /// **'Continue Import'**
  String get continue_import;

  /// No description provided for @edit_club_membership.
  ///
  /// In en, this message translates to:
  /// **'Edit Club Membership'**
  String get edit_club_membership;

  /// No description provided for @add_to_reading_club.
  ///
  /// In en, this message translates to:
  /// **'Add to Reading Club'**
  String get add_to_reading_club;

  /// No description provided for @enter_or_select_club_name.
  ///
  /// In en, this message translates to:
  /// **'Enter or select club name'**
  String get enter_or_select_club_name;

  /// No description provided for @please_enter_club_name.
  ///
  /// In en, this message translates to:
  /// **'Please enter a club name'**
  String get please_enter_club_name;

  /// No description provided for @target_date_optional.
  ///
  /// In en, this message translates to:
  /// **'Target Date (Optional)'**
  String get target_date_optional;

  /// No description provided for @select_date.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get select_date;

  /// No description provided for @reading_progress_percent.
  ///
  /// In en, this message translates to:
  /// **'Reading Progress (%)'**
  String get reading_progress_percent;

  /// No description provided for @please_enter_progress.
  ///
  /// In en, this message translates to:
  /// **'Please enter progress'**
  String get please_enter_progress;

  /// No description provided for @progress_must_be_0_100.
  ///
  /// In en, this message translates to:
  /// **'Progress must be between 0 and 100'**
  String get progress_must_be_0_100;

  /// No description provided for @track_reading_progress.
  ///
  /// In en, this message translates to:
  /// **'Track your reading progress for this club'**
  String get track_reading_progress;

  /// No description provided for @how_import_books.
  ///
  /// In en, this message translates to:
  /// **'How would you like to import your books?'**
  String get how_import_books;

  /// No description provided for @select_or_enter_tag.
  ///
  /// In en, this message translates to:
  /// **'Select or enter a tag:'**
  String get select_or_enter_tag;

  /// No description provided for @available_tags.
  ///
  /// In en, this message translates to:
  /// **'Available tags'**
  String get available_tags;

  /// No description provided for @or_enter_custom_tag.
  ///
  /// In en, this message translates to:
  /// **'Or enter a custom tag'**
  String get or_enter_custom_tag;

  /// No description provided for @eg_owned_wishlist.
  ///
  /// In en, this message translates to:
  /// **'e.g., owned, wishlist'**
  String get eg_owned_wishlist;

  /// No description provided for @please_select_or_enter_tag.
  ///
  /// In en, this message translates to:
  /// **'Please select or enter a tag'**
  String get please_select_or_enter_tag;

  /// No description provided for @import_label.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import_label;

  /// No description provided for @add_books_to.
  ///
  /// In en, this message translates to:
  /// **'Add Books to'**
  String get add_books_to;

  /// No description provided for @books_selected.
  ///
  /// In en, this message translates to:
  /// **'{count} book(s) selected'**
  String books_selected(Object count);

  /// No description provided for @search_for_books_to_add.
  ///
  /// In en, this message translates to:
  /// **'Search for books to add'**
  String get search_for_books_to_add;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @add_n_books.
  ///
  /// In en, this message translates to:
  /// **'Add {count} Book(s)'**
  String add_n_books(Object count);

  /// No description provided for @book.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get book;

  /// No description provided for @tbr_limit_set_to.
  ///
  /// In en, this message translates to:
  /// **'TBR limit set to {limit} books'**
  String tbr_limit_set_to(Object limit);

  /// No description provided for @all_label.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all_label;

  /// No description provided for @read_label.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get read_label;

  /// No description provided for @based_on_publication_year.
  ///
  /// In en, this message translates to:
  /// **'Based on original publication year'**
  String get based_on_publication_year;

  /// No description provided for @create_challenge.
  ///
  /// In en, this message translates to:
  /// **'Create Challenge'**
  String get create_challenge;

  /// No description provided for @seasonal_reading_patterns.
  ///
  /// In en, this message translates to:
  /// **'Seasonal Reading Patterns'**
  String get seasonal_reading_patterns;

  /// No description provided for @avg_books_per_season.
  ///
  /// In en, this message translates to:
  /// **'Average: {count} books per season'**
  String avg_books_per_season(Object count);

  /// No description provided for @most.
  ///
  /// In en, this message translates to:
  /// **'Most'**
  String get most;

  /// No description provided for @least.
  ///
  /// In en, this message translates to:
  /// **'Least'**
  String get least;

  /// No description provided for @per_year.
  ///
  /// In en, this message translates to:
  /// **'per year'**
  String get per_year;

  /// No description provided for @seasonal_reading_preferences.
  ///
  /// In en, this message translates to:
  /// **'Seasonal Reading Preferences'**
  String get seasonal_reading_preferences;

  /// No description provided for @you_read_most_in.
  ///
  /// In en, this message translates to:
  /// **'You read most in'**
  String get you_read_most_in;

  /// No description provided for @no_reading_data_available.
  ///
  /// In en, this message translates to:
  /// **'No reading data available'**
  String get no_reading_data_available;

  /// No description provided for @reading_goals_progress.
  ///
  /// In en, this message translates to:
  /// **'Reading Goals Progress'**
  String get reading_goals_progress;

  /// No description provided for @available_now.
  ///
  /// In en, this message translates to:
  /// **'Available Now'**
  String get available_now;

  /// No description provided for @set_and_track_reading_goals.
  ///
  /// In en, this message translates to:
  /// **'Set and track reading goals'**
  String get set_and_track_reading_goals;

  /// No description provided for @annual_book_page_challenges.
  ///
  /// In en, this message translates to:
  /// **'Annual book and page challenges'**
  String get annual_book_page_challenges;

  /// No description provided for @tap_to_manage_challenges.
  ///
  /// In en, this message translates to:
  /// **'Tap to manage challenges'**
  String get tap_to_manage_challenges;

  /// No description provided for @reading_efficiency_score.
  ///
  /// In en, this message translates to:
  /// **'Reading Efficiency Score'**
  String get reading_efficiency_score;

  /// No description provided for @books_faster_than_average.
  ///
  /// In en, this message translates to:
  /// **'of books read faster than your average pace'**
  String get books_faster_than_average;

  /// No description provided for @what_does_this_mean.
  ///
  /// In en, this message translates to:
  /// **'What does this mean?'**
  String get what_does_this_mean;

  /// No description provided for @efficiency_explanation.
  ///
  /// In en, this message translates to:
  /// **'This compares each book\'s reading speed to your overall average. Higher percentages mean you\'re consistently reading at or above your typical pace.'**
  String get efficiency_explanation;

  /// No description provided for @based_on_n_books.
  ///
  /// In en, this message translates to:
  /// **'Based on {count} books with complete data'**
  String based_on_n_books(Object count);

  /// No description provided for @average_rating.
  ///
  /// In en, this message translates to:
  /// **'Average Rating'**
  String get average_rating;

  /// No description provided for @based_on_rated_books.
  ///
  /// In en, this message translates to:
  /// **'Based on {count} rated books'**
  String based_on_rated_books(Object count);

  /// No description provided for @monthly_reading_heatmap.
  ///
  /// In en, this message translates to:
  /// **'Monthly Reading Heatmap'**
  String get monthly_reading_heatmap;

  /// No description provided for @books_finished_per_month.
  ///
  /// In en, this message translates to:
  /// **'Books finished per month'**
  String get books_finished_per_month;

  /// No description provided for @less.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get less;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @reading_insights.
  ///
  /// In en, this message translates to:
  /// **'Reading Insights'**
  String get reading_insights;

  /// No description provided for @reading_streaks.
  ///
  /// In en, this message translates to:
  /// **'Reading Streaks'**
  String get reading_streaks;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @best.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get best;

  /// No description provided for @re_reads.
  ///
  /// In en, this message translates to:
  /// **'Re-reads'**
  String get re_reads;

  /// No description provided for @series_vs_standalone.
  ///
  /// In en, this message translates to:
  /// **'Series vs Standalone'**
  String get series_vs_standalone;

  /// No description provided for @series.
  ///
  /// In en, this message translates to:
  /// **'series'**
  String get series;

  /// No description provided for @standalone.
  ///
  /// In en, this message translates to:
  /// **'standalone'**
  String get standalone;

  /// No description provided for @personal_bests.
  ///
  /// In en, this message translates to:
  /// **'Personal Bests'**
  String get personal_bests;

  /// No description provided for @most_in_month.
  ///
  /// In en, this message translates to:
  /// **'Most in month'**
  String get most_in_month;

  /// No description provided for @fastest.
  ///
  /// In en, this message translates to:
  /// **'Fastest'**
  String get fastest;

  /// No description provided for @next_milestone_owned.
  ///
  /// In en, this message translates to:
  /// **'Next Milestone (Books Owned)'**
  String get next_milestone_owned;

  /// No description provided for @to_go.
  ///
  /// In en, this message translates to:
  /// **'to go'**
  String get to_go;

  /// No description provided for @next_milestone_read.
  ///
  /// In en, this message translates to:
  /// **'Next Milestone (Books Read)'**
  String get next_milestone_read;

  /// No description provided for @binge_reading_series.
  ///
  /// In en, this message translates to:
  /// **'Binge Reading (Series)'**
  String get binge_reading_series;

  /// No description provided for @binge_reading_description.
  ///
  /// In en, this message translates to:
  /// **'of books finished within 14 days of previous'**
  String get binge_reading_description;

  /// No description provided for @best_past_books.
  ///
  /// In en, this message translates to:
  /// **'Best Past Books'**
  String get best_past_books;

  /// No description provided for @reading_goals_progress_title.
  ///
  /// In en, this message translates to:
  /// **'Reading Goals Progress'**
  String get reading_goals_progress_title;

  /// No description provided for @no_challenge_set_for_year.
  ///
  /// In en, this message translates to:
  /// **'No challenge set for {year}'**
  String no_challenge_set_for_year(Object year);

  /// No description provided for @reading_goals.
  ///
  /// In en, this message translates to:
  /// **'Reading Goals'**
  String get reading_goals;

  /// No description provided for @dnf_rate.
  ///
  /// In en, this message translates to:
  /// **'DNF Rate'**
  String get dnf_rate;

  /// No description provided for @books_by_rating_distribution.
  ///
  /// In en, this message translates to:
  /// **'Books by Rating Distribution'**
  String get books_by_rating_distribution;

  /// No description provided for @page_count_distribution.
  ///
  /// In en, this message translates to:
  /// **'Page Count Distribution'**
  String get page_count_distribution;

  /// No description provided for @book_extremes.
  ///
  /// In en, this message translates to:
  /// **'Book Extremes'**
  String get book_extremes;

  /// No description provided for @oldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get oldest;

  /// No description provided for @newest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get newest;

  /// No description provided for @shortest.
  ///
  /// In en, this message translates to:
  /// **'Shortest'**
  String get shortest;

  /// No description provided for @longest.
  ///
  /// In en, this message translates to:
  /// **'Longest'**
  String get longest;

  /// No description provided for @no_books_read_in_year.
  ///
  /// In en, this message translates to:
  /// **'No books read in {year}'**
  String no_books_read_in_year(Object year);

  /// No description provided for @and_n_more.
  ///
  /// In en, this message translates to:
  /// **'and {count} more'**
  String and_n_more(Object count);

  /// No description provided for @reading_time_of_day.
  ///
  /// In en, this message translates to:
  /// **'Reading Time of Day'**
  String get reading_time_of_day;

  /// No description provided for @coming_soon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get coming_soon;

  /// No description provided for @track_when_you_read_most.
  ///
  /// In en, this message translates to:
  /// **'Track when you read most'**
  String get track_when_you_read_most;

  /// No description provided for @morning_afternoon_night_owl.
  ///
  /// In en, this message translates to:
  /// **'Morning, afternoon, or night owl?'**
  String get morning_afternoon_night_owl;

  /// No description provided for @requires_chronometer.
  ///
  /// In en, this message translates to:
  /// **'Requires chronometer feature'**
  String get requires_chronometer;

  /// No description provided for @saga_completion_rate.
  ///
  /// In en, this message translates to:
  /// **'Saga Completion Rate'**
  String get saga_completion_rate;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @in_progress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get in_progress;

  /// No description provided for @not_started.
  ///
  /// In en, this message translates to:
  /// **'Not Started'**
  String get not_started;

  /// No description provided for @my_books.
  ///
  /// In en, this message translates to:
  /// **'My Books'**
  String get my_books;

  /// No description provided for @no_re_read_books_yet.
  ///
  /// In en, this message translates to:
  /// **'No re-read books yet'**
  String get no_re_read_books_yet;

  /// No description provided for @read_n_times.
  ///
  /// In en, this message translates to:
  /// **'Read {count} times'**
  String read_n_times(Object count);

  /// No description provided for @decade.
  ///
  /// In en, this message translates to:
  /// **'Decade'**
  String get decade;

  /// No description provided for @past_years_competitions.
  ///
  /// In en, this message translates to:
  /// **'Past Years Competitions'**
  String get past_years_competitions;

  /// No description provided for @no_past_competitions_found.
  ///
  /// In en, this message translates to:
  /// **'No past competitions found'**
  String get no_past_competitions_found;

  /// No description provided for @no_winner_set.
  ///
  /// In en, this message translates to:
  /// **'No winner set'**
  String get no_winner_set;

  /// No description provided for @no_books_for_author.
  ///
  /// In en, this message translates to:
  /// **'No books found for this author'**
  String get no_books_for_author;

  /// No description provided for @added_books_to_saga.
  ///
  /// In en, this message translates to:
  /// **'Added {count} book(s) to {type}'**
  String added_books_to_saga(Object count, Object type);

  /// No description provided for @no_books_in_saga.
  ///
  /// In en, this message translates to:
  /// **'No books found in this {type}'**
  String no_books_in_saga(Object type);

  /// No description provided for @no_completed_sagas.
  ///
  /// In en, this message translates to:
  /// **'No completed sagas yet'**
  String get no_completed_sagas;

  /// No description provided for @no_sagas_in_progress.
  ///
  /// In en, this message translates to:
  /// **'No sagas in progress'**
  String get no_sagas_in_progress;

  /// No description provided for @no_unstarted_sagas.
  ///
  /// In en, this message translates to:
  /// **'No unstarted sagas'**
  String get no_unstarted_sagas;

  /// No description provided for @complete_label.
  ///
  /// In en, this message translates to:
  /// **'complete'**
  String get complete_label;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @no_books_in_year.
  ///
  /// In en, this message translates to:
  /// **'No books read in this year'**
  String get no_books_in_year;

  /// No description provided for @year_winner.
  ///
  /// In en, this message translates to:
  /// **'Year Winner'**
  String get year_winner;

  /// No description provided for @final_round.
  ///
  /// In en, this message translates to:
  /// **'Final'**
  String get final_round;

  /// No description provided for @please_select_book.
  ///
  /// In en, this message translates to:
  /// **'Please select a book'**
  String get please_select_book;

  /// No description provided for @select_winner_title.
  ///
  /// In en, this message translates to:
  /// **'Select {period} Winner'**
  String select_winner_title(Object period);

  /// No description provided for @selected_as_winner.
  ///
  /// In en, this message translates to:
  /// **'{name} selected as winner!'**
  String selected_as_winner(Object name);

  /// No description provided for @no_monthly_winners_quarter.
  ///
  /// In en, this message translates to:
  /// **'No monthly winners for this quarter'**
  String get no_monthly_winners_quarter;

  /// No description provided for @no_quarterly_winners.
  ///
  /// In en, this message translates to:
  /// **'No quarterly winners available'**
  String get no_quarterly_winners;

  /// No description provided for @no_semifinal_winners.
  ///
  /// In en, this message translates to:
  /// **'No semifinal winners available'**
  String get no_semifinal_winners;

  /// No description provided for @select_yearly_winner.
  ///
  /// In en, this message translates to:
  /// **'Select {year} Yearly Winner'**
  String select_yearly_winner(Object year);

  /// No description provided for @semifinal.
  ///
  /// In en, this message translates to:
  /// **'Semifinal'**
  String get semifinal;

  /// No description provided for @no_books_currently_reading.
  ///
  /// In en, this message translates to:
  /// **'No books currently reading'**
  String get no_books_currently_reading;

  /// No description provided for @no_books_on_standby.
  ///
  /// In en, this message translates to:
  /// **'No books on standby'**
  String get no_books_on_standby;

  /// No description provided for @reading_label.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get reading_label;

  /// No description provided for @standby_label.
  ///
  /// In en, this message translates to:
  /// **'Standby'**
  String get standby_label;

  /// No description provided for @tbr_title.
  ///
  /// In en, this message translates to:
  /// **'To Be Read (TBR)'**
  String get tbr_title;

  /// No description provided for @no_books_in_tbr.
  ///
  /// In en, this message translates to:
  /// **'No books in TBR'**
  String get no_books_in_tbr;

  /// No description provided for @add_books_to_clubs.
  ///
  /// In en, this message translates to:
  /// **'Add books to clubs from book details'**
  String get add_books_to_clubs;

  /// No description provided for @clubs.
  ///
  /// In en, this message translates to:
  /// **'Clubs'**
  String get clubs;

  /// No description provided for @random_book_picker.
  ///
  /// In en, this message translates to:
  /// **'Random Book Picker'**
  String get random_book_picker;

  /// No description provided for @random_book_description.
  ///
  /// In en, this message translates to:
  /// **'Apply filters and get a random book suggestion'**
  String get random_book_description;

  /// No description provided for @and_all_genres.
  ///
  /// In en, this message translates to:
  /// **'AND: must have all selected genres'**
  String get and_all_genres;

  /// No description provided for @or_any_genre.
  ///
  /// In en, this message translates to:
  /// **'OR: matches any selected genre'**
  String get or_any_genre;

  /// No description provided for @and_not_practical.
  ///
  /// In en, this message translates to:
  /// **'AND: not practical (book has one status)'**
  String get and_not_practical;

  /// No description provided for @or_any_status.
  ///
  /// In en, this message translates to:
  /// **'OR: matches any selected status'**
  String get or_any_status;

  /// No description provided for @tbr_filter_label.
  ///
  /// In en, this message translates to:
  /// **'TBR (To Be Read)'**
  String get tbr_filter_label;

  /// No description provided for @yes_in_tbr.
  ///
  /// In en, this message translates to:
  /// **'Yes - In TBR'**
  String get yes_in_tbr;

  /// No description provided for @no_not_in_tbr.
  ///
  /// In en, this message translates to:
  /// **'No - Not in TBR'**
  String get no_not_in_tbr;

  /// No description provided for @publication_year_decade.
  ///
  /// In en, this message translates to:
  /// **'Publication Year (by decade)'**
  String get publication_year_decade;

  /// No description provided for @or_select_specific_books.
  ///
  /// In en, this message translates to:
  /// **'Or select specific books'**
  String get or_select_specific_books;

  /// No description provided for @search_select_books_description.
  ///
  /// In en, this message translates to:
  /// **'Search and select books by title to pick randomly from your custom list'**
  String get search_select_books_description;

  /// No description provided for @select_books.
  ///
  /// In en, this message translates to:
  /// **'Select Books'**
  String get select_books;

  /// No description provided for @type_to_search_books.
  ///
  /// In en, this message translates to:
  /// **'Type to search books by title'**
  String get type_to_search_books;

  /// No description provided for @random_from_selected.
  ///
  /// In en, this message translates to:
  /// **'Random from Selected ({count})'**
  String random_from_selected(Object count);

  /// No description provided for @try_another.
  ///
  /// In en, this message translates to:
  /// **'Try Another'**
  String get try_another;

  /// No description provided for @tap_to_view_details.
  ///
  /// In en, this message translates to:
  /// **'Tap card to view details'**
  String get tap_to_view_details;

  /// No description provided for @migration_completed_errors.
  ///
  /// In en, this message translates to:
  /// **'Migration Completed with Errors'**
  String get migration_completed_errors;

  /// No description provided for @about_bundle_migration.
  ///
  /// In en, this message translates to:
  /// **'About Bundle Migration'**
  String get about_bundle_migration;

  /// No description provided for @current_status.
  ///
  /// In en, this message translates to:
  /// **'Current Status'**
  String get current_status;

  /// No description provided for @old_style_bundles.
  ///
  /// In en, this message translates to:
  /// **'Old-style bundles'**
  String get old_style_bundles;

  /// No description provided for @new_style_bundles.
  ///
  /// In en, this message translates to:
  /// **'New-style bundles'**
  String get new_style_bundles;

  /// No description provided for @individual_bundle_books.
  ///
  /// In en, this message translates to:
  /// **'Individual bundle books'**
  String get individual_bundle_books;

  /// No description provided for @migrating.
  ///
  /// In en, this message translates to:
  /// **'Migrating...'**
  String get migrating;

  /// No description provided for @migrate_n_bundles.
  ///
  /// In en, this message translates to:
  /// **'Migrate {count} Bundles'**
  String migrate_n_bundles(Object count);

  /// No description provided for @no_migration_needed.
  ///
  /// In en, this message translates to:
  /// **'All bundles are using the new system!\nNo migration needed.'**
  String get no_migration_needed;

  /// No description provided for @last_migration_result.
  ///
  /// In en, this message translates to:
  /// **'Last Migration Result'**
  String get last_migration_result;

  /// No description provided for @resume_import.
  ///
  /// In en, this message translates to:
  /// **'Resume Import?'**
  String get resume_import;

  /// No description provided for @start_fresh.
  ///
  /// In en, this message translates to:
  /// **'Start Fresh'**
  String get start_fresh;

  /// No description provided for @import_all.
  ///
  /// In en, this message translates to:
  /// **'Import All'**
  String get import_all;

  /// No description provided for @no_csv_file_selected.
  ///
  /// In en, this message translates to:
  /// **'No CSV file selected'**
  String get no_csv_file_selected;

  /// No description provided for @clear_reviewed_books.
  ///
  /// In en, this message translates to:
  /// **'Clear Reviewed Books?'**
  String get clear_reviewed_books;

  /// No description provided for @clear_reviewed_books_description.
  ///
  /// In en, this message translates to:
  /// **'This will clear all tracked reviewed books from all import sessions. Use this if the count seems wrong.'**
  String get clear_reviewed_books_description;

  /// No description provided for @cleared_reviewed_books.
  ///
  /// In en, this message translates to:
  /// **'Cleared all reviewed books tracking'**
  String get cleared_reviewed_books;

  /// No description provided for @clear_reviewed_books_cache.
  ///
  /// In en, this message translates to:
  /// **'Clear Reviewed Books Cache'**
  String get clear_reviewed_books_cache;

  /// No description provided for @book_x_of_y.
  ///
  /// In en, this message translates to:
  /// **'Book {current} of {total}'**
  String book_x_of_y(Object current, Object total);

  /// No description provided for @n_to_import.
  ///
  /// In en, this message translates to:
  /// **'{count} to import'**
  String n_to_import(Object count);

  /// No description provided for @import_up_to_here.
  ///
  /// In en, this message translates to:
  /// **'Import Up To Here'**
  String get import_up_to_here;

  /// No description provided for @ignore.
  ///
  /// In en, this message translates to:
  /// **'Ignore'**
  String get ignore;

  /// No description provided for @next_label.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next_label;

  /// No description provided for @import_this_book.
  ///
  /// In en, this message translates to:
  /// **'Import this book'**
  String get import_this_book;

  /// No description provided for @storage_permission_needed.
  ///
  /// In en, this message translates to:
  /// **'Storage permission is needed to create backups. Would you like to grant permission?'**
  String get storage_permission_needed;

  /// No description provided for @import_error.
  ///
  /// In en, this message translates to:
  /// **'Import Error'**
  String get import_error;

  /// No description provided for @cloud_sync.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync'**
  String get cloud_sync;

  /// No description provided for @cloud_sync_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Backup and restore via Google'**
  String get cloud_sync_subtitle;

  /// No description provided for @sign_in_with_google.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get sign_in_with_google;

  /// No description provided for @sign_out.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get sign_out;

  /// No description provided for @signed_in_as.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String signed_in_as(Object email);

  /// No description provided for @backup_to_cloud.
  ///
  /// In en, this message translates to:
  /// **'Backup to Cloud'**
  String get backup_to_cloud;

  /// No description provided for @restore_from_cloud.
  ///
  /// In en, this message translates to:
  /// **'Restore from Cloud'**
  String get restore_from_cloud;

  /// No description provided for @upload_your_library.
  ///
  /// In en, this message translates to:
  /// **'Upload your library to Google Cloud'**
  String get upload_your_library;

  /// No description provided for @download_your_library.
  ///
  /// In en, this message translates to:
  /// **'Download your library from Google Cloud'**
  String get download_your_library;

  /// No description provided for @last_backup.
  ///
  /// In en, this message translates to:
  /// **'Last backup: {date}'**
  String last_backup(Object date);

  /// No description provided for @no_cloud_backup.
  ///
  /// In en, this message translates to:
  /// **'No cloud backup found'**
  String get no_cloud_backup;

  /// No description provided for @cloud_backup_success.
  ///
  /// In en, this message translates to:
  /// **'Backup uploaded successfully'**
  String get cloud_backup_success;

  /// No description provided for @cloud_restore_success.
  ///
  /// In en, this message translates to:
  /// **'Library restored from cloud'**
  String get cloud_restore_success;

  /// No description provided for @cloud_restore_warning.
  ///
  /// In en, this message translates to:
  /// **'This will replace ALL your current data with the cloud backup. This cannot be undone.'**
  String get cloud_restore_warning;

  /// No description provided for @cloud_backup_in_progress.
  ///
  /// In en, this message translates to:
  /// **'Uploading backup...'**
  String get cloud_backup_in_progress;

  /// No description provided for @cloud_restore_in_progress.
  ///
  /// In en, this message translates to:
  /// **'Downloading backup...'**
  String get cloud_restore_in_progress;

  /// No description provided for @sign_in_required.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to use cloud backup'**
  String get sign_in_required;

  /// No description provided for @sign_in_failed.
  ///
  /// In en, this message translates to:
  /// **'Sign in failed'**
  String get sign_in_failed;

  /// No description provided for @no_internet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get no_internet;

  /// No description provided for @cloud_backup_books.
  ///
  /// In en, this message translates to:
  /// **'{count} books'**
  String cloud_backup_books(Object count);

  /// No description provided for @auto_backup.
  ///
  /// In en, this message translates to:
  /// **'Auto Backup'**
  String get auto_backup;

  /// No description provided for @auto_backup_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically back up locally and to cloud when you open the app'**
  String get auto_backup_subtitle;

  /// No description provided for @auto_backup_enabled.
  ///
  /// In en, this message translates to:
  /// **'Auto backup enabled: {frequency}'**
  String auto_backup_enabled(Object frequency);

  /// No description provided for @auto_backup_disabled.
  ///
  /// In en, this message translates to:
  /// **'Auto backup disabled'**
  String get auto_backup_disabled;

  /// No description provided for @backup_frequency_off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get backup_frequency_off;

  /// No description provided for @backup_frequency_daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get backup_frequency_daily;

  /// No description provided for @backup_frequency_weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get backup_frequency_weekly;

  /// No description provided for @backup_frequency_monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get backup_frequency_monthly;

  /// No description provided for @reading_reminders.
  ///
  /// In en, this message translates to:
  /// **'Reading Reminders'**
  String get reading_reminders;

  /// No description provided for @reading_reminders_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Daily notifications to track your reading'**
  String get reading_reminders_subtitle;

  /// No description provided for @enable_reading_reminders.
  ///
  /// In en, this message translates to:
  /// **'Enable Reading Reminders'**
  String get enable_reading_reminders;

  /// No description provided for @enable_reading_reminders_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Get a daily notification asking if you\'ve read today'**
  String get enable_reading_reminders_subtitle;

  /// No description provided for @reminder_time.
  ///
  /// In en, this message translates to:
  /// **'Reminder Time'**
  String get reminder_time;

  /// No description provided for @reminder_time_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Time to receive the daily notification'**
  String get reminder_time_subtitle;

  /// No description provided for @reminder_books_option.
  ///
  /// In en, this message translates to:
  /// **'Which Books to Remind'**
  String get reminder_books_option;

  /// No description provided for @reminder_all_started.
  ///
  /// In en, this message translates to:
  /// **'All started books'**
  String get reminder_all_started;

  /// No description provided for @reminder_last_started.
  ///
  /// In en, this message translates to:
  /// **'Last started book only'**
  String get reminder_last_started;

  /// No description provided for @reminder_all_started_subtitle.
  ///
  /// In en, this message translates to:
  /// **'One notification per book with Started status'**
  String get reminder_all_started_subtitle;

  /// No description provided for @reminder_last_started_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Only the most recently started book'**
  String get reminder_last_started_subtitle;

  /// No description provided for @have_you_read_today.
  ///
  /// In en, this message translates to:
  /// **'Have you read today?'**
  String get have_you_read_today;

  /// No description provided for @have_you_read_today_book.
  ///
  /// In en, this message translates to:
  /// **'Have you read today?: {bookTitle}'**
  String have_you_read_today_book(Object bookTitle);

  /// No description provided for @tap_to_open_book.
  ///
  /// In en, this message translates to:
  /// **'Tap to open book details'**
  String get tap_to_open_book;

  /// No description provided for @reading_reminder_enabled.
  ///
  /// In en, this message translates to:
  /// **'Reading reminders enabled'**
  String get reading_reminder_enabled;

  /// No description provided for @reading_reminder_disabled.
  ///
  /// In en, this message translates to:
  /// **'Reading reminders disabled'**
  String get reading_reminder_disabled;

  /// No description provided for @no_started_books_for_reminder.
  ///
  /// In en, this message translates to:
  /// **'No books with Started status to remind about'**
  String get no_started_books_for_reminder;

  /// No description provided for @fetch_book_info.
  ///
  /// In en, this message translates to:
  /// **'Fetch book info'**
  String get fetch_book_info;

  /// No description provided for @fetching_book_info.
  ///
  /// In en, this message translates to:
  /// **'Fetching book info...'**
  String get fetching_book_info;

  /// No description provided for @book_info_found.
  ///
  /// In en, this message translates to:
  /// **'Book info found and fields filled'**
  String get book_info_found;

  /// No description provided for @no_book_info_found.
  ///
  /// In en, this message translates to:
  /// **'No book info found for this ISBN'**
  String get no_book_info_found;

  /// No description provided for @isbn_required_for_fetch.
  ///
  /// In en, this message translates to:
  /// **'Enter an ISBN first'**
  String get isbn_required_for_fetch;

  /// No description provided for @review_pages_warning.
  ///
  /// In en, this message translates to:
  /// **'Review the number of pages, it may not be correct'**
  String get review_pages_warning;

  /// No description provided for @section_reading_activity.
  ///
  /// In en, this message translates to:
  /// **'Reading Activity'**
  String get section_reading_activity;

  /// No description provided for @section_library_breakdown.
  ///
  /// In en, this message translates to:
  /// **'Library Breakdown'**
  String get section_library_breakdown;

  /// No description provided for @section_top_rankings.
  ///
  /// In en, this message translates to:
  /// **'Top Rankings'**
  String get section_top_rankings;

  /// No description provided for @section_ratings_pages.
  ///
  /// In en, this message translates to:
  /// **'Ratings & Pages'**
  String get section_ratings_pages;

  /// No description provided for @section_sagas_series.
  ///
  /// In en, this message translates to:
  /// **'Sagas & Series'**
  String get section_sagas_series;

  /// No description provided for @section_reading_patterns.
  ///
  /// In en, this message translates to:
  /// **'Reading Patterns & Insights'**
  String get section_reading_patterns;

  /// No description provided for @section_coming_soon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get section_coming_soon;

  /// No description provided for @section_best_book_champions.
  ///
  /// In en, this message translates to:
  /// **'Best Book Champions'**
  String get section_best_book_champions;

  /// No description provided for @quick_stat_total_owned.
  ///
  /// In en, this message translates to:
  /// **'Owned'**
  String get quick_stat_total_owned;

  /// No description provided for @quick_stat_total_read.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get quick_stat_total_read;

  /// No description provided for @quick_stat_this_year.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get quick_stat_this_year;

  /// No description provided for @quick_stat_avg_rating.
  ///
  /// In en, this message translates to:
  /// **'Avg Rating'**
  String get quick_stat_avg_rating;

  /// No description provided for @quick_stat_streak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get quick_stat_streak;

  /// No description provided for @quick_stat_best_streak.
  ///
  /// In en, this message translates to:
  /// **'Best Streak'**
  String get quick_stat_best_streak;

  /// No description provided for @quick_stat_velocity.
  ///
  /// In en, this message translates to:
  /// **'Velocity'**
  String get quick_stat_velocity;

  /// No description provided for @quick_stat_avg_days.
  ///
  /// In en, this message translates to:
  /// **'Avg Days'**
  String get quick_stat_avg_days;

  /// No description provided for @quick_stat_books_year.
  ///
  /// In en, this message translates to:
  /// **'Books/Year'**
  String get quick_stat_books_year;

  /// No description provided for @quick_stat_dnf.
  ///
  /// In en, this message translates to:
  /// **'DNF'**
  String get quick_stat_dnf;

  /// No description provided for @quick_stat_rereads.
  ///
  /// In en, this message translates to:
  /// **'Re-reads'**
  String get quick_stat_rereads;

  /// No description provided for @quick_stat_series.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get quick_stat_series;

  /// No description provided for @quick_stat_sagas_done.
  ///
  /// In en, this message translates to:
  /// **'Sagas Done'**
  String get quick_stat_sagas_done;

  /// No description provided for @quick_stat_milestone_owned.
  ///
  /// In en, this message translates to:
  /// **'To Milestone'**
  String get quick_stat_milestone_owned;

  /// No description provided for @quick_stat_milestone_read.
  ///
  /// In en, this message translates to:
  /// **'To Read Goal'**
  String get quick_stat_milestone_read;

  /// No description provided for @quick_stat_choose.
  ///
  /// In en, this message translates to:
  /// **'Choose a stat'**
  String get quick_stat_choose;

  /// No description provided for @quick_stat_long_press_hint.
  ///
  /// In en, this message translates to:
  /// **'Long press to change'**
  String get quick_stat_long_press_hint;

  /// No description provided for @no_data_available.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get no_data_available;

  /// No description provided for @books_read_per_year.
  ///
  /// In en, this message translates to:
  /// **'Books Read Per Year'**
  String get books_read_per_year;

  /// No description provided for @pages_read_per_year.
  ///
  /// In en, this message translates to:
  /// **'Pages Read Per Year'**
  String get pages_read_per_year;

  /// No description provided for @reading_efficiency.
  ///
  /// In en, this message translates to:
  /// **'Reading Efficiency'**
  String get reading_efficiency;

  /// No description provided for @reading_velocity.
  ///
  /// In en, this message translates to:
  /// **'Reading Velocity'**
  String get reading_velocity;

  /// No description provided for @avg_days_to_finish.
  ///
  /// In en, this message translates to:
  /// **'Avg. Days to Finish'**
  String get avg_days_to_finish;

  /// No description provided for @avg_books_per_year.
  ///
  /// In en, this message translates to:
  /// **'Avg. Books Per Year'**
  String get avg_books_per_year;

  /// No description provided for @books_by_place.
  ///
  /// In en, this message translates to:
  /// **'Books by Place'**
  String get books_by_place;

  /// No description provided for @format_by_language.
  ///
  /// In en, this message translates to:
  /// **'Format by Language'**
  String get format_by_language;

  /// No description provided for @daily_reading_heatmap.
  ///
  /// In en, this message translates to:
  /// **'Days read in a year'**
  String get daily_reading_heatmap;

  /// No description provided for @days_read_summary.
  ///
  /// In en, this message translates to:
  /// **'Read {days} days out of {total} ({percent}%)'**
  String days_read_summary(Object days, Object total, Object percent);

  /// No description provided for @quick_stat_days_read.
  ///
  /// In en, this message translates to:
  /// **'Days Read'**
  String get quick_stat_days_read;

  /// No description provided for @show_price_statistics.
  ///
  /// In en, this message translates to:
  /// **'Show Price Statistics'**
  String get show_price_statistics;

  /// No description provided for @show_price_statistics_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Display a price statistics section in your stats dashboard'**
  String get show_price_statistics_subtitle;

  /// No description provided for @currency_setting.
  ///
  /// In en, this message translates to:
  /// **'Currency Symbol'**
  String get currency_setting;

  /// No description provided for @currency_setting_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose which currency symbol to display for prices'**
  String get currency_setting_subtitle;

  /// No description provided for @custom_currency_hint.
  ///
  /// In en, this message translates to:
  /// **'Custom symbol'**
  String get custom_currency_hint;

  /// No description provided for @no_price_data.
  ///
  /// In en, this message translates to:
  /// **'No books with price data yet. Add prices to your books to see statistics.'**
  String get no_price_data;

  /// No description provided for @section_price_statistics.
  ///
  /// In en, this message translates to:
  /// **'Price Statistics'**
  String get section_price_statistics;

  /// No description provided for @price_by_format.
  ///
  /// In en, this message translates to:
  /// **'Average Price by Format'**
  String get price_by_format;

  /// No description provided for @price_by_year.
  ///
  /// In en, this message translates to:
  /// **'Spending by Year'**
  String get price_by_year;

  /// No description provided for @price_by_month.
  ///
  /// In en, this message translates to:
  /// **'Spending by Month'**
  String get price_by_month;

  /// No description provided for @price_extremes.
  ///
  /// In en, this message translates to:
  /// **'Price Highlights'**
  String get price_extremes;

  /// No description provided for @total_spent.
  ///
  /// In en, this message translates to:
  /// **'Total Spent'**
  String get total_spent;

  /// No description provided for @most_expensive.
  ///
  /// In en, this message translates to:
  /// **'Most Expensive'**
  String get most_expensive;

  /// No description provided for @least_expensive.
  ///
  /// In en, this message translates to:
  /// **'Least Expensive'**
  String get least_expensive;

  /// No description provided for @price_range_evolution.
  ///
  /// In en, this message translates to:
  /// **'Price Range Evolution'**
  String get price_range_evolution;

  /// No description provided for @time_slot_morning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get time_slot_morning;

  /// No description provided for @time_slot_afternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get time_slot_afternoon;

  /// No description provided for @time_slot_night.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get time_slot_night;

  /// No description provided for @time_slot_late_night.
  ///
  /// In en, this message translates to:
  /// **'Early Hours'**
  String get time_slot_late_night;

  /// No description provided for @no_session_data.
  ///
  /// In en, this message translates to:
  /// **'No reading session data yet. Use the chronometer to track your reading sessions.'**
  String get no_session_data;

  /// No description provided for @favorite_reading_time.
  ///
  /// In en, this message translates to:
  /// **'Favorite: {slot}'**
  String favorite_reading_time(Object slot);

  /// No description provided for @full_catalog.
  ///
  /// In en, this message translates to:
  /// **'Full Catalog'**
  String get full_catalog;

  /// No description provided for @my_library_view.
  ///
  /// In en, this message translates to:
  /// **'My Library'**
  String get my_library_view;

  /// No description provided for @fetching_author_books.
  ///
  /// In en, this message translates to:
  /// **'Fetching author books...'**
  String get fetching_author_books;

  /// No description provided for @no_catalog_results.
  ///
  /// In en, this message translates to:
  /// **'No books found for this author'**
  String get no_catalog_results;

  /// No description provided for @loading_more.
  ///
  /// In en, this message translates to:
  /// **'Loading more...'**
  String get loading_more;

  /// No description provided for @standby_suggestion_title.
  ///
  /// In en, this message translates to:
  /// **'Move to Standby?'**
  String get standby_suggestion_title;

  /// No description provided for @standby_suggestion_body.
  ///
  /// In en, this message translates to:
  /// **'It\'s been more than a week since you last read this book. Would you like to move it to Standby? This won\'t affect your reading statistics.'**
  String get standby_suggestion_body;

  /// No description provided for @move_to_standby.
  ///
  /// In en, this message translates to:
  /// **'Move to Standby'**
  String get move_to_standby;

  /// No description provided for @keep_reading.
  ///
  /// In en, this message translates to:
  /// **'Keep Reading'**
  String get keep_reading;

  /// No description provided for @move_back_to_reading.
  ///
  /// In en, this message translates to:
  /// **'Resume Reading'**
  String get move_back_to_reading;

  /// No description provided for @moved_back_to_reading.
  ///
  /// In en, this message translates to:
  /// **'Book moved back to Reading'**
  String get moved_back_to_reading;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @appearance_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Theme and language settings'**
  String get appearance_subtitle;

  /// No description provided for @library_display.
  ///
  /// In en, this message translates to:
  /// **'Library Display'**
  String get library_display;

  /// No description provided for @library_display_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Home Filters, Card Fields, Sort Order, TBR Limit'**
  String get library_display_subtitle;

  /// No description provided for @library_customization.
  ///
  /// In en, this message translates to:
  /// **'Library Customization'**
  String get library_customization;

  /// No description provided for @library_customization_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Rating fields, clubs, dropdowns, price & currency'**
  String get library_customization_subtitle;

  /// No description provided for @migrations_section.
  ///
  /// In en, this message translates to:
  /// **'Migrations'**
  String get migrations_section;

  /// No description provided for @migrations_section_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Data migration tools'**
  String get migrations_section_subtitle;

  /// No description provided for @library_tools.
  ///
  /// In en, this message translates to:
  /// **'Library Tools'**
  String get library_tools;

  /// No description provided for @library_tools_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Bulk edit, fill empty fields, smart suggestions'**
  String get library_tools_subtitle;

  /// No description provided for @assign_books_to_value.
  ///
  /// In en, this message translates to:
  /// **'Assign Books to Value'**
  String get assign_books_to_value;

  /// No description provided for @assign_books_to_value_hint.
  ///
  /// In en, this message translates to:
  /// **'Pick a value, then select books to assign it to'**
  String get assign_books_to_value_hint;

  /// No description provided for @fill_empty_fields.
  ///
  /// In en, this message translates to:
  /// **'Fill Empty Fields'**
  String get fill_empty_fields;

  /// No description provided for @fill_empty_fields_hint.
  ///
  /// In en, this message translates to:
  /// **'Find books with missing data and fill them in groups'**
  String get fill_empty_fields_hint;

  /// No description provided for @smart_suggestions.
  ///
  /// In en, this message translates to:
  /// **'Smart Suggestions'**
  String get smart_suggestions;

  /// No description provided for @smart_suggestions_hint.
  ///
  /// In en, this message translates to:
  /// **'Auto-detect patterns and suggest bulk fixes'**
  String get smart_suggestions_hint;

  /// No description provided for @select_field.
  ///
  /// In en, this message translates to:
  /// **'Select Field'**
  String get select_field;

  /// No description provided for @select_value.
  ///
  /// In en, this message translates to:
  /// **'Select Value'**
  String get select_value;

  /// No description provided for @no_values_available.
  ///
  /// In en, this message translates to:
  /// **'No values available'**
  String get no_values_available;

  /// No description provided for @books_available.
  ///
  /// In en, this message translates to:
  /// **'books available'**
  String get books_available;

  /// No description provided for @all_books_already_have_value.
  ///
  /// In en, this message translates to:
  /// **'All books already have this value!'**
  String get all_books_already_have_value;

  /// No description provided for @deselect_all.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselect_all;

  /// No description provided for @apply_to_n_books.
  ///
  /// In en, this message translates to:
  /// **'Apply to {count} books'**
  String apply_to_n_books(int count);

  /// No description provided for @bulk_updated_books.
  ///
  /// In en, this message translates to:
  /// **'Updated {count} book(s) successfully'**
  String bulk_updated_books(int count);

  /// No description provided for @reverse_assign_info.
  ///
  /// In en, this message translates to:
  /// **'Showing books that don\'t have \"{value}\" as {field}'**
  String reverse_assign_info(String value, String field);

  /// No description provided for @select_field_to_fill.
  ///
  /// In en, this message translates to:
  /// **'Select a field to fill'**
  String get select_field_to_fill;

  /// No description provided for @no_books_with_empty_field.
  ///
  /// In en, this message translates to:
  /// **'All books have this field filled!'**
  String get no_books_with_empty_field;

  /// No description provided for @books_without_field.
  ///
  /// In en, this message translates to:
  /// **'{count} books without {field}'**
  String books_without_field(int count, String field);

  /// No description provided for @group_n_of_total.
  ///
  /// In en, this message translates to:
  /// **'Group {current} of {total}'**
  String group_n_of_total(int current, int total);

  /// No description provided for @other_books_have.
  ///
  /// In en, this message translates to:
  /// **'Other books by this author have: {values}'**
  String other_books_have(String values);

  /// No description provided for @apply_to_group.
  ///
  /// In en, this message translates to:
  /// **'Apply to Group'**
  String get apply_to_group;

  /// No description provided for @next_group.
  ///
  /// In en, this message translates to:
  /// **'Next Group'**
  String get next_group;

  /// No description provided for @previous_group.
  ///
  /// In en, this message translates to:
  /// **'Previous Group'**
  String get previous_group;

  /// No description provided for @no_groups_found.
  ///
  /// In en, this message translates to:
  /// **'No groups found'**
  String get no_groups_found;

  /// No description provided for @ungrouped.
  ///
  /// In en, this message translates to:
  /// **'Other Books'**
  String get ungrouped;

  /// No description provided for @books_in_group.
  ///
  /// In en, this message translates to:
  /// **'{count} books'**
  String books_in_group(int count);

  /// No description provided for @select_value_to_apply.
  ///
  /// In en, this message translates to:
  /// **'Select a value to apply'**
  String get select_value_to_apply;

  /// No description provided for @wizard_complete.
  ///
  /// In en, this message translates to:
  /// **'All groups processed!'**
  String get wizard_complete;

  /// No description provided for @wizard_complete_message.
  ///
  /// In en, this message translates to:
  /// **'You can go back to review or close this screen'**
  String get wizard_complete_message;

  /// No description provided for @generating_suggestions.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your library...'**
  String get generating_suggestions;

  /// No description provided for @no_suggestions.
  ///
  /// In en, this message translates to:
  /// **'No suggestions found. Your library data looks consistent!'**
  String get no_suggestions;

  /// No description provided for @suggestion_confidence.
  ///
  /// In en, this message translates to:
  /// **'{percent}% confidence'**
  String suggestion_confidence(int percent);

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @accept_all.
  ///
  /// In en, this message translates to:
  /// **'Accept All'**
  String get accept_all;

  /// No description provided for @n_suggestions_found.
  ///
  /// In en, this message translates to:
  /// **'{count} suggestions found'**
  String n_suggestions_found(int count);

  /// No description provided for @suggestion_applied.
  ///
  /// In en, this message translates to:
  /// **'Suggestion applied successfully'**
  String get suggestion_applied;

  /// No description provided for @suggestion_rejected.
  ///
  /// In en, this message translates to:
  /// **'Suggestion dismissed'**
  String get suggestion_rejected;

  /// No description provided for @apply_value_to_books.
  ///
  /// In en, this message translates to:
  /// **'Apply \"{value}\" ({field}) to {count} book(s)'**
  String apply_value_to_books(String value, String field, int count);

  /// No description provided for @affected_books.
  ///
  /// In en, this message translates to:
  /// **'Affected books:'**
  String get affected_books;

  /// No description provided for @all_suggestions_processed.
  ///
  /// In en, this message translates to:
  /// **'All suggestions have been processed!'**
  String get all_suggestions_processed;

  /// No description provided for @library_overview.
  ///
  /// In en, this message translates to:
  /// **'Library Overview'**
  String get library_overview;

  /// No description provided for @books_by_genre.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get books_by_genre;

  /// No description provided for @books_by_editorial.
  ///
  /// In en, this message translates to:
  /// **'Editorial'**
  String get books_by_editorial;

  /// No description provided for @books_by_author.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get books_by_author;
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

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get app_title => 'My Random Library';

  @override
  String get home => 'Home';

  @override
  String get statistics => 'Statistics';

  @override
  String get random => 'Random';

  @override
  String get settings => 'Settings';

  @override
  String get search_by_title => 'Title';

  @override
  String get search_by_isbn => 'ISBN/ASIN';

  @override
  String get search_by_author => 'Author';

  @override
  String get search_label => 'Search';

  @override
  String get search_hint => 'Search for books...';

  @override
  String get add_book => 'Add Book';

  @override
  String get edit_book => 'Edit Book';

  @override
  String get delete_book => 'Delete Book';

  @override
  String get unknown_title => 'Unknown Title';

  @override
  String get book_name => 'Book Name';

  @override
  String get isbn => 'ISBN';

  @override
  String isbn_with_colon(Object isbn) {
    return 'ISBN: $isbn';
  }

  @override
  String get author => 'Author';

  @override
  String author_with_colon(Object author) {
    return 'Author: $author';
  }

  @override
  String get saga => 'Saga';

  @override
  String saga_with_colon(Object saga) {
    return 'Saga: $saga';
  }

  @override
  String get saga_number => 'Saga Number';

  @override
  String get pages => 'Pages';

  @override
  String get publication_year => 'Publication Year';

  @override
  String get editorial => 'Editorial';

  @override
  String get genre => 'Genre';

  @override
  String genre_with_colon(Object genre) {
    return 'Genre: $genre';
  }

  @override
  String get place => 'Place';

  @override
  String get format => 'Format';

  @override
  String format_with_colon(Object format) {
    return 'Format: $format';
  }

  @override
  String get format_saga => 'Format Saga';

  @override
  String get status => 'Reading Status';

  @override
  String get loaned => 'Loaned';

  @override
  String get date_created => 'Created Date';

  @override
  String language_with_colon(Object language) {
    return 'Language: $language';
  }

  @override
  String get my_rating => 'My Rating';

  @override
  String get times_read => 'Times Read';

  @override
  String get date_started_reading => 'Date Started Reading';

  @override
  String get date_finished_reading => 'Date Finished Reading';

  @override
  String get my_review => 'My Review';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get clear => 'Clear';

  @override
  String get apply => 'Apply';

  @override
  String get delete => 'Delete';

  @override
  String get import_csv => 'Import from CSV';

  @override
  String get export_csv => 'Export to CSV';

  @override
  String get create_backup => 'Create Backup';

  @override
  String get backup_canceled => 'Backup Canceled';

  @override
  String backup_created_successfully(Object backup_path) {
    return 'Backup created successfully!\n $backup_path';
  }

  @override
  String get replace_database => 'Replace Database';

  @override
  String get database_restored_successfully => 'Database restored successfully!';

  @override
  String import_backup_error(Object error) {
    return 'Error importing backup: $error';
  }

  @override
  String error_importing_backup(Object error) {
    return 'Error importing backup: $error';
  }

  @override
  String get import_backup => 'Import Backup';

  @override
  String get import_database_backup => 'Import Database Backup';

  @override
  String get import_backup_confirmation => 'This will replace your current database with the backup. All current data will be lost. Are you sure?';

  @override
  String get select_backup_file => 'Select backup file';

  @override
  String get delete_all_data => 'Delete All Data';

  @override
  String get creating_backup => 'Creating Backup...';

  @override
  String get importing_books => 'Importing Books...';

  @override
  String get importing_backup => 'Importing Backup...';

  @override
  String get deleting_all_data => 'Deleting All Data...';

  @override
  String get delete_all_data_confirmation => 'This will permanently delete ALL books from your library. This action cannot be undone!\n\nAre you sure you want to continue?';

  @override
  String deleted_books(Object count) {
    return 'Deleted $count books successfully';
  }

  @override
  String error_creating_backup(Object error) {
    return 'Error creating backup: $error';
  }

  @override
  String error_importing_csv(Object error) {
    return 'Error importing CSV: $error';
  }

  @override
  String error_deleting_data(Object error) {
    return 'Error deleting data: $error';
  }

  @override
  String import_completed(Object importedCount, Object skippedCount) {
    return 'Import completed!\nImported: $importedCount books\nSkipped: $skippedCount rows';
  }

  @override
  String get import_completed_with_duplicates => 'Import completed with duplicates!';

  @override
  String imported_books(Object importedCount) {
    return 'Imported: $importedCount books';
  }

  @override
  String skipped_rows(Object skippedCount) {
    return 'Skipped: $skippedCount rows';
  }

  @override
  String duplicates_found(Object duplicateCount) {
    return 'Duplicates found: $duplicateCount books';
  }

  @override
  String get duplicate_books_not_imported => 'Duplicate books (not imported):';

  @override
  String get books_already_exist => 'These books already exist in your library. You can add them manually if needed.';

  @override
  String more_books(Object count) {
    return '... and $count more';
  }

  @override
  String get ok => 'OK';

  @override
  String get permanently_delete_all_books_from_the_database => 'Permanently delete all books from the database';

  @override
  String get light_theme_colors => 'Light Theme Colors';

  @override
  String get dark_theme_colors => 'Dark Theme Colors';

  @override
  String get theme_mode => 'Theme Mode';

  @override
  String get create_database_backup => 'Create Database Backup';

  @override
  String get save_a_copy_of_your_library_database => 'Save a copy of your library database';

  @override
  String get manage_dropdown_values => 'Manage Dropdown Values';

  @override
  String get manage_dropdown_values_hint => 'Manage dropdown values for status, language, place, format, and format saga.';

  @override
  String get import_from_csv_hint => 'Expected columns: read, title, author, publisher, genre, saga, n_saga, format_saga, isbn13, number of pages, original publication year, language, place, binding, loaned';

  @override
  String get import_from_csv_tbreleased => 'For unreleased books use status tb_released';

  @override
  String get import_from_csv => 'Import book from CSV';

  @override
  String get import_from_csv_file => 'Import books from a CSV file';

  @override
  String get restore_a_copy_of_your_library_database => 'Restore a copy of your library database';

  @override
  String get theme => 'Theme';

  @override
  String get theme_light => 'Light';

  @override
  String get theme_dark => 'Dark';

  @override
  String get theme_system => 'System';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get spanish => 'Spanish';

  @override
  String get total_books => 'Total Books';

  @override
  String get latest_book_added => 'Latest Book Added';

  @override
  String get books_by_status => 'Books by Status';

  @override
  String get books_by_language => 'Books by Language';

  @override
  String get books_by_format => 'Books by Format';

  @override
  String get no_books_in_database => 'No books in the database';

  @override
  String get top_10_editorials => 'Top 10 Editorials';

  @override
  String get top_10_authors => 'Top 10 Authors';

  @override
  String get get_random_book => 'Get Random Book';

  @override
  String get filters => 'Filters';

  @override
  String get any => 'Any';

  @override
  String get confirm_delete => 'Are you sure you want to delete this book?';

  @override
  String get confirm_delete_all => 'This will permanently delete ALL books from your library. This action cannot be undone!\\n\\nAre you sure you want to continue?';

  @override
  String get book_added_successfully => 'Book added successfully!';

  @override
  String get book_updated_successfully => 'Book updated successfully!';

  @override
  String get book_deleted_successfully => 'Book deleted successfully!';

  @override
  String get no_books_found => 'No books found';

  @override
  String get no_data => 'No data';

  @override
  String get reading_information => 'Reading Information (Optional)';

  @override
  String get add_read => 'Add Read';

  @override
  String get tap_hearts_to_rate => 'Tap hearts to rate (tap again for half)';

  @override
  String get top_5_genres => 'Top 5 Genres';

  @override
  String get about_box_children => 'Aplicación desarrollada con Flutter/Dart.\n Permite gestionar tu biblioteca personal y recibir recomendaciones de lectura personalizadas.';
}

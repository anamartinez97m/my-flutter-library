// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get app_title => 'My Book Vault';

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
  String get saga_universe => 'Saga Universe';

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
  String get add => 'Add';

  @override
  String get duration_label => 'Duration';

  @override
  String get enter_valid_number => 'Please enter a valid number (1 or greater)';

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

  @override
  String get sort_and_filter => 'Sort & Filter';

  @override
  String get empty => 'Empty';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get isbn_asin => 'ISBN/ASIN';

  @override
  String get bundle => 'Bundle';

  @override
  String get tandem => 'Tandem';

  @override
  String get saga_format_without_saga => 'Saga Format Without Saga';

  @override
  String get saga_format_without_n_saga => 'Saga Format Without N_Saga';

  @override
  String get saga_without_format_saga => 'Saga Without Format Saga';

  @override
  String get publication_year_empty => 'Publication Year';

  @override
  String get rating_filter => 'Rating';

  @override
  String pages_with_colon(Object pages) {
    return 'Pages: $pages';
  }

  @override
  String get max_tbr_books_description => 'Maximum number of books you can mark as \'To Be Read\' at once:';

  @override
  String max_tbr_books_subtitle(Object tbrLimit) {
    return 'Maximum books in \'To Be Read\': $tbrLimit';
  }

  @override
  String get set_tbr_limit => 'Set TBR Limit';

  @override
  String get tbr_limit => 'TBR Limit';

  @override
  String get books => 'books';

  @override
  String get please_enter_valid_number => 'Please enter a valid number greater than 0';

  @override
  String get maximum_limit_200_books => 'Maximum limit is 200 books';

  @override
  String get range_1_200_books => 'Range: 1-200 books';

  @override
  String get this_is_a_bundle => 'This is a bundle';

  @override
  String get check_if_this_book_contains_multiple_books => 'Check if this book contains multiple books in one volume';

  @override
  String get number_of_books_in_bundle => 'Number of Books in Bundle';

  @override
  String get saga_numbers_optional => 'Saga Numbers (optional)';

  @override
  String get saga_number_n_saga => 'Saga Number (N_Saga)';

  @override
  String get book_title => 'Book Title';

  @override
  String get authors => 'Author(s)';

  @override
  String get original_publication_year => 'Original Publication Year';

  @override
  String get started => 'Started';

  @override
  String get finished => 'Finished';

  @override
  String get search_books_by_title => 'Search books by title';

  @override
  String get stop_timer => 'Stop Timer';

  @override
  String get do_you_want_to_stop_the_reading_timer => 'Do you want to stop the reading timer?';

  @override
  String get stop => 'Stop';

  @override
  String get timer_is_running => 'Timer is Running';

  @override
  String get exit => 'Exit';

  @override
  String get start => 'Start';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get stop_save => 'Stop & Save';

  @override
  String get quick_add => 'Quick Add';

  @override
  String add_book_s(Object count) {
    return 'Add $count Book(s)';
  }

  @override
  String get bundle_book_details => 'Bundle Book Details';

  @override
  String select_label(Object label) {
    return 'Select $label';
  }

  @override
  String get full_date => 'Full Date';

  @override
  String get year_only => 'Year Only';

  @override
  String get add_session => 'Add Session';

  @override
  String get enter_year => 'Enter Year';

  @override
  String get please_enter_valid_year => 'Please enter a valid year';

  @override
  String get edit => 'Edit';

  @override
  String get close => 'Close';

  @override
  String get proceed => 'Proceed';

  @override
  String get create => 'Create';

  @override
  String get confirm => 'Confirm';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get warning => 'Warning';

  @override
  String get info => 'Information';

  @override
  String get loading => 'Loading';

  @override
  String get search => 'Search';

  @override
  String get filter => 'Filter';

  @override
  String get sort => 'Sort';

  @override
  String get reset => 'Reset';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String get stop_timer_question => 'Stop Timer?';

  @override
  String get confirm_restore => 'Confirm Restore';

  @override
  String get confirm_restore_message => 'This will replace your current database. Make sure you have a backup!';

  @override
  String get restore => 'Restore';

  @override
  String get add_another => 'Add Another';

  @override
  String get go_to_home => 'Go to Home';

  @override
  String get missing_information => 'Missing Information';

  @override
  String get enable_release_notification => 'Enable Release Notification';

  @override
  String get add_to_tbr => 'Add to TBR (To Be Read)';

  @override
  String get tbr_limit_reached => 'TBR Limit Reached';

  @override
  String get mark_as_tandem_book => 'Mark as Tandem Book';

  @override
  String get scan_isbn => 'Scan ISBN';

  @override
  String get customize_home_filters => 'Customize Home Filters';

  @override
  String get select_all => 'Select All';

  @override
  String get clear_all => 'Clear All';

  @override
  String books_removed_from_tbr(Object bookName) {
    return '$bookName removed from TBR';
  }

  @override
  String error_occurred(Object error) {
    return 'Error: $error';
  }

  @override
  String tbr_books_count(Object count) {
    return '$count';
  }

  @override
  String get no_books_from_decade => 'No books read from this decade';

  @override
  String decade_book_count(Object decade, Object totalCount) {
    return '$decade ($totalCount books)';
  }

  @override
  String get migrate_bundle_books => 'Migrate Bundle Books?';

  @override
  String get migrate => 'Migrate';

  @override
  String successful_migrations(Object count) {
    return '✅ Successful: $count';
  }

  @override
  String skipped_migrations(Object count) {
    return '⏭️  Skipped: $count';
  }

  @override
  String failed_migrations(Object count) {
    return '❌ Failed: $count';
  }

  @override
  String get import_from_goodreads => 'Import from Goodreads';

  @override
  String get import_all_books => 'Import all books';

  @override
  String get import_books_from_tag => 'Import books from a specific tag';

  @override
  String add_dropdown_value(Object valueType) {
    return 'Add $valueType';
  }

  @override
  String edit_dropdown_value(Object valueType) {
    return 'Edit $valueType';
  }

  @override
  String get cannot_delete => 'Cannot Delete';

  @override
  String get delete_value => 'Delete Value';

  @override
  String get replace_with_existing_value => 'Replace with existing value';

  @override
  String get create_new_value => 'Create new value';

  @override
  String get delete_completely => 'Delete completely (may fail)';

  @override
  String get new_year_challenge => 'New Year Challenge';

  @override
  String edit_year_challenge(Object year) {
    return 'Edit $year Challenge';
  }

  @override
  String get delete_challenge => 'Delete Challenge';

  @override
  String get year_challenges => 'Year Challenges';

  @override
  String best_book_of_year(Object year) {
    return 'Best Book of $year';
  }

  @override
  String get best_book_competition => 'Best Book Competition';

  @override
  String get winner => 'Winner';

  @override
  String get nominees => 'Nominees';

  @override
  String get tournament_tree => 'Tournament Tree';

  @override
  String get quarterly_winners => 'Quarterly Winners';

  @override
  String get semifinals => 'Semifinals';

  @override
  String get last => 'Last';

  @override
  String get monthly_winners => 'Monthly Winners';

  @override
  String no_books_read_year(Object year) {
    return 'No books read in $year';
  }

  @override
  String get no_competition_data => 'No competition data available';

  @override
  String error_loading_competition(Object error) {
    return 'Error loading competition data: $error';
  }

  @override
  String get update_available_title => 'Update Available';

  @override
  String get update_available_message => 'A new version of My Book Vault is available. Update now to get the latest features and improvements.';

  @override
  String get update_now => 'Update';

  @override
  String get update_later => 'Later';

  @override
  String get admin_mode => 'Admin Mode';

  @override
  String get admin_mode_subtitle => 'Enable advanced features like admin CSV import';

  @override
  String get admin_csv_import => 'Admin CSV Import';

  @override
  String get admin_csv_import_subtitle => 'Review and edit each book before importing';

  @override
  String get default_values => 'Default Values';

  @override
  String get default_values_subtitle => 'TBR Limit, Sort Order, Home Filters, Card Fields';

  @override
  String get import_export => 'Import/Export';

  @override
  String get import_export_subtitle => 'CSV & Database Backup';

  @override
  String get customize_home_filters_subtitle => 'Select which filters to show in the home screen';

  @override
  String get customize_card_fields => 'Customize Card Fields';

  @override
  String get customize_card_fields_subtitle => 'Select which data to show in book cards';

  @override
  String fields_selected(Object count) {
    return '$count fields selected';
  }

  @override
  String get default_sort_order => 'Default Sort Order';

  @override
  String get default_sort_order_subtitle => 'Set the default order for your book list';

  @override
  String get sort_by => 'Sort By';

  @override
  String get date_added => 'Date Added';

  @override
  String get ascending => 'Ascending';

  @override
  String get descending => 'Descending';

  @override
  String get export_to_csv => 'Export to CSV';

  @override
  String get export_to_excel => 'Export to Excel';

  @override
  String get for_reimport => 'For re-import';

  @override
  String get excel_compatible => 'Excel-compatible';

  @override
  String get preparing_csv_export => 'Preparing CSV export...';

  @override
  String get no_books_to_export => 'No books to export';

  @override
  String get export_canceled => 'Export canceled';

  @override
  String exported_books(Object count, Object path) {
    return 'Exported $count books to:\n$path';
  }

  @override
  String error_exporting_csv(Object error) {
    return 'Error exporting to CSV: $error';
  }

  @override
  String get permission_required => 'Permission Required';

  @override
  String get storage_permission_backup => 'Storage permission is needed to create backups. Would you like to grant permission?';

  @override
  String get storage_permission_export => 'Storage permission is needed to export CSV files. Would you like to grant permission?';

  @override
  String get grant_permission => 'Grant Permission';

  @override
  String get select_folder_save_backup => 'Select folder to save backup';

  @override
  String get select_csv_file => 'Select CSV file';

  @override
  String get select_folder_save_csv => 'Select folder to save CSV';

  @override
  String get select_folder_save_excel_csv => 'Select folder to save Excel CSV';

  @override
  String get please_select_csv_file => 'Please select a CSV file';

  @override
  String get importing_books_from_csv => 'Importing books from CSV...';

  @override
  String get import_completed_title => 'Import Completed';

  @override
  String import_result_message(Object imported, Object updated, Object skipped) {
    return 'Imported: $imported books\nUpdated: $updated books\nSkipped: $skipped rows';
  }

  @override
  String get select_tag => 'Select tag';

  @override
  String get deleting_all_books => 'Deleting all books...';

  @override
  String get goodreads_csv_hint => 'For Goodreads CSV: Books must have \"owned\" or \"read-loaned\" in bookshelves to be imported';

  @override
  String get manage_rating_field_names => 'Manage Rating Field Names';

  @override
  String get manage_rating_field_names_subtitle => 'Add, edit, or remove rating criterion names';

  @override
  String get manage_club_names => 'Manage Club Names';

  @override
  String get manage_club_names_subtitle => 'Rename or delete reading clubs';

  @override
  String get migrate_bundle_books_title => 'Migrate Bundle Books';

  @override
  String get migrate_bundle_books_subtitle => 'Convert old bundles to new system';

  @override
  String get available => 'Available';

  @override
  String get migrate_reading_sessions => 'Migrate Reading Sessions';

  @override
  String get migrate_reading_sessions_subtitle => 'Move reading sessions to individual books';

  @override
  String get migrate_reading_sessions_question => 'Migrate Reading Sessions?';

  @override
  String get no_sessions_to_migrate => 'No reading sessions to migrate. All sessions are already on individual books!';

  @override
  String get migrating_reading_sessions => 'Migrating reading sessions...';

  @override
  String get migration_successful => 'Migration Successful!';

  @override
  String get migration_completed_with_errors => 'Migration Completed with Errors';

  @override
  String get what_will_happen => 'What will happen:';

  @override
  String get migration_description => '• Reading sessions will be copied to individual books\n• Old bundle reading sessions will be deleted\n• This fixes inconsistencies in bundle reading history';

  @override
  String get migration_safe_info => 'ℹ️ This is safe and can be run multiple times';

  @override
  String successful_bundles(Object count) {
    return '✅ Successful: $count bundles';
  }

  @override
  String skipped_bundles(Object count) {
    return '⏭️  Skipped: $count bundles';
  }

  @override
  String failed_bundles(Object count) {
    return '❌ Failed: $count bundles';
  }

  @override
  String total_sessions_migrated(Object count) {
    return '📚 Total sessions migrated: $count';
  }

  @override
  String get errors_label => 'Errors:';

  @override
  String error_migrating_reading_sessions(Object error) {
    return 'Error migrating reading sessions: $error';
  }

  @override
  String get warm_earth => 'Warm Earth';

  @override
  String get vibrant_sunset => 'Vibrant Sunset';

  @override
  String get soft_pastel => 'Soft Pastel';

  @override
  String get deep_ocean => 'Deep Ocean';

  @override
  String get custom => 'Custom';

  @override
  String get mystic_purple => 'Mystic Purple';

  @override
  String get deep_sea => 'Deep Sea';

  @override
  String get warm_autumn => 'Warm Autumn';

  @override
  String get edit_custom_light_palette => 'Edit Custom Light Palette';

  @override
  String get edit_custom_dark_palette => 'Edit Custom Dark Palette';

  @override
  String get primary => 'Primary';

  @override
  String get secondary => 'Secondary';

  @override
  String get tertiary => 'Tertiary';

  @override
  String get pick_a_color => 'Pick a Color';

  @override
  String get pick_a_custom_color => 'Pick a Custom Color';

  @override
  String get hue => 'Hue';

  @override
  String get application_name => 'My Random Library';

  @override
  String get application_legalese => '© 2025 Ana Martínez Montañez. All rights reserved.';

  @override
  String get books_by_decade => 'Books by Decade';

  @override
  String get decade_label => 'Decade: ';

  @override
  String get re_read_books => 'Re-read Books';

  @override
  String get authors_title => 'Authors';

  @override
  String get saga_completion => 'Saga Completion';

  @override
  String get books_by_saga => 'Books by Saga';

  @override
  String get bundle_migration => 'Bundle Migration';

  @override
  String get books_by_year => 'Books by Year';

  @override
  String get reading_status_required => 'Reading Status *';

  @override
  String get status_is_required => 'Status is required';

  @override
  String get add_rating_criterion => 'Add Rating Criterion';

  @override
  String get no_books_match_filters => 'No books match the selected filters';

  @override
  String get specific_number_of_books => 'Specific number of books';

  @override
  String get unknown_show_as_question => 'Unknown (show as \"?\")';

  @override
  String get for_sagas_unknown_length => 'For sagas with unknown or variable length';

  @override
  String get continue_label => 'Continue';

  @override
  String confirm_delete_value(Object value) {
    return 'Are you sure you want to delete \"$value\"?';
  }

  @override
  String get this_will_fail_constraint => 'This will fail if database constraints prevent it';

  @override
  String get field_name => 'Field Name';

  @override
  String get add_rating_field_name => 'Add Rating Field Name';

  @override
  String get edit_rating_field_name => 'Edit Rating Field Name';

  @override
  String get delete_rating_field_name => 'Delete Rating Field Name';

  @override
  String field_name_already_exists(Object name) {
    return 'Field name \"$name\" already exists';
  }

  @override
  String added_value(Object value) {
    return 'Added \"$value\"';
  }

  @override
  String error_adding_field_name(Object error) {
    return 'Error adding field name: $error';
  }

  @override
  String updated_value(Object oldValue, Object newValue) {
    return 'Updated \"$oldValue\" to \"$newValue\"';
  }

  @override
  String error_updating_field_name(Object error) {
    return 'Error updating field name: $error';
  }

  @override
  String confirm_delete_field(Object name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String field_used_in_ratings(Object count) {
    return 'This field is used in $count rating(s). They will be deleted.';
  }

  @override
  String deleted_value(Object value) {
    return 'Deleted \"$value\"';
  }

  @override
  String error_deleting_field_name(Object error) {
    return 'Error deleting field name: $error';
  }

  @override
  String get about_rating_fields => 'About Rating Fields';

  @override
  String get about_rating_fields_description => 'These are the criterion names available when rating books. You can add custom names or edit existing ones. Changes will apply to all future ratings.';

  @override
  String get no_rating_field_names => 'No rating field names yet';

  @override
  String get default_suggestion => 'Default suggestion';

  @override
  String get add_field_name => 'Add Field Name';

  @override
  String get rename_club => 'Rename Club';

  @override
  String get club_name => 'Club Name';

  @override
  String get rename => 'Rename';

  @override
  String get delete_club => 'Delete Club';

  @override
  String delete_club_message(Object clubName, Object count, Object bookWord) {
    return 'Delete \"$clubName\"?\n\nThis will remove $count $bookWord from this club.';
  }

  @override
  String club_already_exists(Object name) {
    return 'Club \"$name\" already exists';
  }

  @override
  String renamed_club(Object oldName, Object newName) {
    return 'Renamed \"$oldName\" to \"$newName\"';
  }

  @override
  String error_renaming_club(Object error) {
    return 'Error renaming club: $error';
  }

  @override
  String error_deleting_club(Object error) {
    return 'Error deleting club: $error';
  }

  @override
  String get no_clubs_yet => 'No clubs yet';

  @override
  String get add_books_to_clubs_hint => 'Add books to clubs from book details';

  @override
  String get book_word => 'book';

  @override
  String get books_word => 'books';

  @override
  String get target_books_required => 'Target Books *';

  @override
  String get target_pages_optional => 'Target Pages (optional)';

  @override
  String get notes_optional => 'Notes (optional)';

  @override
  String get notes_hint => 'Any notes about this challenge';

  @override
  String get custom_challenges => 'Custom Challenges';

  @override
  String get custom_challenges_hint => 'Add custom reading goals (e.g., \"Read 5 classics\", \"Finish 3 series\")';

  @override
  String get goal_name => 'Goal name';

  @override
  String get goal_name_hint => 'e.g., Read 5 classics';

  @override
  String get target => 'Target';

  @override
  String get unit => 'Unit';

  @override
  String get unit_hint => 'e.g., books, chapters, pages';

  @override
  String get enter_valid_target_books => 'Please enter valid target books';

  @override
  String get enter_valid_target_or_custom => 'Please enter valid target books or add custom challenges';

  @override
  String get challenge_created => 'Challenge created successfully!';

  @override
  String error_creating_challenge(Object error) {
    return 'Error creating challenge: $error';
  }

  @override
  String get challenge_updated => 'Challenge updated successfully!';

  @override
  String error_updating_challenge(Object error) {
    return 'Error updating challenge: $error';
  }

  @override
  String confirm_delete_challenge(Object year) {
    return 'Are you sure you want to delete the $year challenge?';
  }

  @override
  String get challenge_deleted => 'Challenge deleted';

  @override
  String error_deleting_challenge(Object error) {
    return 'Error deleting challenge: $error';
  }

  @override
  String get current_progress => 'Current Progress';

  @override
  String get update => 'Update';

  @override
  String get challenge_progress_updated => 'Challenge progress updated!';

  @override
  String get current_label => 'Current';

  @override
  String get books_label => 'Books:';

  @override
  String get pages_label => 'Pages:';

  @override
  String get new_challenge => 'New Challenge';

  @override
  String get bundle_reading_sessions => 'Bundle Reading Sessions';

  @override
  String book_n(Object n) {
    return 'Book $n';
  }

  @override
  String session_n(Object n) {
    return 'Session $n';
  }

  @override
  String get no_reading_sessions => 'No reading sessions';

  @override
  String get not_set => 'Not set';

  @override
  String get start_date => 'Start Date';

  @override
  String get end_date => 'End Date';

  @override
  String get started_reading => 'Started reading!';

  @override
  String get marked_as_finished => 'Marked as finished!';

  @override
  String get marked_as_read => 'Marked as read!';

  @override
  String error_refetching_metadata(Object error) {
    return 'Error refetching metadata: $error';
  }

  @override
  String get reading_history => 'Reading History';

  @override
  String get reading_sessions => 'Reading Sessions';

  @override
  String get no_reading_history => 'No reading history';

  @override
  String get no_sessions_recorded => 'No sessions recorded';

  @override
  String get description => 'Description';

  @override
  String get show_more => 'Show more';

  @override
  String get show_less => 'Show less';

  @override
  String get no_description_available => 'No description available';

  @override
  String get books_in_bundle => 'Books in Bundle';

  @override
  String get notes => 'Notes';

  @override
  String get price_label => 'Price';

  @override
  String get original_book => 'Original Book';

  @override
  String get view_original => 'View Original';

  @override
  String get start_reading => 'Start Reading';

  @override
  String get mark_as_finished => 'Mark as Finished';

  @override
  String get mark_as_read => 'Mark as Read';

  @override
  String get confirm_finish_title => 'Finish Reading';

  @override
  String get confirm_mark_read_title => 'Mark as Read';

  @override
  String get reading_clubs => 'Reading Clubs';

  @override
  String get add_to_club => 'Add to Club';

  @override
  String get new_club => 'New Club';

  @override
  String get enter_club_name => 'Enter club name';

  @override
  String get remove_from_club => 'Remove from club?';

  @override
  String removed_from_club(Object club) {
    return 'Removed from $club';
  }

  @override
  String added_to_club(Object club) {
    return 'Added to $club';
  }

  @override
  String total_bundles(Object count) {
    return 'Total bundles: $count';
  }

  @override
  String individual_books_created(Object count) {
    return '📚 Individual books created: $count';
  }

  @override
  String migration_failed(Object error) {
    return 'Migration failed: $error';
  }

  @override
  String get pages_empty => 'Pages Empty';

  @override
  String get is_bundle => 'Is Bundle';

  @override
  String get is_tandem => 'Is Tandem';

  @override
  String get publication_year_empty_filter => 'Publication Year Empty';

  @override
  String get publication_date => 'Publication Date';

  @override
  String get read_count => 'Read Count';

  @override
  String get reading_progress => 'Reading Progress';

  @override
  String get enter_book_title => 'Enter book title';

  @override
  String get enter_author_names => 'Enter author name(s), separate with commas';

  @override
  String get select_month => 'Select Month';

  @override
  String get no_books_this_month => 'No books read this month';

  @override
  String get select_winner => 'Select Winner';

  @override
  String get confirm_selection => 'Confirm Selection';

  @override
  String get past_years_winners => 'Past Years Winners';

  @override
  String get no_past_winners => 'No past winners yet';

  @override
  String migrate_sessions_description(Object sessions, Object bundles) {
    return 'This will migrate $sessions reading session(s) from $bundles bundle(s) to individual books.';
  }

  @override
  String migrate_bundles_description(Object count) {
    return 'This will convert $count old-style bundles to the new system.\n\nIndividual book records will be created for each book in the bundle.\n\nThis cannot be undone.';
  }

  @override
  String get import_from_tag => 'Import from Tag';

  @override
  String import_options(Object format) {
    return 'Import Options ($format)';
  }

  @override
  String get update_reading_progress => 'Update Reading Progress';

  @override
  String get percentage => 'Percentage';

  @override
  String get pages_label_short => 'Pages';

  @override
  String get progress_percentage => 'Progress (%)';

  @override
  String get current_page => 'Current Page';

  @override
  String total_pages(Object count) {
    return 'Total pages: $count';
  }

  @override
  String get percentage_cannot_exceed_100 => 'Percentage cannot exceed 100';

  @override
  String page_cannot_exceed(Object count) {
    return 'Page number cannot exceed $count';
  }

  @override
  String get progress_updated => 'Progress updated!';

  @override
  String get did_you_read_today => 'Did you read today?';

  @override
  String get did_you_read_this_book_today => 'Did you read this book today?';

  @override
  String get yes_label => 'YES';

  @override
  String get no_label => 'NO';

  @override
  String get marked_read_today => 'Marked as read today!';

  @override
  String get marked_not_read_today => 'Marked as not read today.';

  @override
  String get edit_reading_sessions => 'Edit Reading Sessions';

  @override
  String session_label(Object index) {
    return 'Session $index';
  }

  @override
  String get date_label => 'Date';

  @override
  String get time_hhmmss => 'Time (HH:MM)';

  @override
  String get duration_hint => 'Enter duration as: 1h 30m 5s, 90m, or just seconds';

  @override
  String get sessions_updated => 'Sessions updated!';

  @override
  String get add_reading_session => 'Add Reading Session';

  @override
  String get session_added => 'Session added!';

  @override
  String get reading_time => 'Reading Time';

  @override
  String get reading_time_details => 'Reading Time Details';

  @override
  String book_took_days(Object days, Object dayWord) {
    return 'This book took $days $dayWord to read.';
  }

  @override
  String calculation_method(Object method) {
    return 'Calculation Method: $method';
  }

  @override
  String days_with_time_tracking(Object count) {
    return 'Days with time tracking: $count';
  }

  @override
  String days_with_reading_flag(Object count) {
    return 'Days with reading flag only: $count';
  }

  @override
  String days_marked_as_read(Object count) {
    return 'Days marked as read: $count';
  }

  @override
  String start_date_label(Object date) {
    return 'Start date: $date';
  }

  @override
  String end_date_label(Object date) {
    return 'End date: $date';
  }

  @override
  String bundle_books_calculated(Object count) {
    return 'Bundle: $count books calculated';
  }

  @override
  String get confirm_delete_title => 'Confirm Delete';

  @override
  String get book_details => 'Book Details';

  @override
  String get fetching_cover => 'Fetching cover...';

  @override
  String get no_cover_image => 'No cover image';

  @override
  String get failed_to_load_image => 'Failed to load image';

  @override
  String get added_to_tbr => 'Added to TBR';

  @override
  String get removed_from_tbr => 'Removed from TBR';

  @override
  String get remove_from_tbr => 'Remove from TBR';

  @override
  String get add_to_tbr_short => 'Add to TBR';

  @override
  String get tap_to_update_progress => 'Tap to update progress';

  @override
  String get day_word => 'day';

  @override
  String get days_word => 'days';

  @override
  String get original_publication_year_label => 'Original Publication Year';

  @override
  String get original_publication_date_label => 'Original Publication Date';

  @override
  String get confirm_finish_message => 'Mark this book as finished?';

  @override
  String get confirm_mark_read_message => 'Mark this book as read?';

  @override
  String error_deleting_book(Object error) {
    return 'Error deleting book: $error';
  }

  @override
  String get refresh_metadata => 'Refresh metadata';

  @override
  String get tbr_list_subtitle => 'This book is in your TBR list';

  @override
  String get open_library => 'Open Library';

  @override
  String get google_books => 'Google Books';

  @override
  String get error_loading_bundle_books => 'Error loading bundle books';

  @override
  String get no_books_in_bundle => 'No books in bundle';

  @override
  String get no_status => 'No status';

  @override
  String get created_label => 'Created';

  @override
  String get bundle_timed_reading_sessions => 'Bundle Timed Reading Sessions';

  @override
  String get tbr_label => 'To Be Read';

  @override
  String get release_notification => 'Release Notification';

  @override
  String scheduled_for(Object date) {
    return 'Scheduled for $date';
  }

  @override
  String get my_rating_label => 'My Rating';

  @override
  String get fetching_description => 'Fetching description...';

  @override
  String total_reading_time(Object hours) {
    return 'Total reading time: $hours hours';
  }

  @override
  String get finish_book => 'Finish Book';

  @override
  String get rating_breakdown => 'Rating Breakdown';

  @override
  String get manual_rating => 'Manual rating';

  @override
  String get auto_calculated => 'Auto-calculated';

  @override
  String get read_today_check => 'Read today ✓';

  @override
  String copied_to_clipboard(Object value) {
    return 'Copied: $value';
  }

  @override
  String get tandem_books => 'Tandem Books';

  @override
  String get read_together_with => 'Read together with these books';

  @override
  String get no_tandem_books => 'No other tandem books in this saga';

  @override
  String get rate_reading_experience => 'Rate your reading experience:';

  @override
  String get no_rating_fields => 'No rating fields available. You can add them in Settings.';

  @override
  String get write_review_optional => 'Write a review (optional):';

  @override
  String get share_your_thoughts => 'Share your thoughts...';

  @override
  String get saga_completion_setup => 'Saga Completion Setup';

  @override
  String you_are_adding(Object name) {
    return 'You are adding: \"$name\"';
  }

  @override
  String get how_many_books_saga => 'How many books should this saga show in statistics?';

  @override
  String get saga_completion_explanation => 'The saga completion card will show \"X / Y\" where Y is the number you specify.';

  @override
  String get number_of_books => 'Number of books';

  @override
  String get examples => 'Examples:';

  @override
  String get value_label => 'Value';

  @override
  String get value_added_successfully => 'Value added successfully';

  @override
  String get value_updated_successfully => 'Value updated successfully';

  @override
  String get value_deleted_successfully => 'Value deleted successfully';

  @override
  String get core_status_warning => 'Core status: Only the label will change, not the database value or logic.';

  @override
  String get core_format_saga_warning => 'Core format saga: Only the label can be changed, this value cannot be deleted.';

  @override
  String get core_status_cannot_delete => 'This is a core status value and cannot be deleted. The app logic depends on these values: Yes, No, Started, TBReleased, Abandoned, Repeated, and Standby.';

  @override
  String get core_format_saga_cannot_delete => 'This is a core format saga value and cannot be deleted. The app logic depends on these values: Standalone, Bilogy, Trilogy, Tetralogy, Pentalogy, Hexalogy, 6+, and Saga.';

  @override
  String get core_value_cannot_delete => 'Core value cannot be deleted';

  @override
  String get select_category => 'Select Category';

  @override
  String value_in_use(Object value, Object count) {
    return 'The value \"$value\" is used by $count book(s).';
  }

  @override
  String get what_would_you_like_to_do => 'What would you like to do?';

  @override
  String get replace_with_existing => 'Replace with existing value';

  @override
  String get select_replacement => 'Select replacement';

  @override
  String get new_value => 'New value';

  @override
  String get delete_may_fail => 'This will fail if database constraints prevent it';

  @override
  String get please_select_replacement => 'Please select a replacement value';

  @override
  String get please_enter_new_value => 'Please enter a new value';

  @override
  String get year_label => 'Year';

  @override
  String get target_books => 'Target Books';

  @override
  String get target_pages => 'Target Pages';

  @override
  String get optional => 'optional';

  @override
  String get any_notes_about_challenge => 'Any notes about this challenge';

  @override
  String get add_custom_reading_goals => 'Add custom reading goals (e.g., \"Read 5 classics\", \"Finish 3 series\")';

  @override
  String get no_challenges_yet => 'No challenges yet';

  @override
  String get create_first_challenge => 'Create your first reading challenge!';

  @override
  String get field_name_hint => 'e.g., Romance, Action, Suspense';

  @override
  String updated_field_name(Object oldName, Object newName) {
    return 'Updated \"$oldName\" to \"$newName\"';
  }

  @override
  String confirm_delete_club(Object clubName, Object count) {
    return 'Delete \"$clubName\"?\n\nThis will remove $count book(s) from this club.';
  }

  @override
  String book_count_label(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'books',
      one: 'book',
    );
    return '$count $_temp0';
  }

  @override
  String get what_would_you_like_next => 'What would you like to do next?';

  @override
  String get reading_status => 'Reading Status';

  @override
  String get original_book_required => 'Original Book (required for Repeated status)';

  @override
  String get missing_required_fields => 'Missing Required Fields';

  @override
  String get please_fill_required_fields => 'Please fill in the following required fields:';

  @override
  String get tandem_requires_saga => 'Tandem books must have a Saga or Saga Universe.\n\nPlease fill in at least one of these fields to mark this book as Tandem.';

  @override
  String get search_original_book => 'Search for the original book...';

  @override
  String get original_book_is_required => 'Original book is required';

  @override
  String get asin => 'ASIN';

  @override
  String get search_or_add_author => 'Type to search or add new author';

  @override
  String get select_publisher => 'Select publisher';

  @override
  String get genres => 'Genre(s)';

  @override
  String get search_or_add_genre => 'Type to search or add new genre';

  @override
  String get original_publication_date => 'Original Publication Date (for notifications)';

  @override
  String get release_date => 'Release Date';

  @override
  String get select_release_date => 'Select release date';

  @override
  String get get_notified_when_released => 'Get notified when this book is released';

  @override
  String get notification_date_time => 'Notification Date & Time';

  @override
  String get select_notification_date => 'Select notification date and time';

  @override
  String get book_lists => 'Book Lists';

  @override
  String get mark_for_reading_list => 'Mark this book for your reading list';

  @override
  String tbr_limit_message(Object limit) {
    return 'You have reached your TBR limit of $limit books.\n\nPlease uncheck some books in the My Books screen to add more.';
  }

  @override
  String get mark_as_tandem => 'Mark as Tandem Book';

  @override
  String get tandem_description => 'Read together with other books in this saga';

  @override
  String get reading_information_optional => 'Reading Information (Optional)';

  @override
  String get rating => 'Rating';

  @override
  String get no_ratings_yet => 'No ratings yet';

  @override
  String get average => 'Average';

  @override
  String get criterion => 'Criterion';

  @override
  String get general_rating => 'General Rating';

  @override
  String get manual => 'manual';

  @override
  String get override_auto_calculation => 'Override auto-calculation';

  @override
  String get manually_set_rating => 'Manually set the general rating';

  @override
  String get write_your_thoughts => 'Write your thoughts about this book...';

  @override
  String get price => 'Price';

  @override
  String get enter_book_price => 'Enter book price';

  @override
  String get add_notes_hint => 'Add any additional notes about this book...';

  @override
  String get point_camera_at_barcode => 'Point camera at barcode';

  @override
  String get test_notification_sent => 'Test notification sent!';

  @override
  String get test_notification => 'Test Notification';

  @override
  String get timed_reading_sessions => 'Timed Reading Sessions';

  @override
  String get update_book => 'Update Book';

  @override
  String get reading_session_saved => 'Reading session saved';

  @override
  String get stop_timer_confirm => 'Do you want to stop the reading timer?';

  @override
  String get reading_timer => 'Reading Timer';

  @override
  String get timer_exit_confirm => 'The timer is still counting. Are you sure you want to exit without stopping it?';

  @override
  String get exit_label => 'Exit';

  @override
  String get stop_and_save => 'Stop & Save';

  @override
  String get backup_created => 'Backup created successfully';

  @override
  String get restore_canceled => 'Restore canceled';

  @override
  String get restore_warning => 'This will replace your current database. Make sure you have a backup!';

  @override
  String get restore_database => 'Restore Database';

  @override
  String get restore_from_backup => 'Restore from a previous backup';

  @override
  String get backup_restored_successfully => 'Backup restored successfully';

  @override
  String get select => 'Select';

  @override
  String get session => 'Session';

  @override
  String book_already_in_club(Object clubName) {
    return 'Book is already in \"$clubName\"';
  }

  @override
  String get club_membership_updated => 'Club membership updated';

  @override
  String remove_book_from_club(Object clubName) {
    return 'Remove this book from \"$clubName\"?';
  }

  @override
  String get remove => 'Remove';

  @override
  String get not_in_any_clubs => 'Not in any clubs yet';

  @override
  String get bundle_description => 'Check if this book contains multiple books in one volume';

  @override
  String get eg_3 => 'e.g., 3';

  @override
  String get eg_1_or_1_5 => 'e.g., 1 or 1.5';

  @override
  String get eg_2020 => 'e.g., 2020';

  @override
  String get map_status_values => 'Map Status Values';

  @override
  String get match_csv_status_values => 'Match your CSV status values to app statuses:';

  @override
  String get leave_empty_if_not_used => 'Leave empty if not used in your CSV';

  @override
  String get continue_import => 'Continue Import';

  @override
  String get edit_club_membership => 'Edit Club Membership';

  @override
  String get add_to_reading_club => 'Add to Reading Club';

  @override
  String get enter_or_select_club_name => 'Enter or select club name';

  @override
  String get please_enter_club_name => 'Please enter a club name';

  @override
  String get target_date_optional => 'Target Date (Optional)';

  @override
  String get select_date => 'Select date';

  @override
  String get reading_progress_percent => 'Reading Progress (%)';

  @override
  String get please_enter_progress => 'Please enter progress';

  @override
  String get progress_must_be_0_100 => 'Progress must be between 0 and 100';

  @override
  String get track_reading_progress => 'Track your reading progress for this club';

  @override
  String get how_import_books => 'How would you like to import your books?';

  @override
  String get select_or_enter_tag => 'Select or enter a tag:';

  @override
  String get available_tags => 'Available tags';

  @override
  String get or_enter_custom_tag => 'Or enter a custom tag';

  @override
  String get eg_owned_wishlist => 'e.g., owned, wishlist';

  @override
  String get please_select_or_enter_tag => 'Please select or enter a tag';

  @override
  String get import_label => 'Import';

  @override
  String get add_books_to => 'Add Books to';

  @override
  String books_selected(Object count) {
    return '$count book(s) selected';
  }

  @override
  String get search_for_books_to_add => 'Search for books to add';

  @override
  String get unknown => 'Unknown';

  @override
  String add_n_books(Object count) {
    return 'Add $count Book(s)';
  }

  @override
  String get book => 'Book';

  @override
  String tbr_limit_set_to(Object limit) {
    return 'TBR limit set to $limit books';
  }

  @override
  String get all_label => 'All';

  @override
  String get read_label => 'Read';

  @override
  String get based_on_publication_year => 'Based on original publication year';

  @override
  String get create_challenge => 'Create Challenge';

  @override
  String get seasonal_reading_patterns => 'Seasonal Reading Patterns';

  @override
  String avg_books_per_season(Object count) {
    return 'Average: $count books per season';
  }

  @override
  String get most => 'Most';

  @override
  String get least => 'Least';

  @override
  String get per_year => 'per year';

  @override
  String get seasonal_reading_preferences => 'Seasonal Reading Preferences';

  @override
  String get you_read_most_in => 'You read most in';

  @override
  String get no_reading_data_available => 'No reading data available';

  @override
  String get reading_goals_progress => 'Reading Goals Progress';

  @override
  String get available_now => 'Available Now';

  @override
  String get set_and_track_reading_goals => 'Set and track reading goals';

  @override
  String get annual_book_page_challenges => 'Annual book and page challenges';

  @override
  String get tap_to_manage_challenges => 'Tap to manage challenges';

  @override
  String get reading_efficiency_score => 'Reading Efficiency Score';

  @override
  String get books_faster_than_average => 'of books read faster than your average pace';

  @override
  String get what_does_this_mean => 'What does this mean?';

  @override
  String get efficiency_explanation => 'This compares each book\'s reading speed to your overall average. Higher percentages mean you\'re consistently reading at or above your typical pace.';

  @override
  String based_on_n_books(Object count) {
    return 'Based on $count books with complete data';
  }

  @override
  String get average_rating => 'Average Rating';

  @override
  String based_on_rated_books(Object count) {
    return 'Based on $count rated books';
  }

  @override
  String get monthly_reading_heatmap => 'Monthly Reading Heatmap';

  @override
  String get books_finished_per_month => 'Books finished per month';

  @override
  String get less => 'Less';

  @override
  String get more => 'More';

  @override
  String get reading_insights => 'Reading Insights';

  @override
  String get reading_streaks => 'Reading Streaks';

  @override
  String get days => 'days';

  @override
  String get best => 'Best';

  @override
  String get re_reads => 'Re-reads';

  @override
  String get series_vs_standalone => 'Series vs Standalone';

  @override
  String get series => 'series';

  @override
  String get standalone => 'standalone';

  @override
  String get personal_bests => 'Personal Bests';

  @override
  String get most_in_month => 'Most in month';

  @override
  String get fastest => 'Fastest';

  @override
  String get next_milestone_owned => 'Next Milestone (Books Owned)';

  @override
  String get to_go => 'to go';

  @override
  String get next_milestone_read => 'Next Milestone (Books Read)';

  @override
  String get binge_reading_series => 'Binge Reading (Series)';

  @override
  String get binge_reading_description => 'of books finished within 14 days of previous';

  @override
  String get best_past_books => 'Best Past Books';

  @override
  String get reading_goals_progress_title => 'Reading Goals Progress';

  @override
  String no_challenge_set_for_year(Object year) {
    return 'No challenge set for $year';
  }

  @override
  String get reading_goals => 'Reading Goals';

  @override
  String get dnf_rate => 'DNF Rate';

  @override
  String get books_by_rating_distribution => 'Books by Rating Distribution';

  @override
  String get page_count_distribution => 'Page Count Distribution';

  @override
  String get book_extremes => 'Book Extremes';

  @override
  String get oldest => 'Oldest';

  @override
  String get newest => 'Newest';

  @override
  String get shortest => 'Shortest';

  @override
  String get longest => 'Longest';

  @override
  String no_books_read_in_year(Object year) {
    return 'No books read in $year';
  }

  @override
  String and_n_more(Object count) {
    return 'and $count more';
  }

  @override
  String get reading_time_of_day => 'Reading Time of Day';

  @override
  String get coming_soon => 'Coming Soon';

  @override
  String get track_when_you_read_most => 'Track when you read most';

  @override
  String get morning_afternoon_night_owl => 'Morning, afternoon, or night owl?';

  @override
  String get requires_chronometer => 'Requires chronometer feature';

  @override
  String get saga_completion_rate => 'Saga Completion Rate';

  @override
  String get completed => 'Completed';

  @override
  String get in_progress => 'In Progress';

  @override
  String get not_started => 'Not Started';

  @override
  String get my_books => 'My Books';

  @override
  String get no_re_read_books_yet => 'No re-read books yet';

  @override
  String read_n_times(Object count) {
    return 'Read $count times';
  }

  @override
  String get decade => 'Decade';

  @override
  String get past_years_competitions => 'Past Years Competitions';

  @override
  String get no_past_competitions_found => 'No past competitions found';

  @override
  String get no_winner_set => 'No winner set';

  @override
  String get no_books_for_author => 'No books found for this author';

  @override
  String added_books_to_saga(Object count, Object type) {
    return 'Added $count book(s) to $type';
  }

  @override
  String no_books_in_saga(Object type) {
    return 'No books found in this $type';
  }

  @override
  String get no_completed_sagas => 'No completed sagas yet';

  @override
  String get no_sagas_in_progress => 'No sagas in progress';

  @override
  String get no_unstarted_sagas => 'No unstarted sagas';

  @override
  String get complete_label => 'complete';

  @override
  String get year => 'Year';

  @override
  String get no_books_in_year => 'No books read in this year';

  @override
  String get year_winner => 'Year Winner';

  @override
  String get final_round => 'Final';

  @override
  String get please_select_book => 'Please select a book';

  @override
  String select_winner_title(Object period) {
    return 'Select $period Winner';
  }

  @override
  String selected_as_winner(Object name) {
    return '$name selected as winner!';
  }

  @override
  String get no_monthly_winners_quarter => 'No monthly winners for this quarter';

  @override
  String get no_quarterly_winners => 'No quarterly winners available';

  @override
  String get no_semifinal_winners => 'No semifinal winners available';

  @override
  String select_yearly_winner(Object year) {
    return 'Select $year Yearly Winner';
  }

  @override
  String get semifinal => 'Semifinal';

  @override
  String get no_books_currently_reading => 'No books currently reading';

  @override
  String get no_books_on_standby => 'No books on standby';

  @override
  String get reading_label => 'Reading';

  @override
  String get standby_label => 'Standby';

  @override
  String get tbr_title => 'To Be Read (TBR)';

  @override
  String get no_books_in_tbr => 'No books in TBR';

  @override
  String get add_books_to_clubs => 'Add books to clubs from book details';

  @override
  String get clubs => 'Clubs';

  @override
  String get random_book_picker => 'Random Book Picker';

  @override
  String get random_book_description => 'Apply filters and get a random book suggestion';

  @override
  String get and_all_genres => 'AND: must have all selected genres';

  @override
  String get or_any_genre => 'OR: matches any selected genre';

  @override
  String get and_not_practical => 'AND: not practical (book has one status)';

  @override
  String get or_any_status => 'OR: matches any selected status';

  @override
  String get tbr_filter_label => 'TBR (To Be Read)';

  @override
  String get yes_in_tbr => 'Yes - In TBR';

  @override
  String get no_not_in_tbr => 'No - Not in TBR';

  @override
  String get publication_year_decade => 'Publication Year (by decade)';

  @override
  String get or_select_specific_books => 'Or select specific books';

  @override
  String get search_select_books_description => 'Search and select books by title to pick randomly from your custom list';

  @override
  String get select_books => 'Select Books';

  @override
  String get type_to_search_books => 'Type to search books by title';

  @override
  String random_from_selected(Object count) {
    return 'Random from Selected ($count)';
  }

  @override
  String get try_another => 'Try Another';

  @override
  String get tap_to_view_details => 'Tap card to view details';

  @override
  String get migration_completed_errors => 'Migration Completed with Errors';

  @override
  String get about_bundle_migration => 'About Bundle Migration';

  @override
  String get current_status => 'Current Status';

  @override
  String get old_style_bundles => 'Old-style bundles';

  @override
  String get new_style_bundles => 'New-style bundles';

  @override
  String get individual_bundle_books => 'Individual bundle books';

  @override
  String get migrating => 'Migrating...';

  @override
  String migrate_n_bundles(Object count) {
    return 'Migrate $count Bundles';
  }

  @override
  String get no_migration_needed => 'All bundles are using the new system!\nNo migration needed.';

  @override
  String get last_migration_result => 'Last Migration Result';

  @override
  String get resume_import => 'Resume Import?';

  @override
  String get start_fresh => 'Start Fresh';

  @override
  String get import_all => 'Import All';

  @override
  String get no_csv_file_selected => 'No CSV file selected';

  @override
  String get clear_reviewed_books => 'Clear Reviewed Books?';

  @override
  String get clear_reviewed_books_description => 'This will clear all tracked reviewed books from all import sessions. Use this if the count seems wrong.';

  @override
  String get cleared_reviewed_books => 'Cleared all reviewed books tracking';

  @override
  String get clear_reviewed_books_cache => 'Clear Reviewed Books Cache';

  @override
  String book_x_of_y(Object current, Object total) {
    return 'Book $current of $total';
  }

  @override
  String n_to_import(Object count) {
    return '$count to import';
  }

  @override
  String get import_up_to_here => 'Import Up To Here';

  @override
  String get ignore => 'Ignore';

  @override
  String get next_label => 'Next';

  @override
  String get import_this_book => 'Import this book';

  @override
  String get storage_permission_needed => 'Storage permission is needed to create backups. Would you like to grant permission?';

  @override
  String get import_error => 'Import Error';

  @override
  String get cloud_sync => 'Cloud Sync';

  @override
  String get cloud_sync_subtitle => 'Backup and restore via Google';

  @override
  String get sign_in_with_google => 'Sign in with Google';

  @override
  String get sign_out => 'Sign Out';

  @override
  String signed_in_as(Object email) {
    return 'Signed in as $email';
  }

  @override
  String get backup_to_cloud => 'Backup to Cloud';

  @override
  String get restore_from_cloud => 'Restore from Cloud';

  @override
  String get upload_your_library => 'Upload your library to Google Cloud';

  @override
  String get download_your_library => 'Download your library from Google Cloud';

  @override
  String last_cloud_backup(Object date) {
    return 'Last cloud backup: $date';
  }

  @override
  String get no_cloud_backup => 'No cloud backup found';

  @override
  String get cloud_backup_success => 'Backup uploaded successfully';

  @override
  String get cloud_restore_success => 'Library restored from cloud';

  @override
  String get cloud_restore_warning => 'This will replace ALL your current data with the cloud backup. This cannot be undone.';

  @override
  String get cloud_backup_in_progress => 'Uploading backup...';

  @override
  String get cloud_restore_in_progress => 'Downloading backup...';

  @override
  String get sign_in_required => 'Please sign in to use cloud backup';

  @override
  String get sign_in_failed => 'Sign in failed';

  @override
  String get no_internet => 'No internet connection';

  @override
  String cloud_backup_books(Object count) {
    return '$count books';
  }
}

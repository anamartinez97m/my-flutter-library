import 'package:flutter/foundation.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/database_helper.dart';
import '../repositories/book_repository.dart';

class BookProvider extends ChangeNotifier {
  late BookRepository _repo;
  List<Book> _books = [];
  List<Book> _filteredBooks = <Book>[]; // Books after filter
  List<Book> _displayBooks = <Book>[]; // Books after filter + search
  String? _latestBookAdded = '';
  bool _isLoading = false;
  String _currentSearchQuery = '';
  int _currentSearchIndex = 0;
  
  // State for filters and sorting
  final Map<String, String> _currentFilters = {};
  String _currentSortBy = 'name';
  bool _currentSortAscending = true;

  List<Book> get books => _displayBooks;
  List<Book> get allBooks => _books; // Unfiltered list for statistics
  String? get latestBookAdded => _latestBookAdded;
  bool get isLoading => _isLoading;
  Map<String, String> get currentFilters => Map.unmodifiable(_currentFilters);
  String get currentSortBy => _currentSortBy;
  bool get currentSortAscending => _currentSortAscending;

  static Future<BookProvider> create() async {
    final db = await DatabaseHelper.instance.database;
    final provider = BookProvider._(BookRepository(db));
    await provider._loadSortPreferences();
    await provider.loadBooks();
    return provider;
  }

  Future<void> _loadSortPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _currentSortBy = prefs.getString('default_sort_by') ?? 'name';
    _currentSortAscending = prefs.getBool('default_sort_ascending') ?? true;
  }

  BookProvider._(this._repo);

  /// Removes accents from a string for accent-insensitive search
  String _removeAccents(String text) {
    // const accents = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÖØòóôõöøÈÉÊËèéêëÇçÌÍÎÏìíîïÙÚÛÜùúûüÿÑñ';
    // const withoutAccents = 'AAAAAAaaaaaaOOOOOOooooooEEEEeeeeCcIIIIiiiiUUUUuuuuyNn';

    String result = text;
    // for (int i = 0; i < accents.length; i++) {
    //   result = result.replaceAll(accents[i], withoutAccents[i]);
    // }
    return result;
  }

  Future<void> loadBooks() async {
    // Get fresh database instance in case it was closed/reopened
    final db = await DatabaseHelper.instance.database;
    _repo = BookRepository(db);
    
    _books = await _repo.getAllBooks();
    _latestBookAdded = await _repo.getLatestBookAdded();
    _isLoading = false;
    
    // Reapply all filters
    _applyAllFilters();
    
    // Reapply sorting
    sortBooks(_currentSortBy, _currentSortAscending);
    
    // Reapply search if there was one
    if (_currentSearchQuery.isNotEmpty) {
      _applySearch();
    }
    
    notifyListeners();
  }

  void _applyAllFilters() {
    if (_currentFilters.isEmpty) {
      _filteredBooks = List<Book>.from(_books);
    } else {
      _filteredBooks = _books.where((book) {
        // Check all active filters
        for (var entry in _currentFilters.entries) {
          final filterType = entry.key;
          final filterValue = entry.value;
          
          // Handle empty field filters
          if (filterValue == '__EMPTY__') {
            switch (filterType) {
              case 'title':
                if (book.name != null && book.name!.isNotEmpty) return false;
                break;
              case 'isbn':
                // Check both ISBN and ASIN are empty
                if ((book.isbn != null && book.isbn!.isNotEmpty) || 
                    (book.asin != null && book.asin!.isNotEmpty)) return false;
                break;
              case 'author':
                if (book.author != null && book.author!.isNotEmpty) return false;
                break;
              case 'format':
                if (book.formatValue != null && book.formatValue!.isNotEmpty) return false;
                break;
              case 'language':
                if (book.languageValue != null && book.languageValue!.isNotEmpty) return false;
                break;
              case 'genre':
                if (book.genre != null && book.genre!.isNotEmpty) return false;
                break;
              case 'place':
                if (book.placeValue != null && book.placeValue!.isNotEmpty) return false;
                break;
              case 'editorial':
                if (book.editorialValue != null && book.editorialValue!.isNotEmpty) return false;
                break;
            }
          } else {
            // Normal value filters
            switch (filterType) {
              case 'format':
                if (book.formatValue != filterValue) return false;
                break;
              case 'language':
                if (book.languageValue != filterValue) return false;
                break;
              case 'genre':
                if (!(book.genre?.contains(filterValue) ?? false)) return false;
                break;
              case 'place':
                if (book.placeValue != filterValue) return false;
                break;
              case 'status':
                if (book.statusValue != filterValue) return false;
                break;
            }
          }
        }
        return true;
      }).toList();
    }
    _displayBooks = List<Book>.from(_filteredBooks);
  }

  void _applySearch() {
    if (_currentSearchQuery.isEmpty) {
      _displayBooks = List.from(_filteredBooks);
    } else {
      final normalizedQuery = _removeAccents(_currentSearchQuery.toLowerCase());
      _displayBooks =
          _filteredBooks.where((book) {
          switch (_currentSearchIndex) {
            case 0: // Search by Title
              final normalizedTitle = _removeAccents(
                (book.name ?? '').toLowerCase(),
              );
              return normalizedTitle.contains(normalizedQuery);
            case 1: // Search by ISBN
              final normalizedIsbn = _removeAccents(
                (book.isbn ?? '').toLowerCase(),
              );
              return normalizedIsbn.contains(normalizedQuery);
            case 2: // Search by Author
              final normalizedAuthor = _removeAccents(
                (book.author ?? '').toLowerCase(),
              );
              return normalizedAuthor.contains(normalizedQuery);
            case 3: // Search by Saga
              final normalizedSaga = _removeAccents(
                (book.saga ?? '').toLowerCase(),
              );
              return normalizedSaga.contains(normalizedQuery);
            default:
              return false;
          }
        }).toList();
    }
    
    // Re-apply sorting after search
    _displayBooks.sort((a, b) {
        int comparison = 0;

        switch (_currentSortBy) {
          case 'name':
            final aName = _removeAccents((a.name ?? '').toLowerCase());
            final bName = _removeAccents((b.name ?? '').toLowerCase());
            comparison = aName.compareTo(bName);
            break;
          case 'author':
            final aAuthor = _removeAccents((a.author ?? '').toLowerCase());
            final bAuthor = _removeAccents((b.author ?? '').toLowerCase());
            comparison = aAuthor.compareTo(bAuthor);
            break;
          case 'created_at':
            comparison = (a.createdAt ?? '').compareTo(b.createdAt ?? '');
            break;
          default:
            final aName = _removeAccents((a.name ?? '').toLowerCase());
            final bName = _removeAccents((b.name ?? '').toLowerCase());
            comparison = aName.compareTo(bName);
        }

        return _currentSortAscending ? comparison : -comparison;
      });
  }

  Future<void> searchBooks(String query, {required int searchIndex}) async {
    _currentSearchQuery = query;
    _currentSearchIndex = searchIndex;
    _applySearch();
    notifyListeners();
  }

  Future<void> setDefaultSortOrder(String sortBy, bool ascending) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('default_sort_by', sortBy);
    await prefs.setBool('default_sort_ascending', ascending);
    _currentSortBy = sortBy;
    _currentSortAscending = ascending;
    sortBooks(sortBy, ascending);
  }

  void sortBooks(String sortBy, bool ascending) {
    _currentSortBy = sortBy;
    _currentSortAscending = ascending;
    
    _displayBooks.sort((a, b) {
      int comparison = 0;

      switch (sortBy) {
        case 'name':
          final aName = _removeAccents((a.name ?? '').toLowerCase());
          final bName = _removeAccents((b.name ?? '').toLowerCase());
          comparison = aName.compareTo(bName);
          break;
        case 'author':
          final aAuthor = _removeAccents((a.author ?? '').toLowerCase());
          final bAuthor = _removeAccents((b.author ?? '').toLowerCase());
          comparison = aAuthor.compareTo(bAuthor);
          break;
        case 'created_at':
          comparison = (a.createdAt ?? '').compareTo(b.createdAt ?? '');
          break;
        default:
          final aName = _removeAccents((a.name ?? '').toLowerCase());
          final bName = _removeAccents((b.name ?? '').toLowerCase());
          comparison = aName.compareTo(bName);
      }

      return ascending ? comparison : -comparison;
    });

    notifyListeners();
  }

  void filterBooks(String filterType, String? filterValue) {
    if (filterValue == null || filterValue == 'all') {
      // Remove this filter type
      _currentFilters.remove(filterType);
    } else {
      // Add or update this filter type
      _currentFilters[filterType] = filterValue;
    }
    
    // Reapply all filters
    _applyAllFilters();
    
    // Reapply search on the filtered list
    _applySearch();
    notifyListeners();
  }

  void clearAllFilters() {
    _currentFilters.clear();
    _applyAllFilters();
    _applySearch();
    notifyListeners();
  }
}

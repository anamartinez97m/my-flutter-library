import 'package:flutter/foundation.dart';
import 'package:mylibrary/model/book.dart';
import '../db/database_helper.dart';
import '../repositories/book_repository.dart';

class BookProvider extends ChangeNotifier {
  late final BookRepository _repo;
  List<Book> _books = [];
  List<Book> _displayBooks = <Book>[];
  String? _latestBookAdded = '';
  bool _isLoading = false;

  List<Book> get books => _displayBooks;
  String? get latestBookAdded => _latestBookAdded;
  bool get isLoading => _isLoading;

  static Future<BookProvider> create() async {
    final db = await DatabaseHelper.instance.database;
    final provider = BookProvider._(BookRepository(db));
    await provider.loadBooks();
    return provider;
  }

  BookProvider._(this._repo);

  Future<void> loadBooks() async {
    _books = await _repo.getAllBooks();
    _displayBooks = List<Book>.from(_books);
    _latestBookAdded = await _repo.getLatestBookAdded();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> searchBooks(String query, {required int searchIndex}) async {
    final String lowerCaseQuery = query.toLowerCase();

    if (lowerCaseQuery.isEmpty) {
      _displayBooks = List<Book>.from(_books);
      notifyListeners();
      return;
    }

    _displayBooks =
        _books.where((Book book) {
          switch (searchIndex) {
            case 0: // Search by Title
              return (book.name ?? '').toLowerCase().contains(lowerCaseQuery);
            case 1: // Search by ISBN
              return (book.isbn ?? '').toLowerCase().contains(lowerCaseQuery);
            case 2: // Search by Author
              return (book.author ?? '').toLowerCase().contains(lowerCaseQuery);
            default:
              return false;
          }
        }).toList();

    notifyListeners();
  }

  // Future<void> addBook(Book book) async {
  //   await _repo.addBook(book);
  //   await _loadBooks();
  // }

  // Future<void> deleteBook(int id) async {
  //   await _repo.deleteBook(id);
  //   await _loadBooks();
  // }
}

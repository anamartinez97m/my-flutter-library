import 'package:flutter/foundation.dart';
import 'package:mylibrary/model/book.dart';
import '../db/database_helper.dart';
import '../repositories/book_repository.dart';

class BookProvider extends ChangeNotifier {
  late BookRepository _repo;
  List<Book> _books = [];
  String? _latestBookAdded = '';
  bool _isLoading = false;

  List<Book> get books => _books;
  String? get latestBookAdded => _latestBookAdded;
  bool get isLoading => _isLoading;

  static Future<BookProvider> create() async {
    final db = await DatabaseHelper.instance.database;
    final provider = BookProvider._(BookRepository(db));
    await provider._loadBooks();
    return provider;
  }

  BookProvider._(this._repo);

  Future<void> _loadBooks() async {
    _books = await _repo.getAllBooks();
    _latestBookAdded = await _repo.getLatestBookAdded();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> searchBooks(String query, {required int searchIndex}) async {
    if (query.isEmpty) {
      await _loadBooks();
      return;
    }
    _isLoading = true;
    notifyListeners();

    _books = await _repo.searchBooks(query, searchIndex);
    _isLoading = false;
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

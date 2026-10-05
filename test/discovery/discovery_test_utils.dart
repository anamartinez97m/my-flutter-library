import 'package:myrandomlibrary/model/book.dart';

int _nextId = 1;

Book makeBook({
  int? id,
  String? name,
  String? author,
  String? genre,
  String? saga,
  String? sagaUniverse,
  String? description,
  String? notes,
  String? myReview,
  String? bundleTitles,
  String? status = 'no',
  int? bundleParentId,
  bool isPlaceholder = false,
}) {
  return Book(
    bookId: id ?? _nextId++,
    name: name,
    saga: saga,
    nSaga: null,
    sagaUniverse: sagaUniverse,
    formatSagaValue: null,
    isbn: null,
    asin: null,
    pages: null,
    originalPublicationYear: null,
    loaned: null,
    statusValue: status,
    editorialValue: null,
    languageValue: null,
    placeValue: null,
    formatValue: null,
    createdAt: null,
    author: author,
    genre: genre,
    myReview: myReview,
    bundleTitles: bundleTitles,
    bundleParentId: bundleParentId,
    notes: notes,
    description: description,
    isPlaceholder: isPlaceholder,
  );
}

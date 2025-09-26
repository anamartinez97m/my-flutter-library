import 'package:flutter/material.dart';

class Book {
  final int bookId;
  final int statusId = 0;
  final String statusValue;
  final String name;
  final int? editorialId = 0;
  final String? editorialValue;
  final String? saga;
  final String? nSaga;
  final String? isbn;
  final int? languageId = 0;
  final String? languageValue;
  final int? placeId = 0;
  final String? placeValue;
  final int? formatId = 0;
  final String? formatValue;

  Book({
    required this.bookId,
    required this.name,
    required this.saga,
    required this.nSaga,
    required this.isbn,
    required this.statusValue,
    required this.editorialValue,
    required this.languageValue,
    required this.placeValue,
    required this.formatValue,
  });

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      bookId: map['bookId'] as int,
      name: map['name'] as String,
      saga: map['saga'] as String?,
      nSaga: map['nSaga'].toString() as String?,
      isbn: map['isbn'].toString() as String?,
      statusValue: map['statusValue'] as String,
      editorialValue: map['editorialValue'] as String?,
      languageValue: map['languageValue'] as String?,
      placeValue: map['placeValue'] as String?,
      formatValue: map['formatValue'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookId': bookId,
      'name': name,
      'saga': saga,
      'nSaga': nSaga,
      'isbn': isbn,
      'statusValue': statusValue,
      'editorialValue': editorialValue,
      'languageValue': languageValue,
      'placeValue': placeValue,
      'formatValue': formatValue,
    };
  }
}

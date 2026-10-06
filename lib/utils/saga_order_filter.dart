import 'package:myrandomlibrary/model/book.dart';

/// Keeps only the [candidates] that can be recommended without breaking saga
/// reading order: a numbered saga book is dropped while any earlier book of
/// the same saga (looked up in [allBooks]) is still unread.
List<Book> filterBySagaOrder(List<Book> candidates, List<Book> allBooks) {
  final result = <Book>[];
  for (final book in candidates) {
    if (book.saga == null || book.saga!.isEmpty) {
      result.add(book);
      continue;
    }
    final bookNSaga = book.nSaga;
    if (bookNSaga == null || bookNSaga.isEmpty) {
      result.add(book);
      continue;
    }
    final currentNumber = int.tryParse(bookNSaga);
    if (currentNumber == null) {
      result.add(book);
      continue;
    }
    final sagaBooks =
        allBooks
            .where(
              (b) =>
                  b.saga == book.saga && b.nSaga != null && b.nSaga!.isNotEmpty,
            )
            .toList()
          ..sort(
            (a, b) => (int.tryParse(a.nSaga ?? '0') ?? 0).compareTo(
              int.tryParse(b.nSaga ?? '0') ?? 0,
            ),
          );
    bool canRecommend = true;
    for (final sb in sagaBooks) {
      final sbNum = int.tryParse(sb.nSaga ?? '0') ?? 0;
      if (sbNum < currentNumber) {
        final status = sb.statusValue?.toLowerCase() ?? '';
        final isRead =
            status == 'yes' ||
            status == 'repeated' ||
            status.contains('read') ||
            status.contains('leído');
        if (!isRead) {
          canRecommend = false;
          break;
        }
      }
    }
    if (canRecommend) result.add(book);
  }
  return result;
}

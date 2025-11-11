import 'package:flutter/material.dart';
import 'package:myrandomlibrary/config/app_theme.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/screens/books_by_saga.dart';
import 'package:myrandomlibrary/screens/edit_book.dart';
import 'package:myrandomlibrary/utils/status_helper.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

class BookDetailScreen extends StatefulWidget {
  final Book book;

  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late Book _currentBook;

  @override
  void initState() {
    super.initState();
    _currentBook = widget.book;
  }

  String _formatDateTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
          '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoString.split('T')[0]; // Fallback to date only
    }
  }

  /// Convert database status values to user-friendly display values
  String _getStatusDisplayValue(String dbValue) {
    final lowerValue = dbValue.toLowerCase();

    // Check if status should be "Started" based on read dates
    if (lowerValue == 'no' &&
        _currentBook.dateReadInitial != null &&
        _currentBook.dateReadFinal == null) {
      return 'Started';
    }

    // Use StatusHelper for consistent labeling
    return StatusHelper.getDisplayLabel(dbValue);
  }

  /// Build publication info - shows year and optionally full date for TBReleased books
  List<Widget> _buildPublicationInfo(int pubYearOrDate) {
    final widgets = <Widget>[];

    // Check if it's a full date (YYYYMMDD format, > 9999)
    if (pubYearOrDate > 9999) {
      final year = pubYearOrDate ~/ 10000;
      final month = (pubYearOrDate % 10000) ~/ 100;
      final day = pubYearOrDate % 100;

      // Add year card
      widgets.add(
        _DetailCard(
          icon: Icons.calendar_today,
          label: 'Original Publication Year',
          value: year.toString(),
        ),
      );

      // Add full date card
      widgets.add(
        _DetailCard(
          icon: Icons.event,
          label: 'Original Publication Date',
          value:
              '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year',
        ),
      );
    } else {
      // Just a year
      widgets.add(
        _DetailCard(
          icon: Icons.calendar_today,
          label: 'Original Publication Year',
          value: pubYearOrDate.toString(),
        ),
      );
    }

    return widgets;
  }

  Future<void> _deleteBook(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: Text(
              'Are you sure you want to delete "${_currentBook.name}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true && _currentBook.bookId != null) {
      try {
        final db = await DatabaseHelper.instance.database;
        final repository = BookRepository(db);
        await repository.deleteBook(_currentBook.bookId!);

        if (context.mounted) {
          final provider = Provider.of<BookProvider?>(context, listen: false);
          await provider?.loadBooks();

          Navigator.pop(context); // Go back to list

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Book deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting book: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (!didPop) {
          // Go back to previous screen (list)
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Book Details'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final updatedBook = await Navigator.push<Book>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditBookScreen(book: _currentBook),
                  ),
                );
                if (updatedBook != null && mounted) {
                  setState(() {
                    _currentBook = updatedBook;
                  });
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteBook(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image placeholder
              Container(
                height: 180,
                color: Colors.grey[300],
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.book, size: 60, color: Colors.grey),
                      SizedBox(height: 6),
                      Text(
                        'Image coming soon',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      _currentBook.name ?? 'Unknown Title',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    AppTheme.verticalSpaceLarge,

                    // Description (from API - future implementation)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.description,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Description',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'API',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This is a placeholder for the book description that will be fetched from an external API in future development. The description will provide a summary of the book\'s content, themes, and other relevant information.',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppTheme.verticalSpaceXLarge,

                    // Details in cards
                    if (_currentBook.author != null &&
                        _currentBook.author!.isNotEmpty)
                      _DetailCard(
                        icon: Icons.person,
                        label: 'Author(s)',
                        value: _currentBook.author!,
                      ),
                    if (_currentBook.isbn != null &&
                        _currentBook.isbn!.isNotEmpty)
                      _DetailCard(
                        icon: Icons.numbers,
                        label: 'ISBN',
                        value: _currentBook.isbn!,
                      ),
                    if (_currentBook.asin != null &&
                        _currentBook.asin!.isNotEmpty)
                      _DetailCard(
                        icon: Icons.qr_code,
                        label: 'ASIN',
                        value: _currentBook.asin!,
                      ),
                    if (_currentBook.editorialValue != null &&
                        _currentBook.editorialValue!.isNotEmpty)
                      _DetailCard(
                        icon: Icons.business,
                        label: 'Editorial',
                        value: _currentBook.editorialValue!,
                      ),
                    if (_currentBook.genre != null &&
                        _currentBook.genre!.isNotEmpty)
                      _DetailCard(
                        icon: Icons.category,
                        label: 'Genre(s)',
                        value: _currentBook.genre!,
                      ),
                    if (_currentBook.saga != null &&
                        _currentBook.saga!.isNotEmpty)
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => BooksBySagaScreen(
                                    sagaName: _currentBook.saga!,
                                    sagaUniverse: _currentBook.sagaUniverse,
                                  ),
                            ),
                          );
                        },
                        child: _DetailCard(
                          icon: Icons.collections_bookmark,
                          label: 'Saga',
                          value:
                              '${_currentBook.saga}${_currentBook.nSaga != null ? ' #${_currentBook.nSaga}' : ''}',
                          trailingIcon: Icons.open_in_new,
                        ),
                      ),
                    if (_currentBook.sagaUniverse != null &&
                        _currentBook.sagaUniverse!.isNotEmpty)
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => BooksBySagaScreen(
                                    sagaName: _currentBook.sagaUniverse!,
                                    isSagaUniverse: true,
                                  ),
                            ),
                          );
                        },
                        child: _DetailCard(
                          icon: Icons.public,
                          label: 'Saga Universe',
                          value: _currentBook.sagaUniverse!,
                          trailingIcon: Icons.open_in_new,
                        ),
                      ),
                    if (_currentBook.pages != null)
                      _DetailCard(
                        icon: Icons.description,
                        label: 'Pages',
                        value: _currentBook.pages.toString(),
                      ),
                    if (_currentBook.originalPublicationYear != null)
                      ..._buildPublicationInfo(
                        _currentBook.originalPublicationYear!,
                      ),
                    if (_currentBook.statusValue != null &&
                        _currentBook.statusValue!.isNotEmpty)
                      _DetailCard(
                        icon: Icons.check_circle,
                        label: AppLocalizations.of(context)!.status,
                        value: _getStatusDisplayValue(
                          _currentBook.statusValue!,
                        ),
                      ),
                    if (_currentBook.formatSagaValue != null &&
                        _currentBook.formatSagaValue!.isNotEmpty)
                      _DetailCard(
                        icon: Icons.format_shapes,
                        label: 'Format Saga',
                        value: _currentBook.formatSagaValue!,
                      ),
                    if (_currentBook.languageValue != null &&
                        _currentBook.languageValue!.isNotEmpty)
                      _DetailCard(
                        icon: Icons.language,
                        label: 'Language',
                        value: _currentBook.languageValue!,
                      ),
                    if (_currentBook.placeValue != null &&
                        _currentBook.placeValue!.isNotEmpty)
                      _DetailCard(
                        icon: Icons.place,
                        label: 'Place',
                        value: _currentBook.placeValue!,
                      ),
                    if (_currentBook.formatValue != null &&
                        _currentBook.formatValue!.isNotEmpty)
                      _DetailCard(
                        icon: Icons.import_contacts,
                        label: 'Format',
                        value: _currentBook.formatValue!,
                      ),
                    if (_currentBook.loaned != null &&
                        _currentBook.loaned!.isNotEmpty)
                      _DetailCard(
                        icon: Icons.swap_horiz,
                        label: 'Loaned',
                        value: _currentBook.loaned!,
                      ),
                    if (_currentBook.createdAt != null &&
                        _currentBook.createdAt!.isNotEmpty)
                      _DetailCard(
                        icon: Icons.access_time,
                        label: 'Created',
                        value: _formatDateTime(_currentBook.createdAt!),
                      ),

                    // Bundle information
                    if (_currentBook.isBundle == true) ...[
                      _DetailCard(
                        icon: Icons.library_books,
                        label: 'Bundle',
                        value:
                            'Contains ${_currentBook.bundleCount ?? 0} books',
                      ),
                      if (_currentBook.bundleNumbers != null &&
                          _currentBook.bundleNumbers!.isNotEmpty)
                        _DetailCard(
                          icon: Icons.format_list_numbered,
                          label: 'Saga Numbers',
                          value: _currentBook.bundleNumbers!,
                        ),
                      if (_currentBook.bundleStartDates != null ||
                          _currentBook.bundleEndDates != null ||
                          _currentBook.bundlePages != null)
                        _BundleDatesCard(
                          startDates: _currentBook.bundleStartDates,
                          endDates: _currentBook.bundleEndDates,
                          bundlePages: _currentBook.bundlePages,
                        ),
                    ],

                    // TBR Badge with Checkbox
                    if (_currentBook.tbr == true)
                      Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 12),
                        color: Colors.orange.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CheckboxListTile(
                          value: true,
                          onChanged: (value) async {
                            if (value == false) {
                              // Uncheck TBR
                              try {
                                final db = await DatabaseHelper.instance.database;
                                await db.update(
                                  'book',
                                  {'tbr': 0},
                                  where: 'book_id = ?',
                                  whereArgs: [_currentBook.bookId],
                                );
                                
                                if (mounted) {
                                  // Reload provider and navigate back
                                  final provider = Provider.of<BookProvider?>(context, listen: false);
                                  await provider?.loadBooks();
                                  
                                  // Refresh the screen by popping and pushing again
                                  final updatedBooks = provider?.allBooks ?? [];
                                  final updatedBook = updatedBooks.firstWhere(
                                    (b) => b.bookId == _currentBook.bookId,
                                    orElse: () => _currentBook,
                                  );
                                  
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BookDetailScreen(book: updatedBook),
                                    ),
                                  );
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Removed from TBR'),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          secondary: Icon(
                            Icons.bookmark_add,
                            color: Colors.orange,
                            size: 24,
                          ),
                          title: Text(
                            'To Be Read',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          subtitle: const Text('This book is in your TBR list'),
                        ),
                      ),

                    // Tandem Books
                    if (_currentBook.isTandem == true)
                      _TandemBooksCard(
                        saga: _currentBook.saga,
                        sagaUniverse: _currentBook.sagaUniverse,
                        currentBookId: _currentBook.bookId,
                      ),

                    // New fields
                    if (_currentBook.myRating != null &&
                        _currentBook.myRating! > 0)
                      _RatingCard(
                        label: 'My Rating',
                        rating: _currentBook.myRating!,
                      ),
                    if (_currentBook.readCount != null &&
                        _currentBook.readCount! > 0)
                      _DetailCard(
                        icon: Icons.add_circle_outline,
                        label: 'Times Read',
                        value: '${_currentBook.readCount}',
                      ),
                    if (_currentBook.dateReadInitial != null &&
                        _currentBook.dateReadInitial!.isNotEmpty)
                      _DetailCard(
                        icon: Icons.event,
                        label: 'Date Started Reading',
                        value: _currentBook.dateReadInitial!.split('T')[0],
                      ),
                    if (_currentBook.dateReadFinal != null &&
                        _currentBook.dateReadFinal!.isNotEmpty)
                      _DetailCard(
                        icon: Icons.event_available,
                        label: 'Date Finished Reading',
                        value: _currentBook.dateReadFinal!.split('T')[0],
                      ),
                    if (_currentBook.myReview != null &&
                        _currentBook.myReview!.isNotEmpty)
                      Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: AppTheme.cardPadding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.rate_review,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 24,
                                  ),
                                  AppTheme.horizontalSpaceLarge,
                                  Text(
                                    'My Review',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium?.copyWith(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              AppTheme.verticalSpaceMedium,
                              Text(
                                _currentBook.myReview!,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              AppTheme.verticalSpaceXXLarge, // Bottom margin
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  final String label;
  final double rating;

  const _RatingCard({required this.label, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) {
                final heartValue = index + 1;
                final isFilled = rating >= heartValue;
                final isPartial =
                    !isFilled && rating > index && rating < heartValue;

                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: _buildHeart(isFilled, isPartial),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeart(bool isFilled, bool isPartial) {
    if (isFilled) {
      return const Icon(Icons.favorite, color: Colors.red, size: 28);
    } else if (isPartial) {
      return Stack(
        children: [
          Icon(Icons.favorite_border, color: Colors.grey[400], size: 28),
          ClipRect(
            clipper: _HalfClipper(),
            child: const Icon(Icons.favorite, color: Colors.red, size: 28),
          ),
        ],
      );
    } else {
      return Icon(Icons.favorite_border, color: Colors.grey[400], size: 28);
    }
  }
}

class _HalfClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width / 2, size.height);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => false;
}

class _BundleDatesCard extends StatelessWidget {
  final String? startDates;
  final String? endDates;
  final String? bundlePages;

  const _BundleDatesCard({this.startDates, this.endDates, this.bundlePages});

  @override
  Widget build(BuildContext context) {
    List<DateTime?>? starts;
    List<DateTime?>? ends;
    List<int?>? pages;

    try {
      if (startDates != null) {
        final List<dynamic> dates = jsonDecode(startDates!);
        starts =
            dates.map((d) => d != null ? DateTime.parse(d) : null).toList();
      }
    } catch (e) {
      starts = null;
    }

    try {
      if (endDates != null) {
        final List<dynamic> dates = jsonDecode(endDates!);
        ends = dates.map((d) => d != null ? DateTime.parse(d) : null).toList();
      }
    } catch (e) {
      ends = null;
    }

    try {
      if (bundlePages != null) {
        final List<dynamic> pagesData = jsonDecode(bundlePages!);
        pages = pagesData.map((p) => p as int?).toList();
      }
    } catch (e) {
      pages = null;
    }

    final maxLength = [
      starts?.length ?? 0,
      ends?.length ?? 0,
      pages?.length ?? 0,
    ].reduce((a, b) => a > b ? a : b);

    if (maxLength == 0) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_month,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  'Bundle Reading Dates',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(maxLength, (index) {
              final start =
                  starts != null && index < starts.length
                      ? starts[index]
                      : null;
              final end =
                  ends != null && index < ends.length ? ends[index] : null;
              final pageCount =
                  pages != null && index < pages.length ? pages[index] : null;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Book ${index + 1}:',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            start != null
                                ? '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}'
                                : '-',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const Text(' → '),
                        Expanded(
                          child: Text(
                            end != null
                                ? '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}'
                                : '-',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    if (pageCount != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 4),
                        child: Text(
                          'Pages: $pageCount',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600], fontSize: 12),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final IconData? trailingIcon;

  const _DetailCard({
    required this.icon,
    required this.label,
    required this.value,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(value, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 8),
              Icon(
                trailingIcon,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TandemBooksCard extends StatefulWidget {
  final String? saga;
  final String? sagaUniverse;
  final int? currentBookId;

  const _TandemBooksCard({this.saga, this.sagaUniverse, this.currentBookId});

  @override
  State<_TandemBooksCard> createState() => _TandemBooksCardState();
}

class _TandemBooksCardState extends State<_TandemBooksCard> {
  List<dynamic> _tandemBooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTandemBooks();
  }

  Future<void> _loadTandemBooks() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);
      final books = await repository.getTandemBooks(
        widget.saga,
        widget.sagaUniverse,
      );

      final filteredBooks =
          books.where((book) => book.bookId != widget.currentBookId).toList();

      if (mounted) {
        setState(() {
          _tandemBooks = filteredBooks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.deepPurple.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.swap_horizontal_circle_outlined,
                  color: Colors.deepPurple,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tandem Books',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Read together with these books',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_tandemBooks.isEmpty)
              Text(
                'No other tandem books in this saga',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ..._tandemBooks.map((book) {
                return InkWell(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookDetailScreen(book: book),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.deepPurple.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.menu_book,
                          size: 20,
                          color: Colors.deepPurple,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book.name ?? 'Unknown',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              if (book.author != null &&
                                  book.author!.isNotEmpty)
                                Text(
                                  book.author!,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }
}

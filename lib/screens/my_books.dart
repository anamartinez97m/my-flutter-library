import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/repositories/reading_club_repository.dart';
import 'package:myrandomlibrary/screens/book_detail.dart';
import 'package:provider/provider.dart';

class MyBooksScreen extends StatefulWidget {
  const MyBooksScreen({super.key});

  @override
  State<MyBooksScreen> createState() => _MyBooksScreenState();
}

class _MyBooksScreenState extends State<MyBooksScreen> {
  bool _showCurrentlyReading = true;
  bool _isCurrentlyReadingExpanded = true;
  final GlobalKey<_ClubsCardState> _clubsCardKey = GlobalKey<_ClubsCardState>();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookProvider?>(context);

    if (provider == null || provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Filter books that are currently being read
    final currentlyReading =
        provider.allBooks.where((book) {
          final statusLower = book.statusValue?.toLowerCase();
          return statusLower == 'started' ||
              (statusLower == 'no' &&
                  book.dateReadInitial != null &&
                  book.dateReadFinal == null);
        }).toList();

    // Filter books with standby status
    final standbyBooks =
        provider.allBooks.where((book) {
          final statusLower = book.statusValue?.toLowerCase();
          return statusLower == 'standby';
        }).toList();

    final booksToDisplay =
        _showCurrentlyReading ? currentlyReading : standbyBooks;
    final emptyMessage =
        _showCurrentlyReading
            ? 'No books currently reading'
            : 'No books on standby';

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Currently Reading / Standby Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                initiallyExpanded: _isCurrentlyReadingExpanded,
                onExpansionChanged: (expanded) {
                  setState(() {
                    _isCurrentlyReadingExpanded = expanded;
                  });
                },
                leading: Icon(
                  _showCurrentlyReading
                      ? Icons.menu_book
                      : Icons.pause_circle,
                  color: Colors.deepPurple,
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Toggle buttons
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.deepPurple.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                _showCurrentlyReading = true;
                              });
                            },
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(7),
                              bottomLeft: Radius.circular(7),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _showCurrentlyReading
                                    ? Colors.deepPurple.withOpacity(0.1)
                                    : Colors.transparent,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(7),
                                  bottomLeft: Radius.circular(7),
                                ),
                              ),
                              child: Text(
                                'Reading',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _showCurrentlyReading
                                      ? Colors.deepPurple
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 20,
                            color: Colors.deepPurple.withOpacity(0.2),
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _showCurrentlyReading = false;
                              });
                            },
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(7),
                              bottomRight: Radius.circular(7),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: !_showCurrentlyReading
                                    ? Colors.deepPurple.withOpacity(0.1)
                                    : Colors.transparent,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(7),
                                  bottomRight: Radius.circular(7),
                                ),
                              ),
                              child: Text(
                                'Standby',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: !_showCurrentlyReading
                                      ? Colors.deepPurple
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        if (booksToDisplay.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Column(
                                children: [
                                  Icon(
                                    _showCurrentlyReading
                                        ? Icons.menu_book_outlined
                                        : Icons.pause_circle_outline,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    emptyMessage,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...booksToDisplay.map((book) {
                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        BookDetailScreen(book: book),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.deepPurple.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Book cover placeholder
                                    Container(
                                      width: 50,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.deepPurple.shade300,
                                            Colors.deepPurple.shade600,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 4,
                                            offset: const Offset(2, 2),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          (book.name?.isNotEmpty ?? false)
                                              ? book.name![0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            book.name ?? 'Unknown',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          if (book.author != null &&
                                              book.author!.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              book.author!,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                            ),
                                          ],
                                          // Progress bar (always show for reading/standby books)
                                          if (book.statusValue?.toLowerCase() ==
                                                  'started' ||
                                              book.statusValue?.toLowerCase() ==
                                                  'standby') ...[
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(4),
                                                    child:
                                                        LinearProgressIndicator(
                                                      value: (book
                                                                  .readingProgress ??
                                                              0) /
                                                          100,
                                                      minHeight: 6,
                                                      backgroundColor:
                                                          Colors.grey[300],
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                              Color>(
                                                        Colors.deepPurple,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  '${book.readingProgress ?? 0}%',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Colors.deepPurple,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ],
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
                          }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Clubs Card
            _ClubsCard(key: _clubsCardKey),
            const SizedBox(height: 16),
            // TBR Card
            _TBRCard(provider: provider),
          ],
        ),
      ),
    );
  }
}

class _TBRCard extends StatefulWidget {
  final BookProvider? provider;

  const _TBRCard({required this.provider});

  @override
  State<_TBRCard> createState() => _TBRCardState();
}

class _TBRCardState extends State<_TBRCard> with WidgetsBindingObserver {
  List<dynamic> _tbrBooks = [];
  bool _isLoading = true;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTBRBooks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadTBRBooks();
    }
  }

  Future<void> _loadTBRBooks() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);
      final books = await repository.getTBRBooks();

      if (mounted) {
        setState(() {
          _tbrBooks = books;
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

  Future<void> _uncheckTBR(dynamic book) async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Update book to uncheck TBR
      await db.update(
        'book',
        {'tbr': 0},
        where: 'book_id = ?',
        whereArgs: [book.bookId],
      );

      // Reload books
      await widget.provider?.loadBooks();
      await _loadTBRBooks();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${book.name} removed from TBR'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        initiallyExpanded: _isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        leading: Icon(Icons.bookmark, color: Colors.deepPurple),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'To Be Read (TBR)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            if (_tbrBooks.isNotEmpty)
              Chip(
                label: Text('${_tbrBooks.length}'),
                backgroundColor: Colors.deepPurple.withOpacity(0.1),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_tbrBooks.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.bookmark_border,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No books in TBR',
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._tbrBooks.map((book) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Book cover placeholder
                          InkWell(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      BookDetailScreen(book: book),
                                ),
                              );
                              // Reload TBR list when returning from book detail
                              _loadTBRBooks();
                            },
                            child: Container(
                              width: 50,
                              height: 70,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.orange.shade300,
                                    Colors.orange.shade600,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(2, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  (book.name?.isNotEmpty ?? false)
                                      ? book.name![0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        BookDetailScreen(book: book),
                                  ),
                                );
                                // Reload TBR list when returning from book detail
                                _loadTBRBooks();
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    book.name ?? 'Unknown',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  if (book.author != null &&
                                      book.author!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      book.author!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            color: Colors.orange,
                            onPressed: () => _uncheckTBR(book),
                            tooltip: 'Remove from TBR',
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClubsCard extends StatefulWidget {
  const _ClubsCard({super.key});

  @override
  State<_ClubsCard> createState() => _ClubsCardState();
}

class _ClubsCardState extends State<_ClubsCard> with WidgetsBindingObserver {
  bool _isExpanded = false;
  Map<String, List<Map<String, dynamic>>> _clubsData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadClubs();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadClubs();
    }
  }

  Future<void> _loadClubs() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final repository = ReadingClubRepository(db);
      final allClubs = await repository.getAllClubsWithBooks();

      // Group by club name
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final club in allClubs) {
        final clubName = club['club_name'] as String;
        if (!grouped.containsKey(clubName)) {
          grouped[clubName] = [];
        }
        grouped[clubName]!.add(club);
      }

      if (mounted) {
        setState(() {
          _clubsData = grouped;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading clubs: $e');
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        initiallyExpanded: _isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        leading: Icon(Icons.groups, color: Colors.teal),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Clubs',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            if (_clubsData.isNotEmpty)
              Chip(
                label: Text('${_clubsData.length}'),
                backgroundColor: Colors.teal.withOpacity(0.1),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_clubsData.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.groups_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No clubs yet',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add books to clubs from book details',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._clubsData.entries.map((entry) {
                    final clubName = entry.key;
                    final books = entry.value;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.teal.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        title: Row(
                          children: [
                            Icon(Icons.group, color: Colors.teal, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                clubName,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal[700],
                                ),
                              ),
                            ),
                            Chip(
                              label: Text('${books.length}'),
                              backgroundColor: Colors.teal.withOpacity(0.2),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal[900],
                              ),
                            ),
                          ],
                        ),
                        children: books.map((book) {
                          final progress = book['reading_progress'] as int? ?? 0;
                          final targetDate = book['target_date'] as String?;
                          
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.teal.withOpacity(0.1),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  book['book_name'] as String? ?? 'Unknown',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (book['author'] != null && (book['author'] as String).isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    book['author'] as String,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                                if (targetDate != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Target: $targetDate',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: progress / 100,
                                          minHeight: 6,
                                          backgroundColor: Colors.grey[300],
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '$progress%',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

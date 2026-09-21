import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/model/tandem_reading.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/repositories/tandem_repository.dart';
import 'package:myrandomlibrary/screens/new_ui/tandem_reading_screen.dart';

/// Screen for creating a new tandem reading between two books.
class TandemCreateScreen extends StatefulWidget {
  /// Optionally pre-select one of the books (e.g. the book the user came from).
  final Book? initialBook;

  const TandemCreateScreen({super.key, this.initialBook});

  @override
  State<TandemCreateScreen> createState() => _TandemCreateScreenState();
}

class _TandemCreateScreenState extends State<TandemCreateScreen> {
  static const _kPrimary = Color(0xFF43102B);
  static const _kSub = Color(0xFF514348);
  static const _kBg = Color(0xFFFDF8F6);
  static const _kBorder = Color(0xFFD5C2C7);
  static const _kText = Color(0xFF1C1B1A);

  Book? _bookA;
  Book? _bookB;
  final TextEditingController _titleController = TextEditingController();
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _bookA = widget.initialBook;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickBook(bool isBookA) async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await Navigator.push<Book>(
      context,
      MaterialPageRoute(
        builder:
            (context) => _TandemBookPickerScreen(
              title: isBookA ? l10n.select_book_a : l10n.select_book_b,
            ),
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isBookA) {
          _bookA = picked;
        } else {
          _bookB = picked;
        }
      });
    }
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context)!;
    if (_bookA == null || _bookB == null) {
      _showError(l10n.select_both_books_error);
      return;
    }
    if (_bookA!.bookId == _bookB!.bookId) {
      _showError(l10n.same_book_error);
      return;
    }

    setState(() => _isCreating = true);
    try {
      final db = await DatabaseHelper.instance.database;
      final repository = TandemRepository(db);
      final title = _titleController.text.trim();
      final tandemId = await repository.createTandem(
        TandemReading(
          bookAId: _bookA!.bookId!,
          bookBId: _bookB!.bookId!,
          title: title.isEmpty ? null : title,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.tandem_created)));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TandemReadingScreen(tandemId: tandemId),
          ),
        );
      }
    } catch (e) {
      if (mounted) _showError('${l10n.error}: $e');
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.create_tandem,
          style: const TextStyle(
            color: _kPrimary,
            fontFamily: 'Manrope',
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _kBorder),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BookSelector(
                label: l10n.select_book_a,
                book: _bookA,
                accent: _kPrimary,
                onTap: () => _pickBook(true),
              ),
              const SizedBox(height: 8),
              const Icon(Icons.swap_vert, color: _kPrimary),
              const SizedBox(height: 8),
              _BookSelector(
                label: l10n.select_book_b,
                book: _bookB,
                accent: _kPrimary,
                onTap: () => _pickBook(false),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kBorder),
                ),
                child: TextField(
                  controller: _titleController,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 15,
                    color: _kText,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.tandem_title_optional,
                    labelStyle: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      color: _kSub,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _create,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isCreating
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Text(
                            l10n.create_tandem,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookSelector extends StatelessWidget {
  final String label;
  final Book? book;
  final Color accent;
  final VoidCallback onTap;

  const _BookSelector({
    required this.label,
    required this.book,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: book != null ? accent : const Color(0xFFD5C2C7),
            width: book != null ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            _CoverThumb(coverUrl: book?.coverUrl, accent: accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    book?.name ?? label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      fontWeight:
                          book != null ? FontWeight.w700 : FontWeight.w500,
                      color:
                          book != null
                              ? const Color(0xFF1C1B1A)
                              : const Color(0xFF514348),
                    ),
                  ),
                  if (book?.author != null && book!.author!.isNotEmpty)
                    Text(
                      book!.author!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12,
                        color: Color(0xFF514348),
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              book == null ? Icons.add_circle_outline : Icons.swap_horiz,
              color: accent,
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverThumb extends StatelessWidget {
  final String? coverUrl;
  final Color accent;
  final double size;

  const _CoverThumb({this.coverUrl, required this.accent, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final url = coverUrl?.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: size,
        height: size * 1.4,
        color: accent.withValues(alpha: 0.1),
        child:
            url == null || url.isEmpty
                ? Icon(Icons.menu_book, color: accent, size: size * 0.45)
                : Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) =>
                          Icon(Icons.menu_book, color: accent),
                ),
      ),
    );
  }
}

/// Simple searchable book picker used to select Book A / Book B.
class _TandemBookPickerScreen extends StatefulWidget {
  final String title;

  const _TandemBookPickerScreen({required this.title});

  @override
  State<_TandemBookPickerScreen> createState() =>
      _TandemBookPickerScreenState();
}

class _TandemBookPickerScreenState extends State<_TandemBookPickerScreen> {
  static const _kPrimary = Color(0xFF43102B);
  static const _kSub = Color(0xFF514348);
  static const _kBg = Color(0xFFFDF8F6);
  static const _kBorder = Color(0xFFD5C2C7);

  final TextEditingController _searchController = TextEditingController();
  List<Book> _results = [];
  bool _loading = false;

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    try {
      final db = await DatabaseHelper.instance.database;
      final books = await BookRepository(db).searchBooks(query.trim(), 0);
      if (mounted) {
        setState(() {
          _results = books;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: _kPrimary,
            fontFamily: 'Manrope',
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _kBorder),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBorder),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _search,
                style: const TextStyle(fontFamily: 'Manrope', fontSize: 15),
                decoration: InputDecoration(
                  hintText: l10n.search_by_title,
                  hintStyle: const TextStyle(
                    fontFamily: 'Manrope',
                    color: _kSub,
                  ),
                  icon: const Icon(Icons.search, color: _kSub),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Expanded(
            child:
                _loading
                    ? const Center(
                      child: CircularProgressIndicator(color: _kPrimary),
                    )
                    : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final book = _results[index];
                        return ListTile(
                          leading: _CoverThumb(
                            coverUrl: book.coverUrl,
                            accent: _kPrimary,
                            size: 32,
                          ),
                          title: Text(
                            book.name ?? l10n.unknown_title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle:
                              book.author != null && book.author!.isNotEmpty
                                  ? Text(
                                    book.author!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 12,
                                      color: _kSub,
                                    ),
                                  )
                                  : null,
                          onTap: () => Navigator.pop(context, book),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

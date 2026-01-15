import 'dart:math';
import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/screens/book_detail.dart';
import 'package:myrandomlibrary/widgets/chip_autocomplete_field.dart';
import 'package:provider/provider.dart';

class RandomScreen extends StatefulWidget {
  const RandomScreen({super.key});

  @override
  State<RandomScreen> createState() => _RandomScreenState();
}

class _RandomScreenState extends State<RandomScreen> {
  // Filter values
  String? _filterFormat;
  String? _filterLanguage;
  List<String> _filterGenre = [];
  String? _filterPlace;
  List<String> _filterStatus = [];
  String? _filterEditorial;
  String? _filterFormatSaga;
  String? _filterPages;
  String? _filterYear;
  String? _filterAuthor;
  bool? _filterTBR;

  // Dropdown options
  List<Map<String, dynamic>> _formatList = [];
  List<Map<String, dynamic>> _languageList = [];
  List<Map<String, dynamic>> _genreList = [];
  List<Map<String, dynamic>> _placeList = [];
  List<Map<String, dynamic>> _statusList = [];
  List<Map<String, dynamic>> _editorialList = [];
  List<Map<String, dynamic>> _formatSagaList = [];
  List<Map<String, dynamic>> _authorList = [];

  // Random book
  Book? _randomBook;
  bool _isLoading = true;
  
  // Custom book selection
  List<String> _selectedBookTitles = [];
  bool _useCustomList = false;

  @override
  void initState() {
    super.initState();
    _loadFilters();
  }

  Future<void> _loadFilters() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);

      final format = await repository.getLookupValues('format');
      final language = await repository.getLookupValues('language');
      final genre = await repository.getLookupValues('genre');
      final place = await repository.getLookupValues('place');
      final status = await repository.getLookupValues('status');
      final editorial = await repository.getLookupValues('editorial');
      final formatSaga = await repository.getLookupValues('format_saga');
      final author = await repository.getLookupValues('author');

      setState(() {
        _formatList = format;
        _languageList = language;
        _genreList = genre;
        _placeList = place;
        _statusList = status;
        _editorialList = editorial;
        _formatSagaList = formatSaga;
        _authorList = author;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading filters: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _getRandomBook() {
    final provider = Provider.of<BookProvider?>(context, listen: false);
    if (provider == null) return;

    List<Book> filtered;
    
    // If using custom list, filter by selected titles only
    if (_useCustomList && _selectedBookTitles.isNotEmpty) {
      filtered = provider.allBooks.where((book) {
        return _selectedBookTitles.contains(book.name);
      }).toList();
    } else {
      // Use regular filters
      filtered = provider.allBooks.where((book) {
        // Status filter (optional) - multiple selection
        if (_filterStatus.isNotEmpty && 
            (book.statusValue == null || !_filterStatus.contains(book.statusValue))) {
          return false;
        }
        
        // TBR filter (optional)
        if (_filterTBR != null && book.tbr != _filterTBR) {
          return false;
        }
        
        if (_filterFormat != null && book.formatValue != _filterFormat) {
          return false;
        }
        if (_filterLanguage != null &&
            book.languageValue != _filterLanguage) {
          return false;
        }
        // Genre filter (optional) - multiple selection (AND logic)
        if (_filterGenre.isNotEmpty) {
          final bookGenres = book.genre?.split(',').map((g) => g.trim()).toList() ?? [];
          final hasAllGenres = _filterGenre.every((selectedGenre) => 
            bookGenres.contains(selectedGenre));
          if (!hasAllGenres) {
            return false;
          }
        }
        if (_filterPlace != null && book.placeValue != _filterPlace) {
          return false;
        }
        if (_filterEditorial != null && book.editorialValue != _filterEditorial) {
          return false;
        }
        if (_filterFormatSaga != null && book.formatSagaValue != _filterFormatSaga) {
          return false;
        }
        if (_filterAuthor != null && !(book.author?.contains(_filterAuthor!) ?? false)) {
          return false;
        }
        
        // Pages filter with ranges
        if (_filterPages != null && book.pages != null) {
          final pages = book.pages!;
          switch (_filterPages) {
            case '0-200':
              if (pages < 0 || pages > 200) return false;
              break;
            case '200-400':
              if (pages < 200 || pages > 400) return false;
              break;
            case '400-600':
              if (pages < 400 || pages > 600) return false;
              break;
            case '600-900':
              if (pages < 600 || pages > 900) return false;
              break;
            case '900+':
              if (pages < 900) return false;
              break;
          }
        }
        
        // Year filter with decades
        if (_filterYear != null && book.originalPublicationYear != null) {
          final year = book.originalPublicationYear!;
          final decade = (year ~/ 10) * 10;
          final filterDecade = int.tryParse(_filterYear!);
          if (filterDecade != null && decade != filterDecade) {
            return false;
          }
        }
        
        return true;
      }).toList();
    }

    // Apply saga-aware filtering: if a book is part of a saga, only recommend the next unread book
    final sagaFilteredBooks = _filterBySagaOrder(filtered, provider.allBooks);

    if (sagaFilteredBooks.isEmpty) {
      setState(() {
        _randomBook = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No books match the selected filters')),
      );
      return;
    }

    final random = Random();
    setState(() {
      _randomBook = sagaFilteredBooks[random.nextInt(sagaFilteredBooks.length)];
    });
  }

  /// Filter books to only recommend the next unread book in a saga
  List<Book> _filterBySagaOrder(List<Book> filtered, List<Book> allBooks) {
    final result = <Book>[];
    
    for (final book in filtered) {
      // If book is not part of a saga, include it
      if (book.saga == null || book.saga!.isEmpty) {
        result.add(book);
        continue;
      }
      
      // Book is part of a saga - check if it's the next unread book
      final sagaName = book.saga!;
      final bookNSaga = book.nSaga;
      
      if (bookNSaga == null || bookNSaga.isEmpty) {
        // No saga number, include it
        result.add(book);
        continue;
      }
      
      final currentNumber = int.tryParse(bookNSaga);
      if (currentNumber == null) {
        // Can't parse saga number, include it
        result.add(book);
        continue;
      }
      
      // Get all books in this saga
      final sagaBooks = allBooks
          .where((b) => b.saga == sagaName && b.nSaga != null && b.nSaga!.isNotEmpty)
          .toList();
      
      // Sort by saga number
      sagaBooks.sort((a, b) {
        final aNum = int.tryParse(a.nSaga ?? '0') ?? 0;
        final bNum = int.tryParse(b.nSaga ?? '0') ?? 0;
        return aNum.compareTo(bNum);
      });
      
      // Check if all previous books in the saga have been read
      bool canRecommend = true;
      for (final sagaBook in sagaBooks) {
        final sagaBookNumber = int.tryParse(sagaBook.nSaga ?? '0') ?? 0;
        
        if (sagaBookNumber < currentNumber) {
          // This is a previous book - check if it's been read
          final isRead = sagaBook.statusValue != null && 
                        (sagaBook.statusValue!.toLowerCase().contains('read') ||
                         sagaBook.statusValue!.toLowerCase().contains('leído') ||
                         sagaBook.statusValue!.toLowerCase().contains('reread'));
          
          if (!isRead) {
            // Previous book not read, don't recommend this one
            canRecommend = false;
            break;
          }
        }
      }
      
      if (canRecommend) {
        result.add(book);
      }
    }
    
    return result;
  }

  void _clearFilters() {
    setState(() {
      _filterFormat = null;
      _filterLanguage = null;
      _filterGenre = [];
      _filterPlace = null;
      _filterStatus = [];
      _filterEditorial = null;
      _filterFormatSaga = null;
      _filterPages = null;
      _filterYear = null;
      _filterAuthor = null;
      _filterTBR = null;
      _randomBook = null;
      _selectedBookTitles = [];
      _useCustomList = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Text(
              'Random Book Picker',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Apply filters and get a random book suggestion',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Filters
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.filters,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Format filter
                    DropdownButtonFormField<String>(
                      value: _filterFormat,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.format,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        DropdownMenuItem(value: null, child: Text(AppLocalizations.of(context)!.any)),
                        ..._formatList.map((format) {
                          return DropdownMenuItem<String>(
                            value: format['value'] as String,
                            child: Text(format['value'] as String),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filterFormat = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Language filter
                    DropdownButtonFormField<String>(
                      value: _filterLanguage,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.language,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        DropdownMenuItem(value: null, child: Text(AppLocalizations.of(context)!.any)),
                        ..._languageList.map((lang) {
                          return DropdownMenuItem<String>(
                            value: lang['name'] as String,
                            child: Text(lang['name'] as String),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filterLanguage = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Genre filter - Multiple selection
                    ChipAutocompleteField(
                      labelText: AppLocalizations.of(context)!.genre,
                      prefixIcon: Icons.category,
                      suggestions: _genreList
                          .map((genre) => genre['name'] as String)
                          .toList(),
                      initialValues: _filterGenre,
                      hintText: 'Select one or more genres',
                      onChanged: (values) {
                        setState(() {
                          _filterGenre = values;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Place filter
                    DropdownButtonFormField<String>(
                      value: _filterPlace,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.place,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        DropdownMenuItem(value: null, child: Text(AppLocalizations.of(context)!.any)),
                        ..._placeList.map((place) {
                          return DropdownMenuItem<String>(
                            value: place['name'] as String,
                            child: Text(place['name'] as String),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filterPlace = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Status filter - Multiple selection
                    ChipAutocompleteField(
                      labelText: AppLocalizations.of(context)!.status,
                      prefixIcon: Icons.bookmark,
                      suggestions: _statusList
                          .map((status) => status['value'] as String)
                          .toList(),
                      initialValues: _filterStatus,
                      hintText: 'Select one or more statuses',
                      onChanged: (values) {
                        setState(() {
                          _filterStatus = values;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // TBR filter
                    DropdownButtonFormField<bool?>(
                      value: _filterTBR,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'TBR (To Be Read)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Any')),
                        DropdownMenuItem(value: true, child: Text('Yes - In TBR')),
                        DropdownMenuItem(value: false, child: Text('No - Not in TBR')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filterTBR = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Editorial filter
                    DropdownButtonFormField<String>(
                      value: _filterEditorial,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.editorial,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        DropdownMenuItem(value: null, child: Text(AppLocalizations.of(context)!.any)),
                        ..._editorialList.map((editorial) {
                          return DropdownMenuItem<String>(
                            value: editorial['name'] as String,
                            child: Text(editorial['name'] as String),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filterEditorial = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Format Saga filter
                    DropdownButtonFormField<String>(
                      value: _filterFormatSaga,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.format_saga,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        DropdownMenuItem(value: null, child: Text(AppLocalizations.of(context)!.any)),
                        ..._formatSagaList.map((formatSaga) {
                          return DropdownMenuItem<String>(
                            value: formatSaga['value'] as String,
                            child: Text(formatSaga['value'] as String),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filterFormatSaga = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Pages filter (ranges)
                    DropdownButtonFormField<String>(
                      value: _filterPages,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.pages,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Any')),
                        DropdownMenuItem(value: '0-200', child: Text('0-200')),
                        DropdownMenuItem(value: '200-400', child: Text('200-400')),
                        DropdownMenuItem(value: '400-600', child: Text('400-600')),
                        DropdownMenuItem(value: '600-900', child: Text('600-900')),
                        DropdownMenuItem(value: '900+', child: Text('900+')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filterPages = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Year filter (decades)
                    DropdownButtonFormField<String>(
                      value: _filterYear,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Publication Year (by decade)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Any')),
                        DropdownMenuItem(value: '1900', child: Text('1900s')),
                        DropdownMenuItem(value: '1910', child: Text('1910s')),
                        DropdownMenuItem(value: '1920', child: Text('1920s')),
                        DropdownMenuItem(value: '1930', child: Text('1930s')),
                        DropdownMenuItem(value: '1940', child: Text('1940s')),
                        DropdownMenuItem(value: '1950', child: Text('1950s')),
                        DropdownMenuItem(value: '1960', child: Text('1960s')),
                        DropdownMenuItem(value: '1970', child: Text('1970s')),
                        DropdownMenuItem(value: '1980', child: Text('1980s')),
                        DropdownMenuItem(value: '1990', child: Text('1990s')),
                        DropdownMenuItem(value: '2000', child: Text('2000s')),
                        DropdownMenuItem(value: '2010', child: Text('2010s')),
                        DropdownMenuItem(value: '2020', child: Text('2020s')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filterYear = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Author filter
                    DropdownButtonFormField<String>(
                      value: _filterAuthor,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.author,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        DropdownMenuItem(value: null, child: Text(AppLocalizations.of(context)!.any)),
                        ..._authorList.map((author) {
                          return DropdownMenuItem<String>(
                            value: author['name'] as String,
                            child: Text(author['name'] as String),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filterAuthor = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Divider
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    // Custom book selection
                    Text(
                      'Or select specific books',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Search and select books by title to pick randomly from your custom list',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    Consumer<BookProvider>(
                      builder: (context, provider, child) {
                        final bookTitles = provider.allBooks
                            .map((book) => book.name ?? '')
                            .where((name) => name.isNotEmpty)
                            .toList()
                          ..sort();
                        
                        return ChipAutocompleteField(
                          labelText: 'Select Books',
                          prefixIcon: Icons.library_books,
                          suggestions: bookTitles,
                          initialValues: _selectedBookTitles,
                          hintText: 'Type to search books by title',
                          onChanged: (values) {
                            setState(() {
                              _selectedBookTitles = values;
                              _useCustomList = values.isNotEmpty;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _getRandomBook,
                            icon: const Icon(Icons.casino),
                            label: Text(
                              _useCustomList 
                                ? 'Random from Selected (${_selectedBookTitles.length})'
                                : AppLocalizations.of(context)!.get_random_book
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _clearFilters,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                          ),
                          child: Text(AppLocalizations.of(context)!.clear),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Random Book Result
            if (_randomBook != null)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => BookDetailScreen(book: _randomBook!),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.book,
                          size: 60,
                          color: Colors.deepPurple,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _randomBook!.name ?? 'Unknown',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_randomBook!.author != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'by ${_randomBook!.author}',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _getRandomBook,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Another'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap card to view details',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

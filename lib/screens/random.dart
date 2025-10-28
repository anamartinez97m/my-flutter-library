import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mylibrary/db/database_helper.dart';
import 'package:mylibrary/model/book.dart';
import 'package:mylibrary/providers/book_provider.dart';
import 'package:mylibrary/repositories/book_repository.dart';
import 'package:mylibrary/screens/book_detail.dart';
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
  String? _filterGenre;
  String? _filterPlace;
  
  // Dropdown options
  List<Map<String, dynamic>> _formatList = [];
  List<Map<String, dynamic>> _languageList = [];
  List<Map<String, dynamic>> _genreList = [];
  List<Map<String, dynamic>> _placeList = [];
  
  // Random book
  Book? _randomBook;
  bool _isLoading = true;

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
      
      setState(() {
        _formatList = format;
        _languageList = language;
        _genreList = genre;
        _placeList = place;
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

    List<Book> filtered = provider.books.where((book) {
      if (_filterFormat != null && book.formatValue != _filterFormat) {
        return false;
      }
      if (_filterLanguage != null && book.languageValue != _filterLanguage) {
        return false;
      }
      if (_filterGenre != null && !(book.genre?.contains(_filterGenre!) ?? false)) {
        return false;
      }
      if (_filterPlace != null && book.placeValue != _filterPlace) {
        return false;
      }
      return true;
    }).toList();

    if (filtered.isEmpty) {
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
      _randomBook = filtered[random.nextInt(filtered.length)];
    });
  }

  void _clearFilters() {
    setState(() {
      _filterFormat = null;
      _filterLanguage = null;
      _filterGenre = null;
      _filterPlace = null;
      _randomBook = null;
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
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
                      'Filters',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Format filter
                    DropdownButtonFormField<String>(
                      value: _filterFormat,
                      decoration: const InputDecoration(
                        labelText: 'Format',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Any')),
                        ..._formatList.map((format) {
                          return DropdownMenuItem<String>(
                            value: format['value'] as String,
                            child: Text(format['value'] as String),
                          );
                        }).toList(),
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
                      decoration: const InputDecoration(
                        labelText: 'Language',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Any')),
                        ..._languageList.map((lang) {
                          return DropdownMenuItem<String>(
                            value: lang['name'] as String,
                            child: Text(lang['name'] as String),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filterLanguage = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    // Genre filter
                    DropdownButtonFormField<String>(
                      value: _filterGenre,
                      decoration: const InputDecoration(
                        labelText: 'Genre',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Any')),
                        ..._genreList.map((genre) {
                          return DropdownMenuItem<String>(
                            value: genre['name'] as String,
                            child: Text(genre['name'] as String),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filterGenre = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    // Place filter
                    DropdownButtonFormField<String>(
                      value: _filterPlace,
                      decoration: const InputDecoration(
                        labelText: 'Place',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Any')),
                        ..._placeList.map((place) {
                          return DropdownMenuItem<String>(
                            value: place['name'] as String,
                            child: Text(place['name'] as String),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filterPlace = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _getRandomBook,
                            icon: const Icon(Icons.casino),
                            label: const Text('Get Random Book'),
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
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          ),
                          child: const Text('Clear'),
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
                        builder: (context) => BookDetailScreen(book: _randomBook!),
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
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

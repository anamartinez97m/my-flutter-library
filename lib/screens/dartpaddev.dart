import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// DATA_MODEL for a Book
class Book {
  final String title;
  final String isbn;
  final String author;

  Book({required this.title, required this.isbn, required this.author});
}

// DATA_MODEL and state management for books
// This replaces package:mylibrary/providers/book_provider.dart
class BookProvider with ChangeNotifier {
  bool _isLoading = false;
  List<Book> _books = <Book>[];
  final List<Book> _allBooks; // Stores all books for filtering purposes

  // Constructor uses an initializer list to populate _allBooks
  BookProvider() : _allBooks = _generateDummyBooks() {
    _books = _allBooks; // Initially display all books
  }

  // Static method to generate some dummy book data
  static List<Book> _generateDummyBooks() {
    return <Book>[
      Book(title: 'The Lord of the Rings', isbn: '978-0618260274', author: 'J.R.R. Tolkien'),
      Book(title: 'The Hobbit', isbn: '978-0345339683', author: 'J.R.R. Tolkien'),
      Book(title: '1984', isbn: '978-0451524935', author: 'George Orwell'),
      Book(title: 'Animal Farm', isbn: '978-0451526342', author: 'George Orwell'),
      Book(title: 'Pride and Prejudice', isbn: '978-0141439518', author: 'Jane Austen'),
      Book(title: 'To Kill a Mockingbird', isbn: '978-0061120084', author: 'Harper Lee'),
      Book(title: 'Dune', isbn: '978-0441172719', author: 'Frank Herbert'),
      Book(title: 'Foundation', isbn: '978-0553803717', author: 'Isaac Asimov'),
      Book(title: 'Neuromancer', isbn: '978-0441569595', author: 'William Gibson'),
    ];
  }

  bool get isLoading => _isLoading;
  List<Book> get books => _books;

  // Asynchronously searches for books based on a query and a search index
  Future<void> searchBooks(String query, {required int searchIndex}) async {
    _isLoading = true;
    notifyListeners();

    // Simulate a network delay for fetching results
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final String lowerCaseQuery = query.toLowerCase();

    if (query.isEmpty) {
      _books = _allBooks; // If query is empty, show all books
    } else {
      _books = _allBooks.where((Book book) {
        switch (searchIndex) {
          case 0: // Search by Title
            return book.title.toLowerCase().contains(lowerCaseQuery);
          case 1: // Search by ISBN
            return book.isbn.toLowerCase().contains(lowerCaseQuery);
          case 2: // Search by Author
            return book.author.toLowerCase().contains(lowerCaseQuery);
          default:
            return false; // Should not happen with valid searchIndex
        }
      }).toList();
    }

    _isLoading = false;
    notifyListeners();
  }
}

// UI Widget to display a list of books
// This replaces package:mylibrary/widgets/booklist.dart
class BookListView extends StatelessWidget {
  final List<Book> books;
  const BookListView({super.key, required this.books});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: books.length,
      itemBuilder: (BuildContext context, int index) {
        final Book book = books[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  book.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Author: ${book.author}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'ISBN: ${book.isbn}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Main application entry point
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Library App',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: ChangeNotifierProvider<BookProvider>(
        create: (BuildContext context) => BookProvider(),
        builder: (BuildContext context, Widget? child) {
          return const Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(kToolbarHeight),
              child: CustomAppBar(title: 'My Library'),
            ),
            body: HomeScreen(),
          );
        },
      ),
    );
  }
}

// Custom AppBar widget
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const CustomAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: true,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// Main screen displaying search functionality and book list
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedSearchButtonIndex = 0; // Tracks the currently selected search parameter (0: Title, 1: ISBN, 2: Author)

  // Helper method to perform the search
  Future<void> _performSearch(BookProvider provider) async {
    await provider.searchBooks(
      _searchController.text.trim(),
      searchIndex: _selectedSearchButtonIndex,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access the BookProvider from the widget tree
    final BookProvider provider = Provider.of<BookProvider>(context);

    // Show a loading indicator if the provider is currently loading data
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: <Widget>[
        const SizedBox(height: 20), // Spacing from AppBar
        SearchButtonsWidget(
          titles: const <String>['Title', 'ISBN', 'Auth@r'],
          initialSelectedIndex: _selectedSearchButtonIndex, // Pass current selection to widget
          onSelectionChanged: (int index) {
            setState(() {
              _selectedSearchButtonIndex = index;
            });
            // CRITICAL FIX: Trigger a search immediately when the search parameter changes
            _performSearch(provider);
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 25, bottom: 25, left: 16, right: 16),
          child: SearchTextField(
            controller: _searchController,
            onSearch: (String text) async {
              // Trigger a search when text changes (debounced internally)
              await provider.searchBooks(
                text.trim(),
                searchIndex: _selectedSearchButtonIndex,
              );
            },
          ),
        ),
        Expanded(
          child: provider.books.isNotEmpty
              ? BookListView(books: provider.books)
              : const Center(child: Text('No books found')),
        ),
      ],
    );
  }
}

// Search text field with debounce functionality
class SearchTextField extends StatefulWidget {
  final ValueChanged<String> onSearch; // Callback for search action
  final TextEditingController controller;

  const SearchTextField({
    super.key,
    required this.onSearch,
    required this.controller,
  });

  @override
  State<SearchTextField> createState() => _SearchTextFieldState();
}

class _SearchTextFieldState extends State<SearchTextField> {
  Timer? _debounce;

  void _onChanged(String value) {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel(); // Cancel previous timer if active
    }
    // Set a new timer to call onSearch after a delay (debounce)
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onSearch(value.trim());
    });
  }

  @override
  void dispose() {
    _debounce?.cancel(); // Cancel timer when widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          onPressed: () {
            widget.controller.clear(); // Clear text in the controller
            widget.onSearch(''); // Trigger search with empty query to show all results
          },
          icon: const Icon(Icons.clear),
        ),
        labelText: 'Search',
        hintText: 'Search for books...',
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      onChanged: _onChanged,
    );
  }
}

// Widget for selecting search parameters via buttons
class SearchButtonsWidget extends StatefulWidget {
  final List<String> titles; // List of titles for the buttons (e.g., 'Title', 'ISBN')
  final ValueChanged<int> onSelectionChanged; // Callback when a button is selected
  final int initialSelectedIndex; // The index of the initially selected button

  const SearchButtonsWidget({
    super.key,
    required this.titles,
    required this.onSelectionChanged,
    this.initialSelectedIndex = 0,
  });

  @override
  State<SearchButtonsWidget> createState() => _SearchButtonsWidgetState();
}

class _SearchButtonsWidgetState extends State<SearchButtonsWidget> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.titles.length, (int index) {
        final bool isSelected = widget.initialSelectedIndex == index;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: TextButton(
            style: TextButton.styleFrom(
              foregroundColor: isSelected ? Colors.white : Theme.of(context).primaryColor,
              backgroundColor: isSelected ? Theme.of(context).primaryColor : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                side: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: isSelected ? 2 : 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () {
              widget.onSelectionChanged(index); // Notify parent of selection change
            },
            child: Text(widget.titles[index]),
          ),
        );
      }),
    );
  }
}

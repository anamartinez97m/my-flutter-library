import 'package:flutter/material.dart';
import 'package:mylibrary/providers/book_provider.dart';
import 'package:provider/provider.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookProvider?>(context);

    if (provider == null || provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final books = provider.books;
    final totalCount = books.length;
    final latestBookName = provider.latestBookAdded;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.library_books,
                      size: 48,
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Total Books in Library',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$totalCount',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.new_releases,
                      size: 48,
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Latest Book Added',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      latestBookName != null && latestBookName.isNotEmpty
                          ? latestBookName
                          : 'No books in the database',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.w600,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

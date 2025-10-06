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
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'The database contains the following number of books:',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '$totalCount',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'The last book created at the database is:',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        latestBookName != null && latestBookName.isNotEmpty
                            ? latestBookName
                            : 'No hay libros en la base de datos',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

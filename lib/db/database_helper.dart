import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static Database? _database;
  static final DatabaseHelper instance = DatabaseHelper._internal();

  DatabaseHelper._internal();

  factory DatabaseHelper() => instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final pathToDb = join(dbPath, 'my_library.db');

    return await openDatabase(
      pathToDb,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create all tables matching the SQL script
    await db.execute('''
      CREATE TABLE IF NOT EXISTS status (
        status_id INTEGER PRIMARY KEY AUTOINCREMENT,
        value VARCHAR(50) NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS author (
        author_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR(50) NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS editorial (
        editorial_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR(50) NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS genre (
        genre_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR(50) NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS language (
        language_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR(50) NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS place (
        place_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR(50) NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS format (
        format_id INTEGER PRIMARY KEY AUTOINCREMENT,
        value VARCHAR(50) NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS format_saga (
        format_id INTEGER PRIMARY KEY AUTOINCREMENT,
        value VARCHAR(50) NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS book (
        book_id INTEGER PRIMARY KEY AUTOINCREMENT,
        status_id VARCHAR(50) NOT NULL,
        name VARCHAR(50) NOT NULL DEFAULT 'unknown',
        editorial_id VARCHAR(50),
        saga VARCHAR(50),
        n_saga VARCHAR(50),
        format_saga_id VARCHAR(50),
        isbn VARCHAR(50),
        pages INTEGER,
        original_publication_year INTEGER,
        loaned BOOLEAN,
        language_id VARCHAR(50),
        place_id VARCHAR(50),
        format_id VARCHAR(50),
        created_at TEXT DEFAULT (datetime('now')),
        date_read_initial TEXT,
        date_read_final TEXT,
        read_count INTEGER DEFAULT 0,
        my_rating REAL,
        my_review TEXT,
        FOREIGN KEY (status_id) REFERENCES status (status_id),
        FOREIGN KEY (editorial_id) REFERENCES editorial (editorial_id),
        FOREIGN KEY (language_id) REFERENCES language (language_id),
        FOREIGN KEY (place_id) REFERENCES place (place_id),
        FOREIGN KEY (format_id) REFERENCES format (format_id),
        FOREIGN KEY (format_saga_id) REFERENCES format_saga (format_id)
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_book_isbn ON book (isbn)
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS books_by_author (
        books_by_author_id INTEGER PRIMARY KEY,
        author_id INTEGER,
        book_id INTEGER,
        FOREIGN KEY (author_id) REFERENCES author (author_id),
        FOREIGN KEY (book_id) REFERENCES book (book_id),
        UNIQUE (author_id, book_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS books_by_genre (
        books_by_genre_id INTEGER PRIMARY KEY,
        genre_id INTEGER,
        book_id INTEGER,
        FOREIGN KEY (genre_id) REFERENCES genre (genre_id),
        FOREIGN KEY (book_id) REFERENCES book (book_id),
        UNIQUE (genre_id, book_id)
      )
    ''');
  }

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      // Add new columns for version 2
      await db.execute(
        'ALTER TABLE book ADD COLUMN date_read_initial TEXT',
      );
      await db.execute(
        'ALTER TABLE book ADD COLUMN date_read_final TEXT',
      );
      await db.execute(
        'ALTER TABLE book ADD COLUMN read_count INTEGER DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE book ADD COLUMN my_rating REAL',
      );
      await db.execute(
        'ALTER TABLE book ADD COLUMN my_review TEXT',
      );
    }
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}

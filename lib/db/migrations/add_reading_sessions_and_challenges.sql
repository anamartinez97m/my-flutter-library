-- Migration to add reading sessions and year challenges tables

-- Create reading_sessions table for chronometer functionality
CREATE TABLE IF NOT EXISTS reading_sessions (
  session_id INTEGER PRIMARY KEY AUTOINCREMENT,
  book_id INTEGER NOT NULL,
  start_time TEXT NOT NULL,
  end_time TEXT,
  duration_seconds INTEGER,
  is_active INTEGER NOT NULL DEFAULT 1,
  FOREIGN KEY (book_id) REFERENCES book(book_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_reading_sessions_book_id ON reading_sessions(book_id);
CREATE INDEX IF NOT EXISTS idx_reading_sessions_is_active ON reading_sessions(is_active);

-- Create year_challenges table for reading goals
CREATE TABLE IF NOT EXISTS year_challenges (
  challenge_id INTEGER PRIMARY KEY AUTOINCREMENT,
  year INTEGER NOT NULL UNIQUE,
  target_books INTEGER NOT NULL,
  target_pages INTEGER,
  created_at TEXT NOT NULL,
  notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_year_challenges_year ON year_challenges(year);

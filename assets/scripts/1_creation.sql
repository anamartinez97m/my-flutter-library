/* Creacion tabla de valores de leido */
create table if not exists status (
	status_id integer primary KEY autoincrement,
	value varchar(50) not NULL
);

/* Creacion tabla de autores */
create table if not EXISTS author (
	author_id integer primary KEY autoincrement,
	name varchar(50) not NULL
);

/* Creacion tabla de editoriales */
create table if not EXISTS editorial (
	editorial_id integer primary KEY autoincrement,
	name varchar(50) not NULL
);

/* Creacion tabla de generos */
create table if not EXISTS genre (
	genre_id integer primary KEY autoincrement,
	name varchar(50) not NULL
);

/* Creacion tabla de idiomas */
create table if not EXISTS language (
	language_id integer primary KEY autoincrement,
	name varchar(50) not NULL
);

/* Creacion tabla de lugares */
create table if not EXISTS place (
	place_id integer primary KEY autoincrement,
	name varchar(50) not NULL
);

/* Creacion tabla de formatos */
create table if not EXISTS format (
	format_id integer primary KEY autoincrement,
	value varchar(50) not NULL
);

/* Creacion tabla de formatos de saga */
create table if not EXISTS format_saga (
	format_id integer primary KEY autoincrement,
	value varchar(50) not NULL
);

/* Creacion tabla de biblioteca */
create table if not EXISTS book (
	book_id integer primary KEY autoincrement,
	status_id VARCHAR(50) not NULL,
	name VARCHAR(50) not NULL default 'unknown',
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
	foreign key (status_id) references status (status_id),
	foreign key (editorial_id) references editorial (editorial_id),
	foreign key (language_id) references language (language_id),
	foreign key (place_id) references place (place_id),
	foreign key (format_id) references format (format_id),
	foreign key (format_saga_id) references format_saga(format_id)
);

/* Creación de index para busqueda por isbn */
create index idx_book_isbn on book (isbn);


/* Creacion tabla de libros por autor (1..n) */
create table books_by_author (
	books_by_author_id integer primary key,
	author_id integer,
	book_id integer,
	foreign key (author_id) references author (author_id),
	foreign key (book_id) references book (book_id),
	unique (author_id, book_id)
);

/* Creacion tabla de libros por genero (1..n) */
create table books_by_genre (
	books_by_genre_id integer primary key,
	genre_id integer,
	book_id integer,
	foreign key (genre_id) references genre (genre_id),
	foreign key (book_id) references book (book_id),
	unique (genre_id, book_id)
);


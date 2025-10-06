/* Tabla de valores de leido */
insert into status (value) 
select b.read from Biblioteca b where b.read <> '' group by b.read;

/* Tabla de idiomas */
insert into language (name)
select b.language from Biblioteca b where b.language <> '' group by b.language;

/* Tabla de lugares */
insert into place (name)
select b.place from Biblioteca b where b.place <> '' group by b.place;

/* Tabla de formatos */
insert into format (value)
select b.format from Biblioteca b where b.format <> '' group by b.format;

/* Tabla de formatos de saga */
insert into format_saga (value)
select b.format_saga from Biblioteca b where b.format_saga <> '' group by b.format_saga;

/* Tabla de editoriales */
insert into editorial (name)
select b.editorial from Biblioteca b where editorial <> '' group by b.editorial;

/* Tabla de generos sin duplicar y sin comas */
insert into genre (name)
WITH RECURSIVE split(texto, parte, resto) AS (
    SELECT
        b.genre,
        TRIM(substr(b.genre, 1, instr(b.genre|| ',', ',') - 1)) AS parte,
        TRIM(substr(b.genre || ',', instr(b.genre || ',', ',') + 1)) AS resto
    FROM Biblioteca b
    UNION ALL
    SELECT
        texto,
        TRIM(substr(resto, 1, instr(resto, ',') - 1)),
        TRIM(substr(resto, instr(resto, ',') + 1))
    FROM split
    WHERE resto <> ''
)
SELECT DISTINCT parte
FROM split
WHERE parte <> ''
ORDER BY parte;

/* Tabla de autores sin duplicar y sin comas */
insert into author (name)
WITH RECURSIVE split(texto, parte, resto) AS (
    SELECT
        b.autor,
        TRIM(substr(b.autor, 1, instr(b.autor|| ',', ',') - 1)) AS parte,
        TRIM(substr(b.autor || ',', instr(b.autor || ',', ',') + 1)) AS resto
    FROM Biblioteca b
    UNION ALL
    SELECT
        texto,
        TRIM(substr(resto, 1, instr(resto, ',') - 1)),
        TRIM(substr(resto, instr(resto, ',') + 1))
    FROM split
    WHERE resto <> ''
)
SELECT DISTINCT parte
FROM split
WHERE parte <> ''
ORDER BY parte;

/* Tabla de libros */
insert into book (status_id, name, editorial_id, saga, n_saga, format_saga_id, isbn, pages, original_publication_year, loaned, language_id, place_id, format_id)
select s.status_id, b.name, e.editorial_id, b.saga, b.n_saga, fs.format_id, b.isbn, b.pages, b.publication_year, b.loaned, l.language_id, p.place_id, f.format_id 
from Biblioteca b 
left join status s on b.read like s.value
left join editorial e on b.editorial like e.name
left join language l on b.language like l.name
left join place p on b.place like p.name 
left join format f on b.format like f.value
left join format_saga fs on b.format_saga like fs.value;

/* Tabla de libros por genero */
insert into books_by_genre (genre_id, book_id)
WITH RECURSIVE split(nombre, texto, parte, resto) AS (
    SELECT
    	b.name as nombre,
        b.genre,
        TRIM(substr(b.genre, 1, instr(b.genre || ',', ',') - 1)) AS parte,
        TRIM(substr(b.genre || ',', instr(b.genre || ',', ',') + 1)) AS resto
    FROM Biblioteca b
    UNION ALL
    SELECT
    	nombre,
        texto,
        TRIM(substr(resto, 1, instr(resto, ',') - 1)),
        TRIM(substr(resto, instr(resto, ',') + 1))
    FROM split
    WHERE resto <> ''
)
SELECT distinct g.genre_id, b.book_id
FROM split s
left join book b on s.nombre like b.name
left join genre g on s.parte like g.name
order by b.book_id;

/* Tabla de libros por autor */
insert into books_by_author (author_id, book_id)
WITH RECURSIVE split(nombre, texto, parte, resto) AS (
    SELECT
    	b.name as nombre,
        b.autor,
        TRIM(substr(b.autor, 1, instr(b.autor|| ',', ',') - 1)) AS parte,
        TRIM(substr(b.autor || ',', instr(b.autor || ',', ',') + 1)) AS resto
    FROM Biblioteca b
    UNION ALL
    SELECT
    	nombre,
        texto,
        TRIM(substr(resto, 1, instr(resto, ',') - 1)),
        TRIM(substr(resto, instr(resto, ',') + 1))
    FROM split
    WHERE resto <> ''
)
SELECT distinct a.author_id, b.book_id
FROM split s
left join book b on s.nombre like b.name
left join author a on s.parte like a.name
order by b.book_id;


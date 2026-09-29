-- Parsing array
select
    parse_json('["Malcolm X", "Alex Haley"]') as author,
    author[0]::string as first_author,
    author[1]::string as second_author
;

-- Extracting multiple values from array
select
    parse_json('[0, 1, 2, 3, 4, 5]') as num_array,
    array_slice(num_array, 0, 3) as slice
;

-- Parsing JSON object and extracting book title
select
    parse_json(
        '{
        "title": "The Autobiography of Malcolm X",
        "author": ["Malcolm X", "Alex Haley"]
        }'
    ) as json_data,
    json_data:title::string as title
;

-- Extracting title and authors
select
    parse_json(
        '{
        "title": "The Autobiography of Malcolm X",
        "author": ["Malcolm X", "Alex Haley"]
        }'
    ) as json_data,
    json_data:title::string as title,
    json_data:author as author_array,
    author_array[0]::string as first_author,
    author_array[1]::string as second_author
;

-- Creating example table
create table sh_library_books_raw as (
    select parse_json(
        '[
            {
                "title": "The Autobiography of Malcolm X",
                "author": ["Malcolm X", "Alex Haley"],
                "metadata": {"isbn": "978-0345350688", "genre": "Biography", "pages": 528},
                "checkouts": [
                    {"user_id": 101, "date": "2023-01-15", "days_kept": 14},
                    {"user_id": 205, "date": "2023-03-10", "days_kept": 21}
                ]
            },
            {
                "title": "The Overstory",
                "author": ["Richard Powers"],
                "metadata": {"isbn": "978-0393356687", "genre": "Fiction", "pages": 512},
                "checkouts": [
                    {"user_id": 405, "date": "2023-05-12", "days_kept": 30},
                    {"user_id": 99, "date": "2023-07-20", "days_kept": 5}
                ]
            },
            {
                "title": "Norwegian Wood",
                "author": ["Haruki Murakami"],
                "metadata": {"isbn": "978-0375704024", "genre": "Fiction", "pages": 296},
                "checkouts": [
                    {"user_id": 101, "date": "2023-08-15", "days_kept": 10}
                ]
            },
            {
                "title": "David Copperfield",
                "author": ["Charles Dickens"],
                "metadata": {"isbn": "978-0582541603", "genre": "Classic", "pages": 1024},
                "checkouts": []
            },
            {
                "title": "Little Women",
                "author": ["Louisa May Alcott"],
                "metadata": {"isbn": "978-0143135562", "genre": "Classic", "pages": 449},
                "checkouts": [
                    {"user_id": 303, "date": "2023-09-01", "days_kept": 14},
                    {"user_id": 102, "date": "2023-10-05", "days_kept": 12}
                ]
            },
            {
                "title": "A Game of Thrones",
                "author": ["George R. R. Martin"],
                "metadata": {"isbn": "978-0553381689", "genre": "Fantasy", "pages": 694},
                "checkouts": [
                    {"user_id": 501, "date": "2023-11-20", "days_kept": 45}
                ]
            },
            {
                "title": "Harry Potter and the Deathly Hallows",
                "author": ["J.K. Rowling"],
                "metadata": {"isbn": "978-1408855713", "genre": "Fantasy", "pages": 607},
                "checkouts": [
                    {"user_id": 602, "date": "2023-12-01", "days_kept": 20},
                    {"user_id": 101, "date": "2023-12-28", "days_kept": 15}
                ]
            }
        ]'
    ) as json_data
);

-- Table before flattening
-- Everything is contained in a single row
table sh_library_books_raw;

-- Flattening: separates each book into its own row in value column
select *
from sh_library_books_raw,
    lateral flatten(json_data)
;

-- Creating table for parsed data
create or replace table sh_library_books_parsed as
(
    select
        value:author[0]::string as author_1,
        value:author[1]::string as author_2,
        value:title::string as title,
        value:checkouts::array as checkout_history,
        value:metadata:genre::string as genre,
        value:metadata:isbn::string as isbn,
        value:metadata:pages::int as page_count
    from sh_library_books_raw,
        lateral flatten(json_data)
);

table sh_library_books_parsed;

-- Other useful functions
-- 1. array_append - Add entry to a book's checkout history
select
    array_append(
        checkout_history,
        parse_json(
            '{
                "date": "2023-09-10",
                "days_kept": 12,
                "user_id": 222
            }'
    )) as checkout_history_with_append
from sh_library_books_parsed
where title = 'Norwegian Wood'
;

-- 2. array_size - Get number of times each book has been checked out
select
    array_size(checkout_history) as num_checkouts,
    title
from sh_library_books_parsed
;

-- 3. array_contains - Check to see if author contains Malcolm X
select
    parse_json('["Malcolm X", "Alex Haley"]') as author,
    array_contains('Malcolm X'::variant, author) as contains_malcolm_x
;

-- 4. array_agg - Collect all titles the library has into a single array
select
    array_agg(title) as titles
from sh_library_books_parsed
;

-- 5. array_construct - Create array of 2 authors
select
    array_construct('Malcolm X', 'Alex Haley') as author
;

-- 6. object_construct - Create an object for a specific book
select
    object_construct(
        'title', 'Exhalation',
        'author', 'Ted Chiang',
        'genre', 'Science Fiction'
    ) as constructed_object
;

-- 7a. object_insert - Add country to existing book
select
    parse_json(
        '{
            "title": "Norwegian Wood",
            "author": "Haruki Murakami"
        }'
    ) as original_object,
    object_insert(original_object, 'country', 'Japan') as new_object
;

-- 7b. object_insert - Replace title of existing book
select
    parse_json(
        '{
            "title": "Norwegian Wood",
            "author": "Haruki Murakami"
        }'
    ) as original_object,
    object_insert(original_object, 'title', 'Norwegian Wood (trade paperback)', true) as new_object
;

-- 8. {*} - Return an object for each row with column name as key, data as value
select {*}
from sh_library_books_parsed
;
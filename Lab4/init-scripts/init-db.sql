CREATE TABLE IF NOT EXISTS books (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    author VARCHAR(255) DEFAULT 'Unknown'
);

INSERT INTO books (title, author) VALUES
    ('Docker Deep Dive', 'Nigel Poulton'),
    ('The Phoenix Project', 'Gene Kim');

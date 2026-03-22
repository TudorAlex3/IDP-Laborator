const express = require('express');
const { Pool } = require('pg');

const app = express();
app.use(express.json());

// Logging - afiseaza fiecare request in log-uri
app.use((req, res, next) => {
    const start = Date.now();
    res.on('finish', () => {
        const duration = Date.now() - start;
        console.log(`${req.method} ${req.url} - ${res.statusCode} (${duration}ms)`);
    });
    next();
});

const pool = new Pool({
    user: process.env.PGUSER || 'admin',
    password: process.env.PGPASSWORD || 'admin',
    host: process.env.PGHOST || 'postgres',
    database: process.env.PGDATABASE || 'books',
    port: process.env.PGPORT || 5432
});

// GET /api/books - listeaza toate cartile
app.get('/api/books', async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM books ORDER BY id');
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Database error' });
    }
});

// POST /api/books - adauga o carte
app.post('/api/books', async (req, res) => {
    const { title, author } = req.body;
    if (!title) {
        return res.status(400).json({ error: 'Title is required' });
    }
    try {
        const result = await pool.query(
            'INSERT INTO books (title, author) VALUES ($1, $2) RETURNING *',
            [title, author || 'Unknown']
        );
        res.status(201).json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Database error' });
    }
});

// GET /api/health - health check
app.get('/api/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

const PORT = process.env.PORT || 80;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`API server running on port ${PORT}`);
});

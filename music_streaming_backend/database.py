import sqlite3
import os

DB_PATH = "music.db"

def get_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row  # rows behave like dicts
    conn.execute("PRAGMA foreign_keys = ON")
    return conn

def init_db():
    if os.path.exists(DB_PATH):
        print("✓ Database already exists. Skipping setup.")
        return

    print("Setting up database...")
    conn = get_connection()
    c = conn.cursor()

    # ── TABLES ──────────────────────────────────────────
    c.executescript("""
    CREATE TABLE IF NOT EXISTS SUBSCRIPTION (
        subscription_id INTEGER PRIMARY KEY AUTOINCREMENT,
        plan_name       TEXT NOT NULL,
        monthly_price   REAL NOT NULL,
        quality         TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS ARTISTS (
        artist_id   INTEGER PRIMARY KEY AUTOINCREMENT,
        artist_name TEXT NOT NULL,
        country     TEXT NOT NULL,
        debut_year  INTEGER NOT NULL,
        is_verified INTEGER NOT NULL DEFAULT 0
    );

    CREATE TABLE IF NOT EXISTS SONGS (
        song_id      INTEGER PRIMARY KEY AUTOINCREMENT,
        title        TEXT NOT NULL,
        artist_id    INTEGER NOT NULL,
        genre        TEXT NOT NULL,
        release_year INTEGER NOT NULL,
        duration_sec INTEGER NOT NULL,
        language     TEXT NOT NULL DEFAULT 'English',
        FOREIGN KEY (artist_id) REFERENCES ARTISTS(artist_id)
    );

    CREATE TABLE IF NOT EXISTS USERS (
        user_id         INTEGER PRIMARY KEY AUTOINCREMENT,
        name            TEXT NOT NULL,
        email           TEXT UNIQUE,
        country         TEXT NOT NULL,
        age             INTEGER NOT NULL,
        subscription_id INTEGER NOT NULL,
        created_at      TEXT NOT NULL,
        FOREIGN KEY (subscription_id) REFERENCES SUBSCRIPTION(subscription_id)
    );

    CREATE TABLE IF NOT EXISTS STREAMS (
        stream_id    INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id      INTEGER NOT NULL,
        song_id      INTEGER NOT NULL,
        stream_time  TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        device_type  TEXT NOT NULL,
        location     TEXT NOT NULL,
        listened_sec INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES USERS(user_id),
        FOREIGN KEY (song_id) REFERENCES SONGS(song_id)
    );

    CREATE TABLE IF NOT EXISTS subscription_change_log (
        log_id     INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id    INTEGER,
        old_sub_id INTEGER,
        new_sub_id INTEGER,
        changed_at TEXT DEFAULT CURRENT_TIMESTAMP
    );

    CREATE INDEX IF NOT EXISTS idx_streams_user ON STREAMS(user_id);
    CREATE INDEX IF NOT EXISTS idx_streams_song ON STREAMS(song_id);
    CREATE INDEX IF NOT EXISTS idx_streams_time ON STREAMS(stream_time);
    CREATE INDEX IF NOT EXISTS idx_songs_genre  ON SONGS(genre);
    CREATE INDEX IF NOT EXISTS idx_users_country ON USERS(country);
    """)

    # ── SUBSCRIPTIONS ────────────────────────────────────
    c.executemany("INSERT INTO SUBSCRIPTION (plan_name, monthly_price, quality) VALUES (?,?,?)", [
        ('Free',    0.00,  'Normal'),
        ('Premium', 9.99,  'High'),
        ('Family',  15.99, 'Very High'),
    ])

    # ── ARTISTS ─────────────────────────────────────────
    c.executemany("INSERT INTO ARTISTS (artist_name, country, debut_year, is_verified) VALUES (?,?,?,?)", [
        ('The Weeknd',     'Canada',         2010, 1),
        ('Billie Eilish',  'United States',  2015, 1),
        ('BTS',            'South Korea',    2013, 0),
        ('Ed Sheeran',     'United Kingdom', 2004, 1),
        ('Dua Lipa',       'United Kingdom', 2014, 1),
        ('Taylor Swift',   'United States',  2004, 1),
        ('Bad Bunny',      'Puerto Rico',    2016, 0),
        ('Ariana Grande',  'United States',  2008, 0),
        ('Drake',          'Canada',         2006, 1),
        ('Olivia Rodrigo', 'United States',  2020, 0),
    ])

    # ── SONGS ────────────────────────────────────────────
    c.executemany("INSERT INTO SONGS (title, artist_id, genre, release_year, duration_sec, language) VALUES (?,?,?,?,?,?)", [
        ('Blinding Lights',   1, 'Pop',         2019, 200, 'English'),
        ('Save Your Tears',   1, 'Pop',         2020, 215, 'English'),
        ('Starboy',           1, 'R&B',         2016, 230, 'English'),
        ('bad guy',           2, 'Pop',         2019, 194, 'English'),
        ('Happier Than Ever', 2, 'Alternative', 2021, 298, 'English'),
        ('Ocean Eyes',        2, 'Indie Pop',   2016, 201, 'English'),
        ('Dynamite',          3, 'K-Pop',       2020, 203, 'Korean'),
        ('Butter',            3, 'K-Pop',       2021, 164, 'Korean'),
        ('Shape of You',      4, 'Pop',         2017, 234, 'English'),
        ('Perfect',           4, 'Pop',         2017, 263, 'English'),
        ('Levitating',        5, 'Pop',         2020, 203, 'English'),
        ('Physical',          5, 'Dance',       2020, 194, 'English'),
        ('Anti-Hero',         6, 'Pop',         2022, 200, 'English'),
        ('Shake It Off',      6, 'Pop',         2014, 219, 'English'),
        ('Me Porto Bonito',   7, 'Reggaeton',   2022, 185, 'Spanish'),
        ('Titi Me Pregunto',  7, 'Reggaeton',   2022, 267, 'Spanish'),
        ('7 rings',           8, 'Pop',         2019, 178, 'English'),
        ('positions',         8, 'R&B',         2020, 172, 'English'),
        ('Gods Plan',         9, 'Hip-Hop',     2018, 198, 'English'),
        ('Hotline Bling',     9, 'R&B',         2015, 267, 'English'),
        ('drivers license',  10, 'Pop',         2021, 242, 'English'),
        ('good 4 u',         10, 'Pop',         2021, 178, 'English'),
        ('deja vu',          10, 'Pop',         2021, 215, 'English'),
    ])

    # ── USERS ────────────────────────────────────────────
    c.executemany("INSERT INTO USERS (name, country, age, subscription_id, created_at) VALUES (?,?,?,?,?)", [
        ('Aditya Sharma',  'India',          22, 2, '2022-01-15'),
        ('Sofia Martinez', 'Spain',          28, 3, '2021-06-20'),
        ('Liam Johnson',   'United States',  19, 1, '2023-03-10'),
        ('Priya Nair',     'India',          25, 2, '2022-08-05'),
        ('James Wilson',   'United Kingdom', 33, 3, '2020-11-30'),
        ('Yuna Kim',       'South Korea',    21, 2, '2023-01-22'),
        ('Carlos Gomez',   'Mexico',         30, 1, '2021-09-18'),
        ('Emily Chen',     'Canada',         26, 2, '2022-04-14'),
        ('Mohamed Ali',    'Egypt',          24, 1, '2023-05-07'),
        ('Anna Muller',    'Germany',        35, 3, '2020-07-25'),
        ('Raj Patel',      'India',          27, 2, '2022-12-01'),
        ('Sakura Tanaka',  'Japan',          20, 1, '2023-02-19'),
        ('Lucas Silva',    'Brazil',         23, 2, '2022-03-30'),
        ('Fatima Hassan',  'UAE',            31, 3, '2021-10-10'),
        ('Noah Brown',     'Australia',      18, 1, '2023-06-15'),
    ])

    # ── STREAMS ──────────────────────────────────────────
    streams = [
        (1,  1,  '2024-01-05 08:15:00', 'Mobile',        'Mumbai, India',       200),
        (1,  9,  '2024-01-05 09:00:00', 'Mobile',        'Mumbai, India',       234),
        (1,  13, '2024-01-06 18:30:00', 'Desktop',       'Mumbai, India',       195),
        (2,  11, '2024-01-06 10:00:00', 'Desktop',       'Madrid, Spain',       203),
        (2,  13, '2024-01-07 20:15:00', 'Smart Speaker', 'Madrid, Spain',       200),
        (2,  5,  '2024-01-08 15:45:00', 'Mobile',        'Madrid, Spain',       290),
        (3,  19, '2024-01-06 14:30:00', 'Mobile',        'New York, US',        198),
        (3,  4,  '2024-01-07 11:00:00', 'Desktop',       'New York, US',        180),
        (3,  1,  '2024-01-08 09:30:00', 'Tablet',        'New York, US',        200),
        (4,  7,  '2024-01-09 07:45:00', 'Mobile',        'Bangalore, India',    203),
        (4,  8,  '2024-01-09 08:20:00', 'Mobile',        'Bangalore, India',    164),
        (4,  1,  '2024-01-10 21:00:00', 'Smart Speaker', 'Bangalore, India',    200),
        (5,  14, '2024-01-10 16:00:00', 'Desktop',       'London, UK',          219),
        (5,  10, '2024-01-11 12:30:00', 'Smart Speaker', 'London, UK',          263),
        (5,  9,  '2024-01-11 19:00:00', 'Tablet',        'London, UK',          230),
        (6,  7,  '2024-01-12 08:00:00', 'Mobile',        'Seoul, South Korea',  203),
        (6,  8,  '2024-01-12 08:30:00', 'Mobile',        'Seoul, South Korea',  164),
        (6,  15, '2024-01-13 22:00:00', 'Desktop',       'Seoul, South Korea',  185),
        (7,  16, '2024-01-13 11:00:00', 'Mobile',        'Mexico City, Mexico', 267),
        (7,  15, '2024-01-14 17:30:00', 'Smart Speaker', 'Mexico City, Mexico', 185),
        (8,  20, '2024-01-14 13:00:00', 'Desktop',       'Toronto, Canada',     267),
        (8,  19, '2024-01-15 10:30:00', 'Mobile',        'Toronto, Canada',     198),
        (8,  17, '2024-01-15 15:00:00', 'Tablet',        'Toronto, Canada',     178),
        (9,  4,  '2024-01-16 07:30:00', 'Mobile',        'Cairo, Egypt',        190),
        (9,  6,  '2024-01-16 08:00:00', 'Mobile',        'Cairo, Egypt',        201),
        (10, 5,  '2024-01-16 20:00:00', 'Smart Speaker', 'Berlin, Germany',     298),
        (10, 3,  '2024-01-17 21:30:00', 'Desktop',       'Berlin, Germany',     230),
        (11, 21, '2024-01-17 09:00:00', 'Mobile',        'Delhi, India',        242),
        (11, 22, '2024-01-17 09:45:00', 'Mobile',        'Delhi, India',        178),
        (11, 23, '2024-01-18 10:00:00', 'Mobile',        'Delhi, India',        215),
        (12, 7,  '2024-01-18 07:00:00', 'Mobile',        'Tokyo, Japan',        203),
        (12, 8,  '2024-01-18 07:35:00', 'Mobile',        'Tokyo, Japan',        164),
        (13, 16, '2024-01-19 14:00:00', 'Desktop',       'Sao Paulo, Brazil',   260),
        (13, 18, '2024-01-19 15:00:00', 'Mobile',        'Sao Paulo, Brazil',   170),
        (14, 11, '2024-01-20 11:00:00', 'Desktop',       'Dubai, UAE',          200),
        (14, 12, '2024-01-20 11:45:00', 'Tablet',        'Dubai, UAE',          194),
        (15, 1,  '2024-01-20 16:00:00', 'Mobile',        'Sydney, Australia',   200),
        (15, 13, '2024-01-21 08:00:00', 'Smart Speaker', 'Sydney, Australia',   198),
        (1,  7,  '2024-01-21 08:30:00', 'Mobile',        'Mumbai, India',       200),
        (2,  9,  '2024-01-21 19:00:00', 'Smart Speaker', 'Madrid, Spain',       234),
        (3,  13, '2024-01-22 12:00:00', 'Desktop',       'New York, US',        200),
        (4,  11, '2024-01-22 07:30:00', 'Mobile',        'Bangalore, India',    203),
        (5,  1,  '2024-01-22 22:00:00', 'Smart Speaker', 'London, UK',          200),
        (6,  19, '2024-01-23 09:00:00', 'Mobile',        'Seoul, South Korea',  195),
        (7,  13, '2024-01-23 18:00:00', 'Desktop',       'Mexico City, Mexico', 200),
        (8,  1,  '2024-01-24 10:00:00', 'Tablet',        'Toronto, Canada',     200),
        (9,  21, '2024-01-24 21:00:00', 'Mobile',        'Cairo, Egypt',        240),
        (10, 9,  '2024-01-25 14:00:00', 'Smart Speaker', 'Berlin, Germany',     234),
        (11, 4,  '2024-01-25 08:00:00', 'Mobile',        'Delhi, India',        190),
        (12, 13, '2024-01-25 20:00:00', 'Desktop',       'Tokyo, Japan',        199),
        (1,  4,  '2024-01-26 10:00:00', 'Mobile',        'Mumbai, India',       190),
    ]
    c.executemany(
        "INSERT INTO STREAMS (user_id, song_id, stream_time, device_type, location, listened_sec) VALUES (?,?,?,?,?,?)",
        streams
    )

    conn.commit()
    conn.close()
    print("✓ Database created with all tables and sample data.")

if __name__ == "__main__":
    init_db()

-- ============================================================
--   MUSIC STREAMING ANALYTICS SYSTEM
--   Spotify-Style Platform | DBMS Project | UCS310
--   Full SQL + PL/SQL Implementation (MySQL Compatible)
-- ============================================================

-- ─────────────────────────────────────────
-- SECTION 1: DATABASE SETUP (DDL)
-- ─────────────────────────────────────────

DROP DATABASE IF EXISTS music_streaming;
CREATE DATABASE music_streaming
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE music_streaming;

-- ─────────────────────────────────────────
-- TABLE 1: SUBSCRIPTION
-- ─────────────────────────────────────────
CREATE TABLE SUBSCRIPTION (
    subscription_id   INT           PRIMARY KEY AUTO_INCREMENT,
    plan_name         VARCHAR(50)   NOT NULL CHECK (plan_name IN ('Free','Premium','Family')),
    monthly_price     DECIMAL(8,2)  NOT NULL CHECK (monthly_price >= 0),
    quality           VARCHAR(20)   NOT NULL
);

-- ─────────────────────────────────────────
-- TABLE 2: USERS
-- ─────────────────────────────────────────
CREATE TABLE USERS (
    user_id           INT           PRIMARY KEY AUTO_INCREMENT,
    name              VARCHAR(100)  NOT NULL,
    country           VARCHAR(50)   NOT NULL,
    age               INT           NOT NULL CHECK (age >= 13 AND age <= 120),
    subscription_id   INT           NOT NULL,
    created_at        DATE          NOT NULL DEFAULT (CURDATE()),
    CONSTRAINT fk_user_subscription
        FOREIGN KEY (subscription_id) REFERENCES SUBSCRIPTION(subscription_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

-- ─────────────────────────────────────────
-- TABLE 3: ARTISTS
-- ─────────────────────────────────────────
CREATE TABLE ARTISTS (
    artist_id         INT           PRIMARY KEY AUTO_INCREMENT,
    artist_name       VARCHAR(100)  NOT NULL,
    country           VARCHAR(50)   NOT NULL,
    debut_year        INT           NOT NULL CHECK (debut_year >= 1900 AND debut_year <= YEAR(CURDATE()))
);

-- ─────────────────────────────────────────
-- TABLE 4: SONGS
-- ─────────────────────────────────────────
CREATE TABLE SONGS (
    song_id           INT           PRIMARY KEY AUTO_INCREMENT,
    title             VARCHAR(200)  NOT NULL,
    artist_id         INT           NOT NULL,
    genre             VARCHAR(50)   NOT NULL,
    release_year      INT           NOT NULL CHECK (release_year >= 1900),
    duration_sec      INT           NOT NULL CHECK (duration_sec > 0),
    CONSTRAINT fk_song_artist
        FOREIGN KEY (artist_id) REFERENCES ARTISTS(artist_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

-- ─────────────────────────────────────────
-- TABLE 5: STREAMS  (Fact Table)
-- ─────────────────────────────────────────
CREATE TABLE STREAMS (
    stream_id         INT           PRIMARY KEY AUTO_INCREMENT,
    user_id           INT           NOT NULL,
    song_id           INT           NOT NULL,
    stream_time       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    device_type       VARCHAR(50)   NOT NULL CHECK (device_type IN ('Mobile','Desktop','Smart Speaker','Tablet')),
    location          VARCHAR(100)  NOT NULL,
    listened_sec      INT           NOT NULL CHECK (listened_sec >= 0),
    CONSTRAINT fk_stream_user
        FOREIGN KEY (user_id) REFERENCES USERS(user_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_stream_song
        FOREIGN KEY (song_id) REFERENCES SONGS(song_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- ─────────────────────────────────────────
-- SECTION 2: INDEXES FOR PERFORMANCE
-- ─────────────────────────────────────────

CREATE INDEX idx_streams_user    ON STREAMS(user_id);
CREATE INDEX idx_streams_song    ON STREAMS(song_id);
CREATE INDEX idx_streams_time    ON STREAMS(stream_time);
CREATE INDEX idx_songs_artist    ON SONGS(artist_id);
CREATE INDEX idx_songs_genre     ON SONGS(genre);
CREATE INDEX idx_users_country   ON USERS(country);

-- ─────────────────────────────────────────
-- SECTION 3: SAMPLE DATA (DML – INSERT)
-- ─────────────────────────────────────────

-- Subscription Plans
INSERT INTO SUBSCRIPTION (plan_name, monthly_price, quality) VALUES
    ('Free',    0.00,  'Normal'),
    ('Premium', 9.99,  'High'),
    ('Family',  15.99, 'Very High');

-- Artists
INSERT INTO ARTISTS (artist_name, country, debut_year) VALUES
    ('The Weeknd',        'Canada',          2010),
    ('Billie Eilish',     'United States',   2015),
    ('BTS',               'South Korea',     2013),
    ('Ed Sheeran',        'United Kingdom',  2004),
    ('Dua Lipa',          'United Kingdom',  2014),
    ('Taylor Swift',      'United States',   2004),
    ('Bad Bunny',         'Puerto Rico',     2016),
    ('Ariana Grande',     'United States',   2008),
    ('Drake',             'Canada',          2006),
    ('Olivia Rodrigo',    'United States',   2020);

-- Songs (10+ per genre mix)
INSERT INTO SONGS (title, artist_id, genre, release_year, duration_sec) VALUES
    ('Blinding Lights',        1, 'Pop',      2019,  200),
    ('Save Your Tears',        1, 'Pop',      2020,  215),
    ('Starboy',                1, 'R&B',      2016,  230),
    ('bad guy',                2, 'Pop',      2019,  194),
    ('Happier Than Ever',      2, 'Alternative', 2021, 298),
    ('Ocean Eyes',             2, 'Indie Pop', 2016,  201),
    ('Dynamite',               3, 'K-Pop',    2020,  203),
    ('Butter',                 3, 'K-Pop',    2021,  164),
    ('Shape of You',           4, 'Pop',      2017,  234),
    ('Perfect',                4, 'Pop',      2017,  263),
    ('Levitating',             5, 'Pop',      2020,  203),
    ('Physical',               5, 'Dance',    2020,  194),
    ('Anti-Hero',              6, 'Pop',      2022,  200),
    ('Shake It Off',           6, 'Pop',      2014,  219),
    ('Me Porto Bonito',        7, 'Reggaeton', 2022, 185),
    ('Tití Me Preguntó',       7, 'Reggaeton', 2022, 267),
    ('7 rings',                8, 'Pop',      2019,  178),
    ('positions',              8, 'R&B',      2020,  172),
    ('God\'s Plan',            9, 'Hip-Hop',  2018,  198),
    ('Hotline Bling',          9, 'R&B',      2015,  267),
    ('drivers license',       10, 'Pop',      2021,  242),
    ('good 4 u',              10, 'Pop',      2021,  178),
    ('deja vu',               10, 'Pop',      2021,  215);

-- Users (15 diverse users)
INSERT INTO USERS (name, country, age, subscription_id, created_at) VALUES
    ('Aditya Sharma',   'India',          22, 2, '2022-01-15'),
    ('Sofia Martinez',  'Spain',          28, 3, '2021-06-20'),
    ('Liam Johnson',    'United States',  19, 1, '2023-03-10'),
    ('Priya Nair',      'India',          25, 2, '2022-08-05'),
    ('James Wilson',    'United Kingdom', 33, 3, '2020-11-30'),
    ('Yuna Kim',        'South Korea',    21, 2, '2023-01-22'),
    ('Carlos Gomez',    'Mexico',         30, 1, '2021-09-18'),
    ('Emily Chen',      'Canada',         26, 2, '2022-04-14'),
    ('Mohamed Ali',     'Egypt',          24, 1, '2023-05-07'),
    ('Anna Müller',     'Germany',        35, 3, '2020-07-25'),
    ('Raj Patel',       'India',          27, 2, '2022-12-01'),
    ('Sakura Tanaka',   'Japan',          20, 1, '2023-02-19'),
    ('Lucas Silva',     'Brazil',         23, 2, '2022-03-30'),
    ('Fatima Hassan',   'UAE',            31, 3, '2021-10-10'),
    ('Noah Brown',      'Australia',      18, 1, '2023-06-15');

-- Streams (50 streaming events across different times/devices)
INSERT INTO STREAMS (user_id, song_id, stream_time, device_type, location, listened_sec) VALUES
    (1,  1,  '2024-01-05 08:15:00', 'Mobile',        'Mumbai, India',      200),
    (1,  9,  '2024-01-05 09:00:00', 'Mobile',        'Mumbai, India',      234),
    (1,  13, '2024-01-06 18:30:00', 'Desktop',       'Mumbai, India',      195),
    (2,  11, '2024-01-06 10:00:00', 'Desktop',       'Madrid, Spain',      203),
    (2,  13, '2024-01-07 20:15:00', 'Smart Speaker', 'Madrid, Spain',      200),
    (2,  5,  '2024-01-08 15:45:00', 'Mobile',        'Madrid, Spain',      290),
    (3,  19, '2024-01-06 14:30:00', 'Mobile',        'New York, US',       198),
    (3,  4,  '2024-01-07 11:00:00', 'Desktop',       'New York, US',       180),
    (3,  1,  '2024-01-08 09:30:00', 'Tablet',        'New York, US',       200),
    (4,  7,  '2024-01-09 07:45:00', 'Mobile',        'Bangalore, India',   203),
    (4,  8,  '2024-01-09 08:20:00', 'Mobile',        'Bangalore, India',   164),
    (4,  1,  '2024-01-10 21:00:00', 'Smart Speaker', 'Bangalore, India',   200),
    (5,  14, '2024-01-10 16:00:00', 'Desktop',       'London, UK',         219),
    (5,  10, '2024-01-11 12:30:00', 'Smart Speaker', 'London, UK',         263),
    (5,  9,  '2024-01-11 19:00:00', 'Tablet',        'London, UK',         230),
    (6,  7,  '2024-01-12 08:00:00', 'Mobile',        'Seoul, South Korea', 203),
    (6,  8,  '2024-01-12 08:30:00', 'Mobile',        'Seoul, South Korea', 164),
    (6,  15, '2024-01-13 22:00:00', 'Desktop',       'Seoul, South Korea', 185),
    (7,  16, '2024-01-13 11:00:00', 'Mobile',        'Mexico City, Mexico',267),
    (7,  15, '2024-01-14 17:30:00', 'Smart Speaker', 'Mexico City, Mexico',185),
    (8,  20, '2024-01-14 13:00:00', 'Desktop',       'Toronto, Canada',    267),
    (8,  19, '2024-01-15 10:30:00', 'Mobile',        'Toronto, Canada',    198),
    (8,  17, '2024-01-15 15:00:00', 'Tablet',        'Toronto, Canada',    178),
    (9,  4,  '2024-01-16 07:30:00', 'Mobile',        'Cairo, Egypt',       190),
    (9,  6,  '2024-01-16 08:00:00', 'Mobile',        'Cairo, Egypt',       201),
    (10, 5,  '2024-01-16 20:00:00', 'Smart Speaker', 'Berlin, Germany',    298),
    (10, 3,  '2024-01-17 21:30:00', 'Desktop',       'Berlin, Germany',    230),
    (11, 21, '2024-01-17 09:00:00', 'Mobile',        'Delhi, India',       242),
    (11, 22, '2024-01-17 09:45:00', 'Mobile',        'Delhi, India',       178),
    (11, 23, '2024-01-18 10:00:00', 'Mobile',        'Delhi, India',       215),
    (12, 7,  '2024-01-18 07:00:00', 'Mobile',        'Tokyo, Japan',       203),
    (12, 8,  '2024-01-18 07:35:00', 'Mobile',        'Tokyo, Japan',       164),
    (13, 16, '2024-01-19 14:00:00', 'Desktop',       'São Paulo, Brazil',  260),
    (13, 18, '2024-01-19 15:00:00', 'Mobile',        'São Paulo, Brazil',  170),
    (14, 11, '2024-01-20 11:00:00', 'Desktop',       'Dubai, UAE',         200),
    (14, 12, '2024-01-20 11:45:00', 'Tablet',        'Dubai, UAE',         194),
    (15, 1,  '2024-01-20 16:00:00', 'Mobile',        'Sydney, Australia',  200),
    (15, 13, '2024-01-21 08:00:00', 'Smart Speaker', 'Sydney, Australia',  198),
    (1,  7,  '2024-01-21 08:30:00', 'Mobile',        'Mumbai, India',      200),
    (2,  9,  '2024-01-21 19:00:00', 'Smart Speaker', 'Madrid, Spain',      234),
    (3,  13, '2024-01-22 12:00:00', 'Desktop',       'New York, US',       200),
    (4,  11, '2024-01-22 07:30:00', 'Mobile',        'Bangalore, India',   203),
    (5,  1,  '2024-01-22 22:00:00', 'Smart Speaker', 'London, UK',         200),
    (6,  19, '2024-01-23 09:00:00', 'Mobile',        'Seoul, South Korea', 195),
    (7,  13, '2024-01-23 18:00:00', 'Desktop',       'Mexico City, Mexico',200),
    (8,  1,  '2024-01-24 10:00:00', 'Tablet',        'Toronto, Canada',    200),
    (9,  21, '2024-01-24 21:00:00', 'Mobile',        'Cairo, Egypt',       240),
    (10, 9,  '2024-01-25 14:00:00', 'Smart Speaker', 'Berlin, Germany',    234),
    (11, 4,  '2024-01-25 08:00:00', 'Mobile',        'Delhi, India',       190),
    (12, 13, '2024-01-25 20:00:00', 'Desktop',       'Tokyo, Japan',       199);

-- ─────────────────────────────────────────
-- SECTION 4: ALTER TABLE EXAMPLES
-- ─────────────────────────────────────────

-- Add an email column to USERS
ALTER TABLE USERS ADD COLUMN email VARCHAR(150) UNIQUE AFTER name;

-- Add a verified flag to ARTISTS
ALTER TABLE ARTISTS ADD COLUMN is_verified BOOLEAN NOT NULL DEFAULT FALSE;
UPDATE ARTISTS SET is_verified = TRUE WHERE artist_id IN (1,2,4,5,6,9);

-- Add language metadata to SONGS
ALTER TABLE SONGS ADD COLUMN language VARCHAR(30) NOT NULL DEFAULT 'English';
UPDATE SONGS SET language = 'Korean'    WHERE artist_id = 3;
UPDATE SONGS SET language = 'Spanish'   WHERE artist_id = 7;

-- ─────────────────────────────────────────
-- SECTION 5: VIEWS
-- ─────────────────────────────────────────

-- View 1: Popular Songs (top streamed)
CREATE OR REPLACE VIEW popular_songs AS
    SELECT
        s.song_id,
        s.title,
        a.artist_name,
        s.genre,
        COUNT(st.stream_id)          AS total_streams,
        SUM(st.listened_sec)         AS total_listened_sec,
        ROUND(AVG(st.listened_sec))  AS avg_listened_sec
    FROM SONGS s
    JOIN ARTISTS a  ON s.artist_id  = a.artist_id
    JOIN STREAMS st ON s.song_id    = st.song_id
    GROUP BY s.song_id, s.title, a.artist_name, s.genre
    ORDER BY total_streams DESC;

-- View 2: User Listening History (full join)
CREATE OR REPLACE VIEW user_listening_history AS
    SELECT
        u.user_id,
        u.name                              AS user_name,
        u.country,
        sub.plan_name                       AS subscription,
        sg.title                            AS song_title,
        ar.artist_name,
        sg.genre,
        st.stream_time,
        st.device_type,
        st.location,
        ROUND(st.listened_sec / 60.0, 2)   AS listened_min
    FROM STREAMS st
    JOIN USERS        u   ON st.user_id  = u.user_id
    JOIN SUBSCRIPTION sub ON u.subscription_id = sub.subscription_id
    JOIN SONGS        sg  ON st.song_id  = sg.song_id
    JOIN ARTISTS      ar  ON sg.artist_id= ar.artist_id;

-- View 3: Revenue Dashboard
CREATE OR REPLACE VIEW revenue_dashboard AS
    SELECT
        sub.plan_name,
        sub.monthly_price,
        COUNT(u.user_id)                              AS subscribers,
        ROUND(COUNT(u.user_id) * sub.monthly_price, 2) AS monthly_revenue
    FROM SUBSCRIPTION sub
    JOIN USERS u ON sub.subscription_id = u.subscription_id
    GROUP BY sub.plan_name, sub.monthly_price
    ORDER BY monthly_revenue DESC;

-- View 4: Artist Performance
CREATE OR REPLACE VIEW artist_performance AS
    SELECT
        ar.artist_id,
        ar.artist_name,
        ar.country,
        COUNT(DISTINCT st.stream_id)   AS total_streams,
        COUNT(DISTINCT st.user_id)     AS unique_listeners,
        COUNT(DISTINCT sg.song_id)     AS songs_in_catalog,
        ROUND(SUM(st.listened_sec)/3600.0, 2) AS total_hours_listened
    FROM ARTISTS ar
    JOIN SONGS   sg ON ar.artist_id = sg.artist_id
    JOIN STREAMS st ON sg.song_id   = st.song_id
    GROUP BY ar.artist_id, ar.artist_name, ar.country
    ORDER BY total_streams DESC;

-- ─────────────────────────────────────────
-- SECTION 6: ANALYTICAL SQL QUERIES
-- ─────────────────────────────────────────

-- Q1: Top 5 Most Streamed Songs
SELECT song_id, title, artist_name, total_streams
FROM popular_songs
LIMIT 5;

-- Q2: Most Popular Genres (stream count)
SELECT
    sg.genre,
    COUNT(st.stream_id)        AS stream_count,
    COUNT(DISTINCT st.user_id) AS unique_listeners
FROM STREAMS st
JOIN SONGS sg ON st.song_id = sg.song_id
GROUP BY sg.genre
ORDER BY stream_count DESC;

-- Q3: Users Who Stream More Than Average (Subquery)
SELECT
    u.user_id,
    u.name,
    u.country,
    COUNT(st.stream_id) AS user_streams
FROM USERS u
JOIN STREAMS st ON u.user_id = st.user_id
GROUP BY u.user_id, u.name, u.country
HAVING COUNT(st.stream_id) > (
    SELECT AVG(stream_count)
    FROM (
        SELECT COUNT(stream_id) AS stream_count
        FROM STREAMS
        GROUP BY user_id
    ) subq
)
ORDER BY user_streams DESC;

-- Q4: Revenue by Subscription Plan
SELECT * FROM revenue_dashboard;

-- Q5: Listening Activity by Device Type
SELECT
    device_type,
    COUNT(stream_id)                       AS streams,
    ROUND(SUM(listened_sec)/3600.0, 2)    AS total_hours,
    ROUND(AVG(listened_sec), 0)            AS avg_sec_per_stream
FROM STREAMS
GROUP BY device_type
ORDER BY streams DESC;

-- Q6: Peak Listening Hours
SELECT
    HOUR(stream_time)    AS hour_of_day,
    COUNT(stream_id)     AS stream_count
FROM STREAMS
GROUP BY HOUR(stream_time)
ORDER BY stream_count DESC;

-- Q7: Top Countries by Listening Hours
SELECT
    location,
    COUNT(stream_id)                    AS streams,
    ROUND(SUM(listened_sec)/3600.0, 2) AS hours_listened
FROM STREAMS
GROUP BY location
ORDER BY hours_listened DESC
LIMIT 10;

-- Q8: Songs Released in Last 5 Years with 3+ Streams (HAVING)
SELECT
    sg.song_id,
    sg.title,
    ar.artist_name,
    sg.release_year,
    COUNT(st.stream_id) AS stream_count
FROM SONGS sg
JOIN ARTISTS ar ON sg.artist_id = ar.artist_id
JOIN STREAMS st ON sg.song_id   = st.song_id
WHERE sg.release_year >= YEAR(CURDATE()) - 5
GROUP BY sg.song_id, sg.title, ar.artist_name, sg.release_year
HAVING COUNT(st.stream_id) >= 3
ORDER BY stream_count DESC;

-- Q9: User Completion Rate (listened vs song duration)
SELECT
    u.name,
    sg.title,
    sg.duration_sec,
    st.listened_sec,
    ROUND(st.listened_sec * 100.0 / sg.duration_sec, 1) AS completion_pct
FROM STREAMS st
JOIN USERS u  ON st.user_id = u.user_id
JOIN SONGS sg ON st.song_id = sg.song_id
ORDER BY completion_pct DESC;

-- Q10: Artist with Most Unique Listeners (Correlated Subquery)
SELECT
    ar.artist_name,
    (SELECT COUNT(DISTINCT st.user_id)
     FROM STREAMS st
     JOIN SONGS sg ON st.song_id = sg.song_id
     WHERE sg.artist_id = ar.artist_id) AS unique_listeners
FROM ARTISTS ar
ORDER BY unique_listeners DESC
LIMIT 5;

-- Q11: Monthly Streaming Trend
SELECT
    YEAR(stream_time)  AS yr,
    MONTH(stream_time) AS mo,
    COUNT(stream_id)   AS streams,
    ROUND(SUM(listened_sec)/3600.0, 2) AS hours
FROM STREAMS
GROUP BY YEAR(stream_time), MONTH(stream_time)
ORDER BY yr, mo;

-- Q12: Users on Free Plan Who Stream More Than Premium Avg
SELECT u.name, u.country, COUNT(st.stream_id) AS streams
FROM USERS u
JOIN SUBSCRIPTION sub ON u.subscription_id = sub.subscription_id
JOIN STREAMS st       ON u.user_id = st.user_id
WHERE sub.plan_name = 'Free'
GROUP BY u.user_id, u.name, u.country
HAVING COUNT(st.stream_id) > (
    SELECT AVG(c)
    FROM (
        SELECT COUNT(st2.stream_id) AS c
        FROM USERS u2
        JOIN SUBSCRIPTION sub2 ON u2.subscription_id = sub2.subscription_id
        JOIN STREAMS st2       ON u2.user_id = st2.user_id
        WHERE sub2.plan_name = 'Premium'
        GROUP BY u2.user_id
    ) avg_sub
);

-- ─────────────────────────────────────────
-- SECTION 7: PL/SQL (STORED PROCEDURES)
-- ─────────────────────────────────────────

DELIMITER $$

-- Procedure 1: Log a new stream event with validation
CREATE PROCEDURE add_stream(
    IN  p_user_id     INT,
    IN  p_song_id     INT,
    IN  p_device      VARCHAR(50),
    IN  p_location    VARCHAR(100),
    IN  p_listened    INT,
    OUT p_result      VARCHAR(100)
)
BEGIN
    DECLARE v_user_count INT DEFAULT 0;
    DECLARE v_song_count INT DEFAULT 0;
    DECLARE v_duration   INT DEFAULT 0;

    -- Validate user exists
    SELECT COUNT(*) INTO v_user_count FROM USERS WHERE user_id = p_user_id;
    -- Validate song exists and get duration
    SELECT COUNT(*), IFNULL(MAX(duration_sec),0)
    INTO v_song_count, v_duration
    FROM SONGS WHERE song_id = p_song_id;

    IF v_user_count = 0 THEN
        SET p_result = 'ERROR: User not found.';
    ELSEIF v_song_count = 0 THEN
        SET p_result = 'ERROR: Song not found.';
    ELSEIF p_listened < 0 THEN
        SET p_result = 'ERROR: Listened seconds cannot be negative.';
    ELSEIF p_listened > v_duration + 10 THEN
        SET p_result = 'ERROR: Listened seconds exceed song duration.';
    ELSE
        INSERT INTO STREAMS (user_id, song_id, stream_time, device_type, location, listened_sec)
        VALUES (p_user_id, p_song_id, NOW(), p_device, p_location, p_listened);
        SET p_result = CONCAT('SUCCESS: Stream #', LAST_INSERT_ID(), ' logged.');
    END IF;
END$$

-- Procedure 2: Update user subscription
CREATE PROCEDURE update_subscription(
    IN  p_user_id     INT,
    IN  p_new_plan    VARCHAR(50),
    OUT p_result      VARCHAR(150)
)
BEGIN
    DECLARE v_sub_id   INT DEFAULT 0;
    DECLARE v_old_plan VARCHAR(50);

    SELECT sub.plan_name INTO v_old_plan
    FROM USERS u
    JOIN SUBSCRIPTION sub ON u.subscription_id = sub.subscription_id
    WHERE u.user_id = p_user_id;

    IF v_old_plan IS NULL THEN
        SET p_result = 'ERROR: User not found.';
    ELSE
        SELECT subscription_id INTO v_sub_id
        FROM SUBSCRIPTION WHERE plan_name = p_new_plan LIMIT 1;

        IF v_sub_id = 0 THEN
            SET p_result = 'ERROR: Invalid plan name.';
        ELSE
            UPDATE USERS SET subscription_id = v_sub_id WHERE user_id = p_user_id;
            SET p_result = CONCAT('SUCCESS: Changed from ', v_old_plan, ' to ', p_new_plan);
        END IF;
    END IF;
END$$

-- Procedure 3: Monthly Report Generator
CREATE PROCEDURE generate_monthly_report(IN p_year INT, IN p_month INT)
BEGIN
    SELECT 'TOP 5 SONGS' AS report_section,
           sg.title, ar.artist_name, COUNT(st.stream_id) AS streams
    FROM STREAMS st
    JOIN SONGS sg   ON st.song_id   = sg.song_id
    JOIN ARTISTS ar ON sg.artist_id = ar.artist_id
    WHERE YEAR(st.stream_time) = p_year AND MONTH(st.stream_time) = p_month
    GROUP BY sg.song_id, sg.title, ar.artist_name
    ORDER BY streams DESC LIMIT 5;

    SELECT 'DEVICE BREAKDOWN' AS report_section,
           device_type, COUNT(*) AS streams,
           ROUND(SUM(listened_sec)/3600.0,2) AS hours
    FROM STREAMS
    WHERE YEAR(stream_time) = p_year AND MONTH(stream_time) = p_month
    GROUP BY device_type;

    SELECT 'REVENUE SNAPSHOT' AS report_section,
           plan_name, subscribers, monthly_revenue
    FROM revenue_dashboard;
END$$

DELIMITER ;

-- ─────────────────────────────────────────
-- SECTION 8: PL/SQL (FUNCTIONS)
-- ─────────────────────────────────────────

DELIMITER $$

-- Function 1: Total listening time for a user (in hours)
CREATE FUNCTION calculate_user_listening_time(p_user_id INT)
RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_hours DECIMAL(10,2) DEFAULT 0.00;
    SELECT ROUND(SUM(listened_sec) / 3600.0, 2)
    INTO v_hours
    FROM STREAMS
    WHERE user_id = p_user_id;
    RETURN IFNULL(v_hours, 0.00);
END$$

-- Function 2: Artist popularity score (streams * unique_listeners)
CREATE FUNCTION get_artist_popularity_score(p_artist_id INT)
RETURNS BIGINT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_score BIGINT DEFAULT 0;
    SELECT COUNT(st.stream_id) * COUNT(DISTINCT st.user_id)
    INTO v_score
    FROM SONGS sg
    JOIN STREAMS st ON sg.song_id = st.song_id
    WHERE sg.artist_id = p_artist_id;
    RETURN IFNULL(v_score, 0);
END$$

-- Function 3: Check if user is premium
CREATE FUNCTION is_premium_user(p_user_id INT)
RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_plan VARCHAR(50);
    SELECT sub.plan_name INTO v_plan
    FROM USERS u JOIN SUBSCRIPTION sub ON u.subscription_id = sub.subscription_id
    WHERE u.user_id = p_user_id;
    RETURN (v_plan IN ('Premium', 'Family'));
END$$

DELIMITER ;

-- Test functions
SELECT
    u.user_id,
    u.name,
    calculate_user_listening_time(u.user_id)  AS listening_hours,
    is_premium_user(u.user_id)                AS is_premium
FROM USERS u
ORDER BY listening_hours DESC;

SELECT
    ar.artist_id,
    ar.artist_name,
    get_artist_popularity_score(ar.artist_id) AS popularity_score
FROM ARTISTS ar
ORDER BY popularity_score DESC;

-- ─────────────────────────────────────────
-- SECTION 9: TRIGGERS
-- ─────────────────────────────────────────

DELIMITER $$

-- Trigger 1: Validate stream data before insertion
CREATE TRIGGER before_stream_insert
BEFORE INSERT ON STREAMS
FOR EACH ROW
BEGIN
    DECLARE v_duration INT;
    SELECT duration_sec INTO v_duration FROM SONGS WHERE song_id = NEW.song_id;
    IF NEW.listened_sec > v_duration + 10 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ERROR: listened_sec cannot exceed song duration.';
    END IF;
END$$

-- Trigger 2: Log subscription changes (audit log table required)
CREATE TABLE IF NOT EXISTS subscription_change_log (
    log_id        INT PRIMARY KEY AUTO_INCREMENT,
    user_id       INT,
    old_sub_id    INT,
    new_sub_id    INT,
    changed_at    DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER after_subscription_change
AFTER UPDATE ON USERS
FOR EACH ROW
BEGIN
    IF OLD.subscription_id <> NEW.subscription_id THEN
        INSERT INTO subscription_change_log (user_id, old_sub_id, new_sub_id)
        VALUES (NEW.user_id, OLD.subscription_id, NEW.subscription_id);
    END IF;
END$$

DELIMITER ;

-- ─────────────────────────────────────────
-- SECTION 10: EXPLICIT CURSORS (PL/SQL)
-- ─────────────────────────────────────────

DELIMITER $$

-- Cursor: Print top artists with stats
CREATE PROCEDURE show_top_artists(IN p_limit INT)
BEGIN
    DECLARE done       INT DEFAULT FALSE;
    DECLARE v_artist   VARCHAR(100);
    DECLARE v_streams  INT;
    DECLARE v_listeners INT;

    DECLARE artist_cursor CURSOR FOR
        SELECT ar.artist_name,
               COUNT(st.stream_id)        AS total_streams,
               COUNT(DISTINCT st.user_id) AS unique_listeners
        FROM ARTISTS ar
        JOIN SONGS   sg ON ar.artist_id = sg.artist_id
        JOIN STREAMS st ON sg.song_id   = st.song_id
        GROUP BY ar.artist_name
        ORDER BY total_streams DESC
        LIMIT p_limit;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    DROP TEMPORARY TABLE IF EXISTS artist_report;
    CREATE TEMPORARY TABLE artist_report (
        artist_name      VARCHAR(100),
        total_streams    INT,
        unique_listeners INT
    );

    OPEN artist_cursor;
    read_loop: LOOP
        FETCH artist_cursor INTO v_artist, v_streams, v_listeners;
        IF done THEN LEAVE read_loop; END IF;
        INSERT INTO artist_report VALUES (v_artist, v_streams, v_listeners);
    END LOOP;
    CLOSE artist_cursor;

    SELECT * FROM artist_report;
    DROP TEMPORARY TABLE artist_report;
END$$

DELIMITER ;

CALL show_top_artists(5);

-- ─────────────────────────────────────────
-- SECTION 11: TRANSACTION EXAMPLES
-- ─────────────────────────────────────────

-- Transaction 1: Safely upgrade a user and log a stream atomically
START TRANSACTION;
SAVEPOINT before_upgrade;

UPDATE USERS SET subscription_id = 2 WHERE user_id = 3;

INSERT INTO STREAMS (user_id, song_id, stream_time, device_type, location, listened_sec)
VALUES (3, 14, NOW(), 'Mobile', 'New York, US', 210);

-- Verify and commit
COMMIT;

-- Transaction 2: Rollback example (simulated error)
START TRANSACTION;
SAVEPOINT start_batch;

-- This would fail if user 999 doesn't exist (FK violation)
-- INSERT INTO STREAMS (user_id, song_id, ...) VALUES (999, 1, ...);
-- ROLLBACK TO start_batch;
ROLLBACK; -- clean up demo

-- ─────────────────────────────────────────
-- SECTION 12: UPDATE & DELETE DML
-- ─────────────────────────────────────────

-- Update: Correct an artist's debut year
UPDATE ARTISTS SET debut_year = 2011 WHERE artist_id = 1;

-- Update: Bulk price update for Family plan
UPDATE SUBSCRIPTION SET monthly_price = 17.99 WHERE plan_name = 'Family';

-- Delete: Remove streams older than 2 years (data retention)
DELETE FROM STREAMS
WHERE stream_time < DATE_SUB(NOW(), INTERVAL 2 YEAR);

-- ─────────────────────────────────────────
-- SECTION 13: FINAL VERIFICATION QUERIES
-- ─────────────────────────────────────────

-- Show table row counts
SELECT 'SUBSCRIPTION' AS tbl, COUNT(*) AS rows FROM SUBSCRIPTION
UNION ALL SELECT 'USERS',   COUNT(*) FROM USERS
UNION ALL SELECT 'ARTISTS', COUNT(*) FROM ARTISTS
UNION ALL SELECT 'SONGS',   COUNT(*) FROM SONGS
UNION ALL SELECT 'STREAMS', COUNT(*) FROM STREAMS;

-- Full artist performance view
SELECT * FROM artist_performance;

-- Revenue summary
SELECT * FROM revenue_dashboard;

-- Top 10 popular songs
SELECT * FROM popular_songs LIMIT 10;

-- ============================================================
--   END OF MUSIC STREAMING ANALYTICS SYSTEM SQL
-- ============================================================

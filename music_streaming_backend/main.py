from fastapi import FastAPI, Query, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
import sqlite3, os
from database import get_connection, init_db

# ── APP SETUP ────────────────────────────────────────────────────────────────
app = FastAPI(title="Music Streaming Analytics API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── STARTUP ──────────────────────────────────────────────────────────────────
@app.on_event("startup")
def startup():
    init_db()

# Serve static files (the dashboard HTML)
app.mount("/static", StaticFiles(directory="static"), name="static")

@app.get("/", include_in_schema=False)
def serve_dashboard():
    return FileResponse("static/index.html")

# ── HELPER ───────────────────────────────────────────────────────────────────
def rows_to_list(rows):
    return [dict(r) for r in rows]

# ════════════════════════════════════════════════════════════════════════════
# ANALYTICS ENDPOINTS
# ════════════════════════════════════════════════════════════════════════════

@app.get("/api/stats/overview")
def overview():
    """KPI cards — total streams, revenue, hours, catalog size."""
    conn = get_connection()
    c = conn.cursor()

    total_streams = c.execute("SELECT COUNT(*) FROM STREAMS").fetchone()[0]
    total_hours   = round(c.execute("SELECT SUM(listened_sec)/3600.0 FROM STREAMS").fetchone()[0] or 0, 2)
    total_songs   = c.execute("SELECT COUNT(*) FROM SONGS").fetchone()[0]
    total_users   = c.execute("SELECT COUNT(*) FROM USERS").fetchone()[0]
    total_artists = c.execute("SELECT COUNT(*) FROM ARTISTS").fetchone()[0]

    revenue = c.execute("""
        SELECT ROUND(SUM(s.monthly_price), 2)
        FROM USERS u JOIN SUBSCRIPTION s ON u.subscription_id = s.subscription_id
    """).fetchone()[0] or 0

    conn.close()
    return {
        "total_streams": total_streams,
        "total_hours":   total_hours,
        "total_songs":   total_songs,
        "total_users":   total_users,
        "total_artists": total_artists,
        "monthly_revenue": revenue,
    }


@app.get("/api/stats/devices")
def device_breakdown():
    """Stream count and hours per device type."""
    conn = get_connection()
    rows = conn.execute("""
        SELECT device_type,
               COUNT(*)                          AS streams,
               ROUND(SUM(listened_sec)/3600.0,2) AS hours,
               ROUND(AVG(listened_sec),0)         AS avg_sec
        FROM STREAMS
        GROUP BY device_type
        ORDER BY streams DESC
    """).fetchall()
    conn.close()
    return rows_to_list(rows)


@app.get("/api/stats/genres")
def genre_breakdown():
    """Stream count per genre."""
    conn = get_connection()
    rows = conn.execute("""
        SELECT sg.genre,
               COUNT(st.stream_id)        AS streams,
               COUNT(DISTINCT st.user_id) AS unique_listeners
        FROM STREAMS st
        JOIN SONGS sg ON st.song_id = sg.song_id
        GROUP BY sg.genre
        ORDER BY streams DESC
    """).fetchall()
    conn.close()
    return rows_to_list(rows)


@app.get("/api/stats/revenue")
def revenue_breakdown():
    """Revenue per subscription plan."""
    conn = get_connection()
    rows = conn.execute("""
        SELECT sub.plan_name,
               sub.monthly_price,
               COUNT(u.user_id)                              AS subscribers,
               ROUND(COUNT(u.user_id) * sub.monthly_price,2) AS monthly_revenue
        FROM SUBSCRIPTION sub
        JOIN USERS u ON sub.subscription_id = u.subscription_id
        GROUP BY sub.plan_name, sub.monthly_price
        ORDER BY monthly_revenue DESC
    """).fetchall()
    conn.close()
    return rows_to_list(rows)


@app.get("/api/stats/peak-hours")
def peak_hours():
    """Streams per hour of day."""
    conn = get_connection()
    rows = conn.execute("""
        SELECT CAST(strftime('%H', stream_time) AS INTEGER) AS hour_of_day,
               COUNT(*) AS streams
        FROM STREAMS
        GROUP BY hour_of_day
        ORDER BY hour_of_day
    """).fetchall()
    conn.close()
    return rows_to_list(rows)


@app.get("/api/stats/locations")
def top_locations():
    """Top 10 locations by streams."""
    conn = get_connection()
    rows = conn.execute("""
        SELECT location,
               COUNT(*)                          AS streams,
               ROUND(SUM(listened_sec)/3600.0,2) AS hours
        FROM STREAMS
        GROUP BY location
        ORDER BY streams DESC
        LIMIT 10
    """).fetchall()
    conn.close()
    return rows_to_list(rows)


# ════════════════════════════════════════════════════════════════════════════
# SONGS ENDPOINTS
# ════════════════════════════════════════════════════════════════════════════

@app.get("/api/songs")
def get_songs(
    search: Optional[str] = Query(None, description="Search by title or artist"),
    genre:  Optional[str] = Query(None, description="Filter by genre"),
    year:   Optional[int] = Query(None, description="Filter by release year"),
    limit:  int           = Query(20,   description="Max results"),
):
    """All songs with stream count. Supports search and filters."""
    conn = get_connection()

    sql = """
        SELECT sg.song_id, sg.title, ar.artist_name, sg.genre,
               sg.release_year, sg.duration_sec, sg.language,
               COUNT(st.stream_id)                          AS streams,
               ROUND(AVG(st.listened_sec)*100.0/sg.duration_sec,1) AS avg_completion
        FROM SONGS sg
        JOIN ARTISTS ar ON sg.artist_id = ar.artist_id
        LEFT JOIN STREAMS st ON sg.song_id = st.song_id
        WHERE 1=1
    """
    params = []

    if search:
        sql += " AND (sg.title LIKE ? OR ar.artist_name LIKE ?)"
        params += [f"%{search}%", f"%{search}%"]
    if genre:
        sql += " AND sg.genre = ?"
        params.append(genre)
    if year:
        sql += " AND sg.release_year = ?"
        params.append(year)

    sql += " GROUP BY sg.song_id ORDER BY streams DESC LIMIT ?"
    params.append(limit)

    rows = conn.execute(sql, params).fetchall()
    conn.close()
    return rows_to_list(rows)


@app.get("/api/songs/genres")
def list_genres():
    """All unique genres for filter dropdown."""
    conn = get_connection()
    rows = conn.execute("SELECT DISTINCT genre FROM SONGS ORDER BY genre").fetchall()
    conn.close()
    return [r["genre"] for r in rows]


@app.get("/api/songs/{song_id}")
def get_song(song_id: int):
    """Single song detail with full stream history."""
    conn = get_connection()
    song = conn.execute("""
        SELECT sg.*, ar.artist_name, ar.country AS artist_country,
               COUNT(st.stream_id) AS total_streams,
               ROUND(SUM(st.listened_sec)/3600.0,2) AS total_hours
        FROM SONGS sg
        JOIN ARTISTS ar ON sg.artist_id = ar.artist_id
        LEFT JOIN STREAMS st ON sg.song_id = st.song_id
        WHERE sg.song_id = ?
        GROUP BY sg.song_id
    """, [song_id]).fetchone()

    if not song:
        raise HTTPException(status_code=404, detail="Song not found")

    conn.close()
    return dict(song)


# ════════════════════════════════════════════════════════════════════════════
# ARTISTS ENDPOINTS
# ════════════════════════════════════════════════════════════════════════════

@app.get("/api/artists")
def get_artists(
    search:   Optional[str] = Query(None, description="Search by name or country"),
    verified: Optional[bool]= Query(None, description="Filter verified artists only"),
):
    """All artists with performance stats."""
    conn = get_connection()
    sql = """
        SELECT ar.artist_id, ar.artist_name, ar.country, ar.debut_year, ar.is_verified,
               COUNT(DISTINCT st.stream_id)          AS total_streams,
               COUNT(DISTINCT st.user_id)            AS unique_listeners,
               COUNT(DISTINCT sg.song_id)            AS songs_count,
               ROUND(SUM(st.listened_sec)/3600.0,2)  AS total_hours,
               (COUNT(DISTINCT st.stream_id) * COUNT(DISTINCT st.user_id)) AS popularity_score
        FROM ARTISTS ar
        JOIN SONGS sg   ON ar.artist_id = sg.artist_id
        LEFT JOIN STREAMS st ON sg.song_id = st.song_id
        WHERE 1=1
    """
    params = []
    if search:
        sql += " AND (ar.artist_name LIKE ? OR ar.country LIKE ?)"
        params += [f"%{search}%", f"%{search}%"]
    if verified is not None:
        sql += " AND ar.is_verified = ?"
        params.append(1 if verified else 0)

    sql += " GROUP BY ar.artist_id ORDER BY total_streams DESC"
    rows = conn.execute(sql, params).fetchall()
    conn.close()
    return rows_to_list(rows)


# ════════════════════════════════════════════════════════════════════════════
# USERS ENDPOINTS
# ════════════════════════════════════════════════════════════════════════════

@app.get("/api/users")
def get_users(
    search: Optional[str] = Query(None, description="Search by name or country"),
    plan:   Optional[str] = Query(None, description="Filter by plan: Free, Premium, Family"),
):
    """All users with listening stats."""
    conn = get_connection()
    sql = """
        SELECT u.user_id, u.name, u.country, u.age, sub.plan_name,
               COUNT(st.stream_id)                   AS total_streams,
               ROUND(SUM(st.listened_sec)/3600.0,2)  AS total_hours
        FROM USERS u
        JOIN SUBSCRIPTION sub ON u.subscription_id = sub.subscription_id
        LEFT JOIN STREAMS st  ON u.user_id = st.user_id
        WHERE 1=1
    """
    params = []
    if search:
        sql += " AND (u.name LIKE ? OR u.country LIKE ?)"
        params += [f"%{search}%", f"%{search}%"]
    if plan:
        sql += " AND sub.plan_name = ?"
        params.append(plan)

    sql += " GROUP BY u.user_id ORDER BY total_streams DESC"
    rows = conn.execute(sql, params).fetchall()
    conn.close()
    return rows_to_list(rows)


@app.get("/api/users/{user_id}/history")
def user_history(user_id: int):
    """Listening history for a specific user."""
    conn = get_connection()
    rows = conn.execute("""
        SELECT sg.title, ar.artist_name, sg.genre,
               st.stream_time, st.device_type, st.location,
               st.listened_sec,
               ROUND(st.listened_sec*100.0/sg.duration_sec,1) AS completion_pct
        FROM STREAMS st
        JOIN SONGS sg   ON st.song_id   = sg.song_id
        JOIN ARTISTS ar ON sg.artist_id = ar.artist_id
        WHERE st.user_id = ?
        ORDER BY st.stream_time DESC
    """, [user_id]).fetchall()
    conn.close()
    return rows_to_list(rows)


# ════════════════════════════════════════════════════════════════════════════
# STREAMS — ADD A NEW STREAM (Procedure logic in Python)
# ════════════════════════════════════════════════════════════════════════════

class StreamIn(BaseModel):
    user_id:     int
    song_id:     int
    device_type: str
    location:    str
    listened_sec: int

@app.post("/api/streams")
def add_stream(data: StreamIn):
    """Add a new stream event with validation (mirrors the stored procedure)."""
    conn = get_connection()
    c = conn.cursor()

    user = c.execute("SELECT user_id FROM USERS WHERE user_id=?", [data.user_id]).fetchone()
    if not user:
        conn.close()
        raise HTTPException(status_code=404, detail="User not found")

    song = c.execute("SELECT duration_sec FROM SONGS WHERE song_id=?", [data.song_id]).fetchone()
    if not song:
        conn.close()
        raise HTTPException(status_code=404, detail="Song not found")

    if data.listened_sec < 0:
        conn.close()
        raise HTTPException(status_code=400, detail="listened_sec cannot be negative")

    if data.listened_sec > song["duration_sec"] + 10:
        conn.close()
        raise HTTPException(status_code=400, detail="listened_sec exceeds song duration")

    valid_devices = ['Mobile', 'Desktop', 'Smart Speaker', 'Tablet']
    if data.device_type not in valid_devices:
        conn.close()
        raise HTTPException(status_code=400, detail=f"device_type must be one of {valid_devices}")

    c.execute("""
        INSERT INTO STREAMS (user_id, song_id, device_type, location, listened_sec)
        VALUES (?,?,?,?,?)
    """, [data.user_id, data.song_id, data.device_type, data.location, data.listened_sec])
    conn.commit()
    new_id = c.lastrowid
    conn.close()
    return {"message": f"Stream #{new_id} logged successfully", "stream_id": new_id}


# ════════════════════════════════════════════════════════════════════════════
# SEARCH — global search across songs, artists, users
# ════════════════════════════════════════════════════════════════════════════

@app.get("/api/search")
def global_search(q: str = Query(..., min_length=1, description="Search term")):
    """Search songs, artists, and users in one call."""
    conn = get_connection()
    like = f"%{q}%"

    songs = conn.execute("""
        SELECT sg.song_id, sg.title, ar.artist_name, sg.genre
        FROM SONGS sg JOIN ARTISTS ar ON sg.artist_id = ar.artist_id
        WHERE sg.title LIKE ? OR ar.artist_name LIKE ?
        LIMIT 5
    """, [like, like]).fetchall()

    artists = conn.execute("""
        SELECT artist_id, artist_name, country FROM ARTISTS
        WHERE artist_name LIKE ? OR country LIKE ?
        LIMIT 5
    """, [like, like]).fetchall()

    users = conn.execute("""
        SELECT user_id, name, country FROM USERS
        WHERE name LIKE ? OR country LIKE ?
        LIMIT 5
    """, [like, like]).fetchall()

    conn.close()
    return {
        "songs":   rows_to_list(songs),
        "artists": rows_to_list(artists),
        "users":   rows_to_list(users),
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)

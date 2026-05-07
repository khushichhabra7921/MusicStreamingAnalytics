# Music Streaming Analytics — Backend Setup

## What's in this folder

```
music_streaming_backend/
├── main.py          ← FastAPI backend (all API routes)
├── database.py      ← SQLite setup + sample data
├── requirements.txt ← Python packages needed
├── static/
│   └── index.html   ← Frontend dashboard (live data)
└── README.md        ← This file
```

## How to run (step by step)

### Step 1 — Open this folder in Command Prompt
Right-click the folder → "Open in Terminal" or "Open Command Prompt here"
Or open CMD and type:
```
cd path\to\music_streaming_backend
```

### Step 2 — Install packages (only once)
```
pip install fastapi uvicorn
```

### Step 3 — Run the backend
```
python main.py
```
You should see:
```
✓ Database created with all tables and sample data.
INFO:     Uvicorn running on http://127.0.0.1:8000
```

### Step 4 — Open the dashboard
Open your browser and go to:
```
http://127.0.0.1:8000
```

That's it! The dashboard is live and connected to the real SQLite database.

---

## API Endpoints

| Method | URL | What it does |
|--------|-----|-------------|
| GET | /api/stats/overview | KPI numbers |
| GET | /api/stats/devices | Streams by device |
| GET | /api/stats/genres | Genre breakdown |
| GET | /api/stats/revenue | Revenue per plan |
| GET | /api/stats/peak-hours | Listening by hour |
| GET | /api/stats/locations | Top locations |
| GET | /api/songs | All songs (supports ?search=&genre=&year=) |
| GET | /api/songs/{id} | Single song detail |
| GET | /api/artists | All artists (supports ?search=&verified=true) |
| GET | /api/users | All users (supports ?search=&plan=) |
| GET | /api/users/{id}/history | One user's listening history |
| POST | /api/streams | Log a new stream |
| GET | /api/search?q= | Global search |

## Interactive API Docs
While the backend is running, visit:
```
http://127.0.0.1:8000/docs
```
This shows all endpoints and lets you test them directly in the browser.

---

## To stop the backend
Press Ctrl + C in the terminal.

## To reset the database
Delete the `music.db` file and run `python main.py` again.

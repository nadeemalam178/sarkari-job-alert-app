import os
import json
import sqlite3
from datetime import datetime

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(BASE_DIR, "data")
DB_PATH = os.path.join(DATA_DIR, "jobs.db")
JOBS_JSON_PATH = os.path.join(DATA_DIR, "jobs.json")
SETTINGS_JSON_PATH = os.path.join(DATA_DIR, "settings.json")
DEFAULT_SETTINGS_PATH = os.path.join(DATA_DIR, "default_settings.json")

os.makedirs(DATA_DIR, exist_ok=True)

def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS jobs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            url TEXT UNIQUE,
            title TEXT,
            org TEXT,
            last_date TEXT,
            eligibility_snippet TEXT,
            qualifications_found TEXT,
            matched_keywords TEXT,
            is_matched INTEGER DEFAULT 0,
            scraped_at TEXT,
            notified INTEGER DEFAULT 0
        )
    ''')
    conn.commit()
    conn.close()

    # Ensure settings.json exists
    if not os.path.exists(SETTINGS_JSON_PATH):
        if os.path.exists(DEFAULT_SETTINGS_PATH):
            with open(DEFAULT_SETTINGS_PATH, "r", encoding="utf-8") as f:
                settings = json.load(f)
        else:
            settings = {
                "selected_qualifications": ["B.ED", "CTET", "STET", "GRADUATE", "MCA", "BCA", "10+2"],
                "custom_keywords": ["TEACHER", "COMPUTER"],
                "check_interval_minutes": 60,
                "enable_browser_push": True,
                "enable_sound": True,
                "ntfy_topic": "sarkari_job_alert_user",
                "telegram_bot_token": "",
                "telegram_chat_id": "",
                "last_checked_at": None,
                "total_checked": 0,
                "total_matched": 0
            }
        save_settings(settings)

    # Sync from jobs.json into SQLite if DB is empty but jobs.json has data
    sync_json_to_db_if_needed()

def sync_json_to_db_if_needed():
    if os.path.exists(JOBS_JSON_PATH):
        try:
            with open(JOBS_JSON_PATH, "r", encoding="utf-8") as f:
                jobs = json.load(f)
            if jobs:
                conn = get_db()
                cursor = conn.cursor()
                for j in jobs:
                    cursor.execute('''
                        INSERT OR IGNORE INTO jobs 
                        (url, title, org, last_date, eligibility_snippet, qualifications_found, matched_keywords, is_matched, scraped_at, notified)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    ''', (
                        j.get("url"),
                        j.get("title"),
                        j.get("org", ""),
                        j.get("last_date", ""),
                        j.get("eligibility_snippet", ""),
                        json.dumps(j.get("qualifications_found", [])),
                        json.dumps(j.get("matched_keywords", [])),
                        1 if j.get("is_matched") else 0,
                        j.get("scraped_at", datetime.now().isoformat()),
                        1 if j.get("notified") else 0
                    ))
                conn.commit()
                conn.close()
        except Exception as e:
            print("Sync warning:", e)

def sync_db_to_json():
    """Exports all jobs from SQLite into jobs.json for static/serverless Vercel deployment"""
    try:
        conn = get_db()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM jobs ORDER BY id DESC")
        rows = cursor.fetchall()
        jobs = []
        for r in rows:
            qual_found = []
            matched_kw = []
            try:
                qual_found = json.loads(r["qualifications_found"]) if r["qualifications_found"] else []
            except:
                qual_found = [r["qualifications_found"]]
            try:
                matched_kw = json.loads(r["matched_keywords"]) if r["matched_keywords"] else []
            except:
                matched_kw = [r["matched_keywords"]]

            jobs.append({
                "id": r["id"],
                "url": r["url"],
                "title": r["title"],
                "org": r["org"],
                "last_date": r["last_date"],
                "eligibility_snippet": r["eligibility_snippet"],
                "qualifications_found": qual_found,
                "matched_keywords": matched_kw,
                "is_matched": bool(r["is_matched"]),
                "scraped_at": r["scraped_at"],
                "notified": bool(r["notified"])
            })
        conn.close()

        with open(JOBS_JSON_PATH, "w", encoding="utf-8") as f:
            json.dump(jobs, f, indent=2, ensure_ascii=False)
        return jobs
    except Exception as e:
        print("Export to JSON failed:", e)
        return []

def get_settings():
    if os.path.exists(SETTINGS_JSON_PATH):
        try:
            with open(SETTINGS_JSON_PATH, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass
    if os.path.exists(DEFAULT_SETTINGS_PATH):
        with open(DEFAULT_SETTINGS_PATH, "r", encoding="utf-8") as f:
            return json.load(f)
    return {}

def save_settings(settings):
    with open(SETTINGS_JSON_PATH, "w", encoding="utf-8") as f:
        json.dump(settings, f, indent=2, ensure_ascii=False)

def get_seen_urls():
    """Ultra-fast set of already processed URLs to avoid re-scraping"""
    urls = set()
    try:
        conn = get_db()
        cursor = conn.cursor()
        cursor.execute("SELECT url FROM jobs")
        rows = cursor.fetchall()
        for r in rows:
            urls.add(r["url"])
        conn.close()
    except Exception:
        # Fallback to jobs.json
        if os.path.exists(JOBS_JSON_PATH):
            try:
                with open(JOBS_JSON_PATH, "r", encoding="utf-8") as f:
                    jobs = json.load(f)
                    urls = {j.get("url") for j in jobs if j.get("url")}
            except Exception:
                pass
    return urls

def save_job(job_data):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute('''
        INSERT OR REPLACE INTO jobs 
        (url, title, org, last_date, eligibility_snippet, qualifications_found, matched_keywords, is_matched, scraped_at, notified)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', (
        job_data["url"],
        job_data["title"],
        job_data.get("org", ""),
        job_data.get("last_date", ""),
        job_data.get("eligibility_snippet", ""),
        json.dumps(job_data.get("qualifications_found", [])),
        json.dumps(job_data.get("matched_keywords", [])),
        1 if job_data.get("is_matched") else 0,
        job_data.get("scraped_at", datetime.now().isoformat()),
        1 if job_data.get("notified") else 0
    ))
    conn.commit()
    conn.close()

def get_all_jobs(matched_only=False, search=None, limit=100):
    try:
        conn = get_db()
        cursor = conn.cursor()
        query = "SELECT * FROM jobs"
        params = []
        conditions = []

        if matched_only:
            conditions.append("is_matched = 1")
        if search:
            conditions.append("(title LIKE ? OR org LIKE ? OR eligibility_snippet LIKE ? OR matched_keywords LIKE ?)")
            search_param = f"%{search}%"
            params.extend([search_param, search_param, search_param, search_param])

        if conditions:
            query += " WHERE " + " AND ".join(conditions)

        query += " ORDER BY id DESC LIMIT ?"
        params.append(limit)

        cursor.execute(query, params)
        rows = cursor.fetchall()
        jobs = []
        for r in rows:
            qual_found = []
            matched_kw = []
            try:
                qual_found = json.loads(r["qualifications_found"]) if r["qualifications_found"] else []
            except:
                qual_found = [r["qualifications_found"]]
            try:
                matched_kw = json.loads(r["matched_keywords"]) if r["matched_keywords"] else []
            except:
                matched_kw = [r["matched_keywords"]]

            jobs.append({
                "id": r["id"],
                "url": r["url"],
                "title": r["title"],
                "org": r["org"],
                "last_date": r["last_date"],
                "eligibility_snippet": r["eligibility_snippet"],
                "qualifications_found": qual_found,
                "matched_keywords": matched_kw,
                "is_matched": bool(r["is_matched"]),
                "scraped_at": r["scraped_at"],
                "notified": bool(r["notified"])
            })
        conn.close()
        return jobs
    except Exception as e:
        # Fallback to json if DB query fails
        if os.path.exists(JOBS_JSON_PATH):
            with open(JOBS_JSON_PATH, "r", encoding="utf-8") as f:
                jobs = json.load(f)
                if matched_only:
                    jobs = [j for j in jobs if j.get("is_matched")]
                return jobs[:limit]
        return []

def get_stats():
    total_checked = 0
    total_matched = 0
    try:
        conn = get_db()
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM jobs")
        total_checked = cursor.fetchone()[0]
        cursor.execute("SELECT COUNT(*) FROM jobs WHERE is_matched = 1")
        total_matched = cursor.fetchone()[0]
        conn.close()
    except Exception:
        pass
    settings = get_settings()
    return {
        "total_checked": total_checked,
        "total_matched": total_matched,
        "last_checked_at": settings.get("last_checked_at"),
        "ntfy_topic": settings.get("ntfy_topic", "sarkari_job_alert_user")
    }

# Initialize on import
init_db()

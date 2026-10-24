import os
import json
import sqlite3
import hashlib
import secrets
from datetime import datetime

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(BASE_DIR, "data")
DB_PATH = os.path.join(DATA_DIR, "jobs.db")
JOBS_JSON_PATH = os.path.join(DATA_DIR, "jobs.json")
SETTINGS_JSON_PATH = os.path.join(DATA_DIR, "settings.json")
DEFAULT_SETTINGS_PATH = os.path.join(DATA_DIR, "default_settings.json")

os.makedirs(DATA_DIR, exist_ok=True)

def hash_password(password, salt=None):
    if not salt:
        salt = secrets.token_hex(16)
    hashed = hashlib.sha256((password + salt).encode('utf-8')).hexdigest()
    return f"{salt}${hashed}"

def verify_password(password, stored_hash):
    if not stored_hash or "$" not in stored_hash:
        return False
    salt, hashed = stored_hash.split("$", 1)
    test_hash = hashlib.sha256((password + salt).encode('utf-8')).hexdigest()
    return test_hash == hashed

def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_db()
    cursor = conn.cursor()
    
    # 1. Jobs Table (with source column)
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS jobs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            source TEXT DEFAULT 'SarkariResult',
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

    # Check if 'source' column exists in existing DB
    cursor.execute("PRAGMA table_info(jobs)")
    cols = [col[1] for col in cursor.fetchall()]
    if "source" not in cols:
        try:
            cursor.execute("ALTER TABLE jobs ADD COLUMN source TEXT DEFAULT 'SarkariResult'")
        except Exception:
            pass

    # 2. Users Table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            email TEXT UNIQUE COLLATE NOCASE,
            password_hash TEXT,
            qualifications TEXT,
            custom_keywords TEXT,
            state TEXT DEFAULT 'All India',
            ntfy_topic TEXT,
            created_at TEXT
        )
    ''')

    # 3. Sessions Table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS sessions (
            token TEXT PRIMARY KEY,
            user_id INTEGER,
            created_at TEXT,
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
        )
    ''')

    conn.commit()
    conn.close()

    # Sync from jobs.json into SQLite if DB is empty
    sync_json_to_db_if_needed()

# --- User Auth Functions ---

def register_user(name, email, password, qualifications, custom_keywords=None, state="All India"):
    name = (name or "").strip()
    email = (email or "").strip().lower()
    if not email or not password or not name:
        return False, "Name, email and password are required"

    if not qualifications:
        qualifications = ["GRADUATE"]

    conn = get_db()
    cursor = conn.cursor()
    try:
        pw_hash = hash_password(password)
        clean_name = "".join(c for c in name.lower() if c.isalnum())[:10]
        rand_suffix = secrets.token_hex(3)
        ntfy_topic = f"sarkari_job_{clean_name}_{rand_suffix}"

        cursor.execute('''
            INSERT INTO users (name, email, password_hash, qualifications, custom_keywords, state, ntfy_topic, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            name,
            email,
            pw_hash,
            json.dumps(qualifications),
            json.dumps(custom_keywords or []),
            state or "All India",
            ntfy_topic,
            datetime.now().isoformat()
        ))
        user_id = cursor.lastrowid
        conn.commit()

        # Create session
        token = create_session(user_id)
        user_data = get_user_by_id(user_id)
        conn.close()
        return True, {"token": token, "user": user_data}
    except sqlite3.IntegrityError:
        conn.close()
        return False, "An account with this email already exists. Please log in."
    except Exception as e:
        conn.close()
        return False, str(e)

def login_user(email, password):
    email = (email or "").strip().lower()
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM users WHERE email = ?", (email,))
    row = cursor.fetchone()
    conn.close()

    if not row:
        return False, "Account not found with this email"

    if not verify_password(password, row["password_hash"]):
        return False, "Incorrect password"

    token = create_session(row["id"])
    user_data = format_user_row(row)
    return True, {"token": token, "user": user_data}

def create_session(user_id):
    token = secrets.token_hex(24)
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute('''
        INSERT INTO sessions (token, user_id, created_at)
        VALUES (?, ?, ?)
    ''', (token, user_id, datetime.now().isoformat()))
    conn.commit()
    conn.close()
    return token

def get_user_by_token(token):
    if not token:
        return None
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute('''
        SELECT u.* FROM users u
        JOIN sessions s ON u.id = s.user_id
        WHERE s.token = ?
    ''', (token,))
    row = cursor.fetchone()
    conn.close()
    if row:
        return format_user_row(row)
    return None

def get_user_by_id(user_id):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,))
    row = cursor.fetchone()
    conn.close()
    if row:
        return format_user_row(row)
    return None

def update_user_profile(user_id, name=None, qualifications=None, custom_keywords=None, state=None, ntfy_topic=None):
    conn = get_db()
    cursor = conn.cursor()
    updates = []
    params = []

    if name is not None:
        updates.append("name = ?")
        params.append(name.strip())
    if qualifications is not None:
        updates.append("qualifications = ?")
        params.append(json.dumps(qualifications))
    if custom_keywords is not None:
        updates.append("custom_keywords = ?")
        params.append(json.dumps(custom_keywords))
    if state is not None:
        updates.append("state = ?")
        params.append(state.strip())
    if ntfy_topic is not None:
        updates.append("ntfy_topic = ?")
        params.append(ntfy_topic.strip())

    if not updates:
        conn.close()
        return get_user_by_id(user_id)

    params.append(user_id)
    query = f"UPDATE users SET {', '.join(updates)} WHERE id = ?"
    cursor.execute(query, params)
    conn.commit()
    conn.close()
    return get_user_by_id(user_id)

def logout_session(token):
    if not token:
        return
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM sessions WHERE token = ?", (token,))
    conn.commit()
    conn.close()

def get_all_users_for_notifications():
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT id, name, email, qualifications, custom_keywords, ntfy_topic FROM users")
    rows = cursor.fetchall()
    conn.close()
    users = []
    for r in rows:
        users.append(format_user_row(r))
    return users

def format_user_row(row):
    quals = []
    kw = []
    try:
        quals = json.loads(row["qualifications"]) if row["qualifications"] else []
    except Exception:
        quals = []
    try:
        kw = json.loads(row["custom_keywords"]) if row["custom_keywords"] else []
    except Exception:
        kw = []

    return {
        "id": row["id"],
        "name": row["name"],
        "email": row["email"],
        "qualifications": quals,
        "custom_keywords": kw,
        "state": row["state"] if "state" in row.keys() else "All India",
        "ntfy_topic": row["ntfy_topic"],
        "created_at": row["created_at"] if "created_at" in row.keys() else None
    }

# --- Jobs & Sync Functions ---

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
                        (source, url, title, org, last_date, eligibility_snippet, qualifications_found, matched_keywords, is_matched, scraped_at, notified)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    ''', (
                        j.get("source", "SarkariResult"),
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
                "source": r["source"] if "source" in r.keys() else "SarkariResult",
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

def get_seen_urls():
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
        (source, url, title, org, last_date, eligibility_snippet, qualifications_found, matched_keywords, is_matched, scraped_at, notified)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', (
        job_data.get("source", "SarkariResult"),
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

def get_jobs_for_user(user=None, matched_only=False, search=None, source=None, limit=100):
    """
    Returns jobs customized for the logged-in user:
    Calculates dynamic qualification matches based on user's selected qualifications!
    """
    try:
        conn = get_db()
        cursor = conn.cursor()
        query = "SELECT * FROM jobs"
        params = []
        conditions = []

        if source and source.lower() != "all":
            conditions.append("source = ?")
            params.append(source)

        if search:
            conditions.append("(title LIKE ? OR org LIKE ? OR eligibility_snippet LIKE ? OR qualifications_found LIKE ?)")
            p = f"%{search}%"
            params.extend([p, p, p, p])

        if conditions:
            query += " WHERE " + " AND ".join(conditions)

        query += " ORDER BY id DESC LIMIT ?"
        params.append(limit * 2 if matched_only else limit)

        cursor.execute(query, params)
        rows = cursor.fetchall()
        conn.close()

        user_quals = [q.upper() for q in (user.get("qualifications", []) if user else [])]
        user_kw = [k.lower() for k in (user.get("custom_keywords", []) if user else [])]

        results = []
        for r in rows:
            qual_found = []
            try:
                qual_found = json.loads(r["qualifications_found"]) if r["qualifications_found"] else []
            except Exception:
                qual_found = [r["qualifications_found"]]

            # Compute dynamic match for this specific user
            matched_for_this_user = []
            for uq in user_quals:
                for qf in qual_found:
                    if uq in qf.upper() or qf.upper() in uq:
                        matched_for_this_user.append(qf)
                        break

            # Check custom keywords in text
            text_combo = (r["title"] + " " + (r["eligibility_snippet"] or "") + " " + (r["org"] or "")).lower()
            for kw in user_kw:
                if kw and kw in text_combo:
                    matched_for_this_user.append(kw.upper())

            matched_for_this_user = list(dict.fromkeys(matched_for_this_user))
            is_user_match = len(matched_for_this_user) > 0 if user_quals or user_kw else bool(r["is_matched"])

            if matched_only and not is_user_match:
                continue

            results.append({
                "id": r["id"],
                "source": r["source"] if "source" in r.keys() else "SarkariResult",
                "url": r["url"],
                "title": r["title"],
                "org": r["org"],
                "last_date": r["last_date"],
                "eligibility_snippet": r["eligibility_snippet"],
                "qualifications_found": qual_found,
                "matched_keywords": matched_for_this_user if user else json.loads(r["matched_keywords"] or "[]"),
                "is_matched": is_user_match,
                "scraped_at": r["scraped_at"],
                "notified": bool(r["notified"])
            })

            if len(results) >= limit:
                break

        return results
    except Exception as e:
        print("get_jobs_for_user error:", e)
        return []

def get_stats(user=None):
    total_checked = 0
    total_matched = 0
    sources_count = {}
    try:
        conn = get_db()
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM jobs")
        total_checked = cursor.fetchone()[0]

        cursor.execute("SELECT source, COUNT(*) FROM jobs GROUP BY source")
        for s, count in cursor.fetchall():
            sources_count[s or "SarkariResult"] = count

        conn.close()
    except Exception:
        pass

    # Count matched for user
    if user:
        matched_jobs = get_jobs_for_user(user=user, matched_only=True, limit=500)
        total_matched = len(matched_jobs)
    else:
        try:
            conn = get_db()
            cursor = conn.cursor()
            cursor.execute("SELECT COUNT(*) FROM jobs WHERE is_matched = 1")
            total_matched = cursor.fetchone()[0]
            conn.close()
        except:
            pass

    return {
        "total_checked": total_checked,
        "total_matched": total_matched,
        "sources": sources_count,
        "ntfy_topic": user.get("ntfy_topic") if user else "sarkari_job_alert_user"
    }

# Backward compatibility functions
def get_settings():
    if os.path.exists(SETTINGS_JSON_PATH):
        try:
            with open(SETTINGS_JSON_PATH, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass
    return {
        "selected_qualifications": ["B.ED", "CTET", "GRADUATE", "10+2"],
        "custom_keywords": ["TEACHER"],
        "check_interval_minutes": 60,
        "ntfy_topic": "sarkari_job_alert_user"
    }

def save_settings(settings):
    with open(SETTINGS_JSON_PATH, "w", encoding="utf-8") as f:
        json.dump(settings, f, indent=2, ensure_ascii=False)

def get_all_jobs(matched_only=False, search=None, limit=100):
    return get_jobs_for_user(user=None, matched_only=matched_only, search=search, limit=limit)

init_db()

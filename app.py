import os
import sys
import json
from flask import Flask, jsonify, request, send_from_directory
from apscheduler.schedulers.background import BackgroundScheduler
import database
import scraper
import notifier

# Ensure unicode stdout for Windows
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

app = Flask(__name__, static_folder="static")

# Scheduler setup
scheduler = BackgroundScheduler()

def scheduled_job():
    print("[Cron] Starting automated multi-source scrape...")
    try:
        scraper.run_scrape_cycle(max_per_source=10)
    except Exception as e:
        print("[Cron] Scraping error:", e)

# Run every 60 minutes
scheduler.add_job(scheduled_job, 'interval', minutes=60, id='scraper_job')
scheduler.start()

def get_current_user():
    auth_header = request.headers.get("Authorization", "")
    token = None
    if auth_header.startswith("Bearer "):
        token = auth_header.split(" ", 1)[1].strip()
    elif request.args.get("token"):
        token = request.args.get("token").strip()

    if token:
        return database.get_user_by_token(token), token
    return None, None

@app.route("/")
def index():
    return send_from_directory("static", "index.html")

@app.route("/<path:path>")
def serve_static(path):
    if os.path.exists(os.path.join("static", path)):
        return send_from_directory("static", path)
    return send_from_directory("static", "index.html")

# --- Authentication & Profile Endpoints ---

@app.route("/api/auth/register", methods=["POST"])
def register():
    data = request.json or {}
    name = data.get("name")
    email = data.get("email")
    password = data.get("password")
    qualifications = data.get("qualifications", ["GRADUATE"])
    custom_keywords = data.get("custom_keywords", [])
    state = data.get("state", "All India")

    ok, result = database.register_user(
        name=name,
        email=email,
        password=password,
        qualifications=qualifications,
        custom_keywords=custom_keywords,
        state=state
    )

    if ok:
        return jsonify({"success": True, "token": result["token"], "user": result["user"]})
    return jsonify({"success": False, "error": result}), 400

@app.route("/api/auth/login", methods=["POST"])
def login():
    data = request.json or {}
    email = data.get("email")
    password = data.get("password")

    ok, result = database.login_user(email=email, password=password)
    if ok:
        return jsonify({"success": True, "token": result["token"], "user": result["user"]})
    return jsonify({"success": False, "error": result}), 401

@app.route("/api/auth/me", methods=["GET"])
def me():
    user, _ = get_current_user()
    if user:
        return jsonify({"success": True, "user": user})
    return jsonify({"success": False, "error": "Not authenticated"}), 401

@app.route("/api/auth/logout", methods=["POST"])
def logout():
    _, token = get_current_user()
    if token:
        database.logout_session(token)
    return jsonify({"success": True})

@app.route("/api/auth/profile", methods=["PUT"])
def update_profile():
    user, _ = get_current_user()
    if not user:
        return jsonify({"success": False, "error": "Unauthorized"}), 401

    data = request.json or {}
    updated = database.update_user_profile(
        user_id=user["id"],
        name=data.get("name"),
        qualifications=data.get("qualifications"),
        custom_keywords=data.get("custom_keywords"),
        state=data.get("state"),
        ntfy_topic=data.get("ntfy_topic")
    )
    return jsonify({"success": True, "user": updated})

# --- Jobs & Stats Endpoints ---

@app.route("/api/jobs", methods=["GET"])
def get_jobs():
    user, _ = get_current_user()
    matched_only = request.args.get("matched_only", "false").lower() == "true"
    search = request.args.get("search", "").strip()
    source = request.args.get("source", "").strip()
    limit = int(request.args.get("limit", 100))

    jobs = database.get_jobs_for_user(
        user=user,
        matched_only=matched_only,
        search=search or None,
        source=source or None,
        limit=limit
    )
    return jsonify({"success": True, "count": len(jobs), "jobs": jobs})

@app.route("/api/stats", methods=["GET"])
def get_stats():
    user, _ = get_current_user()
    stats = database.get_stats(user=user)
    return jsonify({"success": True, "stats": stats})

@app.route("/api/scrape-now", methods=["POST"])
def trigger_scrape():
    try:
        result = scraper.run_scrape_cycle(max_per_source=8)
        user, _ = get_current_user()
        return jsonify({"success": True, "result": result, "stats": database.get_stats(user=user)})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

@app.route("/api/test-notification", methods=["POST"])
def test_notification():
    user, _ = get_current_user()
    topic = (user.get("ntfy_topic") if user else None) or "sarkari_job_alert_user"
    user_quals = (user.get("qualifications") if user else ["B.ED", "CTET", "GRADUATE"])
    
    sample_job = {
        "title": f"Test Alert: Govt Job Match for {user['name'] if user else 'Candidate'}",
        "matched_keywords": user_quals[:3],
        "last_date": "31/12/2026",
        "url": "https://www.sarkariresult.com"
    }
    results = notifier.dispatch_job_alert(sample_job, {"ntfy_topic": topic})
    return jsonify({"success": True, "results": results, "topic": topic})

# Legacy compatibility
@app.route("/api/settings", methods=["GET", "POST"])
def handle_settings():
    user, _ = get_current_user()
    if user:
        if request.method == "POST":
            data = request.json or {}
            updated = database.update_user_profile(
                user_id=user["id"],
                qualifications=data.get("selected_qualifications"),
                custom_keywords=data.get("custom_keywords")
            )
            return jsonify({"success": True, "settings": {
                "selected_qualifications": updated["qualifications"],
                "custom_keywords": updated["custom_keywords"]
            }})
        return jsonify({"success": True, "settings": {
            "selected_qualifications": user["qualifications"],
            "custom_keywords": user["custom_keywords"]
        }})
    return jsonify({"success": True, "settings": database.get_settings()})

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    print("==================================================")
    print(f"🚀 Sarkari Job Alert Multi-Portal Web App:")
    print(f"   http://localhost:{port}")
    print("==================================================")
    app.run(host="0.0.0.0", port=port, debug=False)

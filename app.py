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
    print("[Cron] Starting automated periodic scrape...")
    try:
        scraper.run_scrape_cycle(max_new_jobs=15)
    except Exception as e:
        print("[Cron] Scraping error:", e)

# Start scheduler with configured interval
settings = database.get_settings()
interval_mins = settings.get("check_interval_minutes", 60)
scheduler.add_job(scheduled_job, 'interval', minutes=max(5, interval_mins), id='scraper_job')
scheduler.start()

@app.route("/")
def index():
    return send_from_directory("static", "index.html")

@app.route("/<path:path>")
def serve_static(path):
    if os.path.exists(os.path.join("static", path)):
        return send_from_directory("static", path)
    return send_from_directory("static", "index.html")

@app.route("/api/jobs", methods=["GET"])
def get_jobs():
    matched_only = request.args.get("matched_only", "false").lower() == "true"
    search = request.args.get("search", "").strip()
    limit = int(request.args.get("limit", 100))
    jobs = database.get_all_jobs(matched_only=matched_only, search=search or None, limit=limit)
    return jsonify({"success": True, "count": len(jobs), "jobs": jobs})

@app.route("/api/stats", methods=["GET"])
def get_stats():
    stats = database.get_stats()
    return jsonify({"success": True, "stats": stats})

@app.route("/api/settings", methods=["GET", "POST"])
def handle_settings():
    if request.method == "POST":
        data = request.json or {}
        current_settings = database.get_settings()
        
        # Check if qualifications or keywords changed
        old_quals = current_settings.get("selected_qualifications", [])
        new_quals = data.get("selected_qualifications", old_quals)
        old_kw = current_settings.get("custom_keywords", [])
        new_kw = data.get("custom_keywords", old_kw)

        quals_changed = (set(old_quals) != set(new_quals)) or (set(old_kw) != set(new_kw))

        # Update fields
        for key in ["selected_qualifications", "custom_keywords", "check_interval_minutes", 
                    "enable_browser_push", "enable_sound", "ntfy_topic", 
                    "telegram_bot_token", "telegram_chat_id"]:
            if key in data:
                current_settings[key] = data[key]

        database.save_settings(current_settings)

        # Update scheduler interval if changed
        try:
            new_interval = max(5, int(current_settings.get("check_interval_minutes", 60)))
            scheduler.reschedule_job('scraper_job', trigger='interval', minutes=new_interval)
        except Exception:
            pass

        # If qualifications changed, re-match existing jobs in-memory without re-scraping!
        rematched = 0
        if quals_changed:
            rematched = scraper.rematch_all_cached_jobs()

        return jsonify({"success": True, "settings": current_settings, "rematched_jobs": rematched})

    return jsonify({"success": True, "settings": database.get_settings()})

@app.route("/api/scrape-now", methods=["POST"])
def trigger_scrape():
    try:
        result = scraper.run_scrape_cycle(max_new_jobs=15)
        return jsonify({"success": True, "result": result, "stats": database.get_stats()})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

@app.route("/api/test-notification", methods=["POST"])
def test_notification():
    settings = database.get_settings()
    sample_job = {
        "title": "Sample Test Alert: Sarkari Result Job Tracker",
        "matched_keywords": ["B.ED", "CTET", "GRADUATE"],
        "last_date": "31/12/2026",
        "url": "https://www.sarkariresult.com"
    }
    results = notifier.dispatch_job_alert(sample_job, settings)
    return jsonify({"success": True, "results": results})

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    print(f"==================================================")
    print(f"🚀 Sarkari Result Job Alert Web App running at:")
    print(f"   http://localhost:{port}")
    print(f"==================================================")
    app.run(host="0.0.0.0", port=port, debug=False)

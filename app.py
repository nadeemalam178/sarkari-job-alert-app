import os
import sys
import json
from flask import Flask, jsonify, request, send_from_directory
from apscheduler.schedulers.background import BackgroundScheduler
import database
import scraper
import notifier

# Ensure unicode stdout for Windows consoles
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

app = Flask(__name__, static_folder="static")

# Scheduler setup
scheduler = BackgroundScheduler()

def scheduled_job():
    print("[Cron] Starting automated deduplicated multi-source scrape...")
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

# --- Comprehensive List of Indian Government Job Qualifications ---
INDIAN_QUALIFICATIONS_MASTER = [
    {"code": "10TH", "name": "10th Pass / Matriculation / High School", "category": "Schooling"},
    {"code": "12TH / 10+2", "name": "12th Pass / Intermediate (Any Stream)", "category": "Schooling"},
    {"code": "12TH PCM", "name": "12th Pass (Science - Math / PCM)", "category": "Schooling"},
    {"code": "12TH PCB", "name": "12th Pass (Science - Biology / PCB)", "category": "Schooling"},
    {"code": "12TH COMMERCE", "name": "12th Pass (Commerce)", "category": "Schooling"},
    {"code": "8TH", "name": "8th Pass / Middle School", "category": "Schooling"},

    # Teaching
    {"code": "B.ED", "name": "B.Ed (Bachelor of Education)", "category": "Teaching"},
    {"code": "D.EL.ED / BTC", "name": "D.El.Ed / BTC (Diploma in Elementary Education)", "category": "Teaching"},
    {"code": "CTET", "name": "CTET (Central Teacher Eligibility Test)", "category": "Teaching"},
    {"code": "CTET PAPER 1", "name": "CTET Paper 1 (Primary - Class 1 to 5)", "category": "Teaching"},
    {"code": "CTET PAPER 2", "name": "CTET Paper 2 (Upper Primary - Class 6 to 8)", "category": "Teaching"},
    {"code": "STET", "name": "STET / State TET (Paper 1 / Paper 2)", "category": "Teaching"},
    {"code": "NTT", "name": "NTT (Nursery Teacher Training)", "category": "Teaching"},
    {"code": "TEACHER", "name": "Teacher (PRT / TGT / PGT / Educator)", "category": "Teaching"},

    # Graduation
    {"code": "GRADUATE", "name": "Graduate in Any Stream (BA / BSc / BCom)", "category": "Graduation"},
    {"code": "BA", "name": "BA (Bachelor of Arts)", "category": "Graduation"},
    {"code": "B.SC", "name": "B.Sc (Bachelor of Science)", "category": "Graduation"},
    {"code": "B.COM", "name": "B.Com (Bachelor of Commerce)", "category": "Graduation"},
    {"code": "BBA", "name": "BBA (Bachelor of Business Administration)", "category": "Graduation"},
    {"code": "BCA", "name": "BCA (Bachelor of Computer Applications)", "category": "Graduation"},
    {"code": "B.LIB", "name": "B.Lib / B.Lib.I.Sc (Library Science)", "category": "Graduation"},

    # Engineering (B.Tech / B.E)
    {"code": "B.TECH / B.E", "name": "B.Tech / B.E (Engineering - Any Branch)", "category": "Engineering"},
    {"code": "B.TECH CIVIL", "name": "B.Tech / B.E (Civil Engineering)", "category": "Engineering"},
    {"code": "B.TECH MECHANICAL", "name": "B.Tech / B.E (Mechanical Engineering)", "category": "Engineering"},
    {"code": "B.TECH ELECTRICAL", "name": "B.Tech / B.E (Electrical Engineering)", "category": "Engineering"},
    {"code": "B.TECH CS / IT", "name": "B.Tech / B.E (Computer Science / IT)", "category": "Engineering"},

    # Polytechnic & Diploma
    {"code": "DIPLOMA", "name": "Polytechnic Diploma (Any Branch)", "category": "Diploma & ITI"},
    {"code": "DIPLOMA CIVIL", "name": "Diploma in Civil Engineering", "category": "Diploma & ITI"},
    {"code": "DIPLOMA MECHANICAL", "name": "Diploma in Mechanical Engineering", "category": "Diploma & ITI"},
    {"code": "DIPLOMA ELECTRICAL", "name": "Diploma in Electrical Engineering", "category": "Diploma & ITI"},
    {"code": "D.PHARMA", "name": "D.Pharma (Diploma in Pharmacy)", "category": "Diploma & ITI"},
    {"code": "ITI", "name": "ITI (Any Trade Certificate)", "category": "Diploma & ITI"},
    {"code": "ITI FITTER", "name": "ITI (Fitter Trade)", "category": "Diploma & ITI"},
    {"code": "ITI ELECTRICIAN", "name": "ITI (Electrician Trade)", "category": "Diploma & ITI"},
    {"code": "ITI WELDER", "name": "ITI (Welder Trade)", "category": "Diploma & ITI"},
    {"code": "ITI COPA", "name": "ITI COPA (Computer Operator)", "category": "Diploma & ITI"},

    # Post Graduation (Masters)
    {"code": "POST GRADUATE", "name": "Post Graduate (Any Stream / Master Degree)", "category": "Post Graduation"},
    {"code": "MA", "name": "MA (Master of Arts)", "category": "Post Graduation"},
    {"code": "M.SC", "name": "M.Sc (Master of Science)", "category": "Post Graduation"},
    {"code": "M.COM", "name": "M.Com (Master of Commerce)", "category": "Post Graduation"},
    {"code": "MCA", "name": "MCA (Master of Computer Applications)", "category": "Post Graduation"},
    {"code": "MBA / PGDM", "name": "MBA / PGDM (Management)", "category": "Post Graduation"},
    {"code": "M.TECH", "name": "M.Tech / M.E (Engineering)", "category": "Post Graduation"},

    # Medical & Nursing
    {"code": "ANM", "name": "ANM (Auxiliary Nurse Midwife)", "category": "Medical & Nursing"},
    {"code": "GNM", "name": "GNM (General Nursing and Midwifery)", "category": "Medical & Nursing"},
    {"code": "B.SC NURSING", "name": "B.Sc Nursing", "category": "Medical & Nursing"},
    {"code": "B.PHARMA", "name": "B.Pharma (Bachelor of Pharmacy)", "category": "Medical & Nursing"},
    {"code": "MBBS", "name": "MBBS / Medical Degree", "category": "Medical & Nursing"},

    # Law & Accounts
    {"code": "LLB", "name": "LLB (Law Degree - 3 Year / 5 Year)", "category": "Law & Accounts"},
    {"code": "CA / ICWA", "name": "CA / ICWA / CMA (Chartered Accountant)", "category": "Law & Accounts"},

    # Skills & Others
    {"code": "POLICE / DEFENCE", "name": "Police / Constable / SI / Defence Interested", "category": "Defence & Skills"},
    {"code": "COMPUTER", "name": "Computer Operator / CCC / O-Level", "category": "Defence & Skills"},
    {"code": "TYPING", "name": "Typing Knowledge (Hindi / English)", "category": "Defence & Skills"},
    {"code": "STENOGRAPHER", "name": "Stenographer / Shorthand", "category": "Defence & Skills"}
]

@app.route("/api/qualifications-master", methods=["GET"])
def get_qualifications_master():
    return jsonify({"success": True, "qualifications": INDIAN_QUALIFICATIONS_MASTER})

# --- Authentication & Profile Endpoints ---

@app.route("/api/auth/register", methods=["POST"])
def register():
    data = request.json or {}
    name = data.get("name")
    email = data.get("email")
    password = data.get("password")
    highest_qualification = data.get("highest_qualification", "Graduate")
    qualifications = data.get("qualifications", ["GRADUATE"])
    custom_keywords = data.get("custom_keywords", [])
    state = data.get("state", "All India")

    ok, result = database.register_user(
        name=name,
        email=email,
        password=password,
        highest_qualification=highest_qualification,
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
        highest_qualification=data.get("highest_qualification"),
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
        "title": f"Test Alert: Sarkari Result Match for {user['name'] if user else 'Candidate'}",
        "matched_keywords": user_quals[:3],
        "last_date": "31/12/2026",
        "url": "https://www.sarkariresult.com"
    }
    results = notifier.dispatch_job_alert(sample_job, {"ntfy_topic": topic})
    return jsonify({"success": True, "results": results, "topic": topic})

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    print("==================================================")
    print(f"🚀 Sarkari Job Alert Multi-Portal Web App:")
    print(f"   http://localhost:{port}")
    print("==================================================")
    app.run(host="0.0.0.0", port=port, debug=False)

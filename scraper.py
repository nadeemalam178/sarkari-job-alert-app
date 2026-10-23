import re
import os
import sys
import requests
from bs4 import BeautifulSoup
from datetime import datetime
import database
import notifier

# Ensure stdout handles unicode smoothly on Windows consoles
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

# Accurate qualification regex rules without false positives
QUALIFICATION_RULES = {
    "10TH": [r"\b10th\b", r"\bclass\s*10\b", r"\bmatric(?:ulation)?\b", r"\bhigh\s*school\b"],
    "12TH / 10+2": [r"\b12th\b", r"\bclass\s*12\b", r"\b10\+2\b", r"\bintermediate\b", r"\bsenior\s*secondary\b"],
    "ITI": [r"\biti\b", r"\bindustrial\s*training\s*institute\b", r"\biti\s*certificate\b"],
    "DIPLOMA": [r"\bdiploma\b", r"\bpolytechnic\b"],
    "GRADUATE": [r"\bgraduate\b", r"\bgraduation\b", r"\bbachelor'?s?\s*degree\b", r"\bdegree\s*in\s*any\s*stream\b", r"\bb\.?a\.\b", r"\bb\.?sc\b", r"\bb\.?com\b"],
    "B.TECH / B.E": [r"\bb\.?\s*tech\b", r"\bb\.e\.\b", r"\bb\.e\b(?!\s*a\b)", r"\bbachelor\s*of\s*engineering\b", r"\bbachelor\s*of\s*technology\b"],
    "BCA": [r"\bbca\b", r"\bbachelor\s*of\s*computer\s*application\b"],
    "MCA": [r"\bmca\b", r"\bmaster\s*of\s*computer\s*application\b"],
    "POST GRADUATE": [r"\bpost\s*graduate\b", r"\bmaster'?s?\s*degree\b", r"\bm\.?a\.\b", r"\bm\.?sc\b", r"\bm\.?com\b", r"\bm\.?\s*tech\b", r"\bmba\b"],
    "B.ED": [r"\bb\.?\s*ed\b", r"\bbachelor\s*of\s*education\b"],
    "D.EL.ED / BTC": [r"\bd\.?\s*el\.?\s*ed\b", r"\bbtc\b", r"\bdiploma\s*in\s*elementary\s*education\b"],
    "CTET": [r"\bctet\b", r"\bcentral\s*teacher\s*eligibility\s*test\b"],
    "STET": [r"\bstet\b", r"\bstate\s*teacher\s*eligibility\s*test\b"],
    "TEACHER": [r"\bteacher\b", r"\bprt\b", r"\btgt\b", r"\bpgt\b", r"\blecturer\b", r"\bprofessor\b"],
    "NURSING / MEDICAL": [r"\banm\b", r"\bgnm\b", r"\bnursing\b", r"\bmbbs\b", r"\bparamedical\b"],
    "POLICE / DEFENCE": [r"\bpolice\b", r"\bconstable\b", r"\bsub\s*inspector\b", r"\barmy\b", r"\bnavy\b", r"\bairforce\b", r"\bagniveer\b"],
    "COMPUTER": [r"\bcomputer\b", r"\bdata\s*entry\b", r"\bdeo\b", r"\bsoftware\b", r"\bprogrammer\b"]
}

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.9,hi;q=0.8"
}

def extract_qualifications_from_text(text):
    """Returns all standard qualifications found in text"""
    found = []
    text_lower = text.lower()
    for category, patterns in QUALIFICATION_RULES.items():
        for pat in patterns:
            if re.search(pat, text_lower):
                found.append(category)
                break
    return list(dict.fromkeys(found))

def match_user_qualifications(found_qualifications, text, selected_quals, custom_keywords):
    """
    Matches extracted qualifications and custom keywords against user preferences.
    """
    matched = []
    text_lower = text.lower()

    # 1. Check selected categories
    for qual in selected_quals:
        # Match normalized names (e.g. 'B.ED', 'CTET', 'GRADUATE')
        for f in found_qualifications:
            if qual.upper() in f.upper() or f.upper() in qual.upper():
                matched.append(f)
                break

    # 2. Check custom user keywords
    for kw in custom_keywords:
        kw_clean = kw.strip().lower()
        if kw_clean and (kw_clean in text_lower or re.search(rf"\b{re.escape(kw_clean)}\b", text_lower)):
            matched.append(kw.upper())

    return list(dict.fromkeys(matched))

def scrape_latest_jobs(limit=25):
    """
    Fetches the latest job links from Sarkari Result.
    Uses cached URLs to only fetch details for newly added posts.
    """
    url = "https://www.sarkariresult.com/latestjob/"
    try:
        res = requests.get(url, headers=HEADERS, timeout=12)
        if res.status_code != 200:
            print(f"[Scraper] Failed to fetch latest jobs. Status: {res.status_code}")
            return []
        
        soup = BeautifulSoup(res.text, "html.parser")
        job_links = []
        
        # Sarkari Result jobs are in #post or table or post lists
        for a in soup.find_all("a", href=True):
            href = a["href"].strip()
            title = a.get_text(strip=True)
            if not href.startswith("http"):
                continue
            # Ensure it's a job post url on sarkariresult.com
            if "sarkariresult.com/20" in href or "sarkariresult.com/latest" not in href:
                if any(k in title.lower() for k in ["apply", "online", "form", "recruitment", "vacancy", "post", "bharti", "202"]):
                    # Clean title
                    title = re.sub(r'\s+', ' ', title).strip()
                    if title and len(title) > 8:
                        job_links.append({"url": href, "title": title})

        # Deduplicate
        seen_hrefs = set()
        unique_jobs = []
        for j in job_links:
            if j["url"] not in seen_hrefs:
                seen_hrefs.add(j["url"])
                unique_jobs.append(j)

        return unique_jobs[:limit]
    except Exception as e:
        print("[Scraper] Error fetching list:", e)
        return []

def parse_job_detail_page(job_url):
    """
    Visits the job page, extracts last date, organization, and eligibility details.
    """
    try:
        res = requests.get(job_url, headers=HEADERS, timeout=10)
        if res.status_code != 200:
            return None
        soup = BeautifulSoup(res.text, "html.parser")

        # 1. Extract Last Date
        last_date = ""
        date_match = re.search(r"Last Date\s*(?:for Apply Online)?\s*:\s*(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})", soup.get_text(), re.I)
        if date_match:
            last_date = date_match.group(1)
        else:
            dm2 = re.search(r"(\d{1,2}/\d{1,2}/202\d)", soup.get_text())
            if dm2:
                last_date = dm2.group(1)

        # 2. Extract Organization / Board
        org = ""
        h1 = soup.find("h1")
        if h1:
            org = h1.get_text(strip=True)
        if not org:
            h2 = soup.find("h2")
            if h2:
                org = h2.get_text(strip=True)

        # 3. Extract Eligibility / Qualification Section
        page_text = soup.get_text(separator=" ", strip=True)
        eligibility_snippet = ""

        # Search for table rows or text containing eligibility
        for tr in soup.find_all("tr"):
            row_text = tr.get_text(" ", strip=True)
            if any(w in row_text.lower() for w in ["eligibility", "qualification", "passed", "degree", "diploma", "b.ed", "ctet"]):
                if len(row_text) > 25 and len(row_text) < 600:
                    eligibility_snippet += row_text + " | "

        if not eligibility_snippet:
            # Fallback to text matching
            match = re.search(r"(?:Eligibility|Qualification|Educational Qualification)[^.\n]{20,400}", page_text, re.I)
            if match:
                eligibility_snippet = match.group(0)

        # Clean snippet
        eligibility_snippet = re.sub(r'\s+', ' ', eligibility_snippet).strip()[:800]
        if not eligibility_snippet:
            eligibility_snippet = "See official notification on Sarkari Result for detailed eligibility criteria."

        # Detect all qualifications present in full page
        found_quals = extract_qualifications_from_text(page_text)

        return {
            "last_date": last_date or "Check Notification",
            "org": org[:150],
            "eligibility_snippet": eligibility_snippet,
            "qualifications_found": found_quals,
            "full_text": page_text
        }
    except Exception as e:
        print(f"[Scraper] Failed parsing detail page {job_url}: {e}")
        return None

def run_scrape_cycle(max_new_jobs=15):
    """
    Executes a complete scrape cycle:
    1. Checks latest job listings
    2. Skips already seen URLs (saving network bandwidth & tokens)
    3. Fetches details for new jobs
    4. Evaluates against user qualification settings
    5. Dispatches notifications for new matching jobs
    6. Updates SQLite and exports to jobs.json
    """
    settings = database.get_settings()
    selected_quals = settings.get("selected_qualifications", [])
    custom_keywords = settings.get("custom_keywords", [])
    seen_urls = database.get_seen_urls()

    print(f"[Scraper] Starting scrape cycle. Seen URLs in DB: {len(seen_urls)}")
    latest_links = scrape_latest_jobs(limit=30)
    print(f"[Scraper] Retrieved {len(latest_links)} job links from Sarkari Result")

    new_jobs_processed = 0
    new_matches = []

    for item in latest_links:
        url = item["url"]
        title = item["title"]

        if url in seen_urls:
            continue

        print(f"[Scraper] New job detected: {title}")
        details = parse_job_detail_page(url)
        if not details:
            continue

        # Check match with user preferences
        matched_kw = match_user_qualifications(
            details["qualifications_found"],
            details["full_text"],
            selected_quals,
            custom_keywords
        )
        is_matched = len(matched_kw) > 0

        job_record = {
            "url": url,
            "title": title,
            "org": details["org"],
            "last_date": details["last_date"],
            "eligibility_snippet": details["eligibility_snippet"],
            "qualifications_found": details["qualifications_found"],
            "matched_keywords": matched_kw,
            "is_matched": is_matched,
            "scraped_at": datetime.now().strftime("%Y-%m-%d %H:%M"),
            "notified": 0
        }

        # Send alert if matched
        if is_matched:
            print(f"  🎯 MATCH FOUND: {matched_kw} for {title}")
            notifier.dispatch_job_alert(job_record, settings)
            job_record["notified"] = 1
            new_matches.append(job_record)

        # Save to database
        database.save_job(job_record)
        seen_urls.add(url)
        new_jobs_processed += 1

        if new_jobs_processed >= max_new_jobs:
            break

    # Export to jobs.json for static & Vercel deployment
    database.sync_db_to_json()

    # Update settings stats
    settings["last_checked_at"] = datetime.now().strftime("%d %b %Y, %I:%M %p")
    database.save_settings(settings)

    print(f"[Scraper] Finished. Processed {new_jobs_processed} new jobs. Matches: {len(new_matches)}")
    return {
        "new_jobs_processed": new_jobs_processed,
        "new_matches": len(new_matches),
        "matches": new_matches
    }

def rematch_all_cached_jobs():
    """
    Re-evaluates already cached jobs against newly saved qualifications.
    Zero network requests needed!
    """
    settings = database.get_settings()
    selected_quals = settings.get("selected_qualifications", [])
    custom_keywords = settings.get("custom_keywords", [])

    jobs = database.get_all_jobs(matched_only=False, limit=500)
    matched_count = 0

    for j in jobs:
        qual_found = j.get("qualifications_found", [])
        snippet = j.get("eligibility_snippet", "") + " " + j.get("title", "")
        matched_kw = match_user_qualifications(qual_found, snippet, selected_quals, custom_keywords)
        is_matched = len(matched_kw) > 0

        j["matched_keywords"] = matched_kw
        j["is_matched"] = is_matched
        database.save_job(j)
        if is_matched:
            matched_count += 1

    database.sync_db_to_json()
    return matched_count

if __name__ == "__main__":
    print("Testing initial scraper run (up to 5 new jobs)...")
    result = run_scrape_cycle(max_new_jobs=5)
    print("Result:", result)

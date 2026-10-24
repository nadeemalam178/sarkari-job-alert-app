import re
import os
import sys
import requests
from bs4 import BeautifulSoup
from datetime import datetime
import database
import notifier

# Ensure unicode stdout for Windows
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

# Comprehensive Indian qualification regex rules
QUALIFICATION_RULES = {
    "10TH": [r"\b10th\b", r"\bclass\s*10\b", r"\bmatric(?:ulation)?\b", r"\bhigh\s*school\b", r"\b7th\b", r"\b8th\b"],
    "12TH / 10+2": [r"\b12th\b", r"\bclass\s*12\b", r"\b10\+2\b", r"\bintermediate\b", r"\bsenior\s*secondary\b"],
    "ITI": [r"\biti\b", r"\bindustrial\s*training\s*institute\b", r"\biti\s*certificate\b"],
    "DIPLOMA": [r"\bdiploma\b", r"\bpolytechnic\b", r"\bd\.?pharm\b"],
    "GRADUATE": [r"\bgraduate\b", r"\bgraduation\b", r"\bbachelor'?s?\s*degree\b", r"\bany\s*graduate\b", r"\bdegree\s*in\s*any\s*stream\b", r"\bb\.?a\.\b", r"\bb\.?sc\b", r"\bb\.?com\b", r"\bb\.?pharma\b", r"\bca\b"],
    "B.TECH / B.E": [r"\bb\.?\s*tech\b", r"\bb\.e\.\b", r"\bb\.e\b(?!\s*a\b)", r"\bbachelor\s*of\s*engineering\b", r"\bbachelor\s*of\s*technology\b"],
    "BCA": [r"\bbca\b", r"\bbachelor\s*of\s*computer\s*application\b"],
    "MCA": [r"\bmca\b", r"\bmaster\s*of\s*computer\s*application\b"],
    "POST GRADUATE": [r"\bpost\s*graduate\b", r"\bany\s*post\s*graduate\b", r"\bmaster'?s?\s*degree\b", r"\bm\.?a\.\b", r"\bm\.?sc\b", r"\bm\.?com\b", r"\bm\.?\s*tech\b", r"\bmba\b", r"\bpgdm\b"],
    "B.ED": [r"\bb\.?\s*ed\b", r"\bbachelor\s*of\s*education\b"],
    "D.EL.ED / BTC": [r"\bd\.?\s*el\.?\s*ed\b", r"\bbtc\b", r"\bdiploma\s*in\s*elementary\s*education\b"],
    "CTET": [r"\bctet\b", r"\bcentral\s*teacher\s*eligibility\s*test\b"],
    "STET": [r"\bstet\b", r"\bstate\s*teacher\s*eligibility\s*test\b"],
    "TEACHER": [r"\bteacher\b", r"\bprt\b", r"\btgt\b", r"\bpgt\b", r"\blecturer\b", r"\bprofessor\b", r"\bfaculty\b"],
    "NURSING / MEDICAL": [r"\banm\b", r"\bgnm\b", r"\bnursing\b", r"\bpharmacist\b", r"\bmbbs\b", r"\bparamedical\b"],
    "POLICE / DEFENCE": [r"\bpolice\b", r"\bconstable\b", r"\bsub\s*inspector\b", r"\barmy\b", r"\bnavy\b", r"\bairforce\b", r"\bagniveer\b"],
    "COMPUTER": [r"\bcomputer\b", r"\bdata\s*entry\b", r"\bdeo\b", r"\bsoftware\b", r"\bprogrammer\b", r"\bciso\b"]
}

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.9,hi;q=0.8"
}

def extract_qualifications_from_text(text):
    found = []
    text_lower = text.lower()
    for category, patterns in QUALIFICATION_RULES.items():
        for pat in patterns:
            if re.search(pat, text_lower):
                found.append(category)
                break
    return list(dict.fromkeys(found))

def match_user_qualifications(found_qualifications, text, selected_quals, custom_keywords=None):
    matched = []
    text_lower = text.lower()

    for qual in selected_quals or []:
        for f in found_qualifications:
            if qual.upper() in f.upper() or f.upper() in qual.upper():
                matched.append(f)
                break

    for kw in custom_keywords or []:
        kw_clean = kw.strip().lower()
        if kw_clean and (kw_clean in text_lower or re.search(rf"\b{re.escape(kw_clean)}\b", text_lower)):
            matched.append(kw.upper())

    return list(dict.fromkeys(matched))

# --- Source 1: Sarkari Result ---
def scrape_sarkari_result(limit=15):
    url = "https://www.sarkariresult.com/latestjob/"
    jobs = []
    try:
        res = requests.get(url, headers=HEADERS, timeout=10)
        if res.status_code != 200:
            return []
        soup = BeautifulSoup(res.text, "html.parser")
        seen_urls = set()
        
        for a in soup.find_all("a", href=True):
            href = a["href"].strip()
            title = a.get_text(strip=True)
            if not href.startswith("http") or href in seen_urls:
                continue
            if "sarkariresult.com/20" in href or "sarkariresult.com/latest" not in href:
                if any(k in title.lower() for k in ["apply", "online", "form", "recruitment", "vacancy", "post", "bharti", "202"]):
                    title = re.sub(r'\s+', ' ', title).strip()
                    if len(title) > 8:
                        seen_urls.add(href)
                        jobs.append({"url": href, "title": title, "source": "SarkariResult"})
                        if len(jobs) >= limit:
                            break
    except Exception as e:
        print("[Scraper] SarkariResult error:", e)
    return jobs

def parse_sarkari_detail(job_url):
    try:
        res = requests.get(job_url, headers=HEADERS, timeout=10)
        if res.status_code != 200:
            return None
        soup = BeautifulSoup(res.text, "html.parser")

        # Extract Last Date
        last_date = ""
        date_match = re.search(r"Last Date\s*(?:for Apply Online)?\s*:\s*(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})", soup.get_text(), re.I)
        if date_match:
            last_date = date_match.group(1)
        else:
            dm2 = re.search(r"(\d{1,2}/\d{1,2}/202\d)", soup.get_text())
            if dm2:
                last_date = dm2.group(1)

        # Organization
        org = ""
        h1 = soup.find("h1") or soup.find("h2")
        if h1:
            org = h1.get_text(strip=True)

        page_text = soup.get_text(separator=" ", strip=True)
        snippet = ""
        for tr in soup.find_all("tr"):
            row_text = tr.get_text(" ", strip=True)
            if any(w in row_text.lower() for w in ["eligibility", "qualification", "passed", "degree", "diploma", "b.ed", "ctet"]):
                if 25 < len(row_text) < 600:
                    snippet += row_text + " | "

        if not snippet:
            match = re.search(r"(?:Eligibility|Qualification|Educational Qualification)[^.\n]{20,400}", page_text, re.I)
            if match:
                snippet = match.group(0)

        snippet = re.sub(r'\s+', ' ', snippet).strip()[:800]
        if not snippet:
            snippet = "Refer to the official notification link for full eligibility details."

        found_quals = extract_qualifications_from_text(page_text)
        return {
            "last_date": last_date or "Check Notification",
            "org": org[:150],
            "eligibility_snippet": snippet,
            "qualifications_found": found_quals,
            "full_text": page_text
        }
    except Exception as e:
        print(f"[Scraper] Failed parsing detail page {job_url}: {e}")
        return None

# --- Source 2: FreeJobAlert ---
def scrape_freejobalert(limit=15):
    url = "https://www.freejobalert.com/latest-notifications/"
    jobs = []
    try:
        res = requests.get(url, headers=HEADERS, timeout=10)
        if res.status_code != 200:
            return []
        soup = BeautifulSoup(res.text, "html.parser")

        for tr in soup.find_all("tr"):
            tds = tr.find_all("td")
            if len(tds) >= 6:
                post_date = tds[0].get_text(strip=True)
                org = tds[1].get_text(" ", strip=True)
                post_name = tds[2].get_text(" ", strip=True)
                raw_qual = tds[3].get_text(" ", strip=True)
                last_date = tds[5].get_text(strip=True)

                a = tr.find("a", href=True)
                if not a or not a["href"].startswith("http"):
                    continue

                href = a["href"].strip()
                title = f"{org} - {post_name}"
                title = re.sub(r'\s+', ' ', title).strip()

                found_quals = extract_qualifications_from_text(raw_qual + " " + post_name)
                jobs.append({
                    "url": href,
                    "title": title,
                    "org": org[:120],
                    "last_date": last_date or "Check Notification",
                    "eligibility_snippet": f"Qualification: {raw_qual} | Post Date: {post_date}",
                    "qualifications_found": found_quals,
                    "full_text": f"{title} {org} {raw_qual} {post_name}",
                    "source": "FreeJobAlert"
                })
                if len(jobs) >= limit:
                    break
    except Exception as e:
        print("[Scraper] FreeJobAlert error:", e)
    return jobs

# --- Source 3: Rojgar Result ---
def scrape_rojgar_result(limit=15):
    url = "https://www.rojgarresult.com/"
    jobs = []
    try:
        res = requests.get(url, headers=HEADERS, timeout=10)
        if res.status_code != 200:
            return []
        soup = BeautifulSoup(res.text, "html.parser")
        seen = set()

        for a in soup.find_all("a", href=True):
            href = a["href"].strip()
            title = a.get_text(strip=True)
            if not href.startswith("http") or href in seen:
                continue
            if any(k in title.lower() for k in ["online form", "apply now", "recruitment", "vacancy", "bharti", "202"]):
                clean_title = re.sub(r'\s+', ' ', title).strip()
                if len(clean_title) > 10:
                    seen.add(href)
                    found_quals = extract_qualifications_from_text(clean_title)
                    jobs.append({
                        "url": href,
                        "title": clean_title,
                        "source": "RojgarResult",
                        "found_quals_pre": found_quals
                    })
                    if len(jobs) >= limit:
                        break
    except Exception as e:
        print("[Scraper] RojgarResult error:", e)
    return jobs

def parse_rojgar_detail(job_url, pre_title, pre_quals):
    try:
        res = requests.get(job_url, headers=HEADERS, timeout=10)
        if res.status_code != 200:
            return None
        soup = BeautifulSoup(res.text, "html.parser")
        text = soup.get_text(separator=" ", strip=True)

        last_date = ""
        dm = re.search(r"Last Date\s*(?:for Apply Online)?\s*:\s*(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})", text, re.I)
        if dm:
            last_date = dm.group(1)

        org = ""
        h1 = soup.find("h1") or soup.find("h2")
        if h1:
            org = h1.get_text(strip=True)

        found_quals = list(dict.fromkeys(pre_quals + extract_qualifications_from_text(text)))
        snippet = ""
        match = re.search(r"(?:Eligibility|Qualification)[^.\n]{20,400}", text, re.I)
        if match:
            snippet = match.group(0)
        else:
            snippet = f"Check advertisement on RojgarResult for {pre_title}."

        return {
            "last_date": last_date or "Check Notification",
            "org": org[:120],
            "eligibility_snippet": snippet[:500],
            "qualifications_found": found_quals,
            "full_text": text
        }
    except Exception as e:
        print(f"[Scraper] Rojgar detail failed {job_url}: {e}")
        return None

# --- Unified Multi-Source Scrape Cycle ---
def run_scrape_cycle(max_per_source=10):
    seen_urls = database.get_seen_urls()
    print(f"[MultiScraper] Starting multi-source scrape. Seen URLs: {len(seen_urls)}")

    all_users = database.get_all_users_for_notifications()
    print(f"[MultiScraper] Registered users for alerts: {len(all_users)}")

    new_jobs_added = 0
    new_matches = []

    # 1. Fetch from Sarkari Result
    sr_links = scrape_sarkari_result(limit=max_per_source)
    for item in sr_links:
        url = item["url"]
        if url in seen_urls:
            continue
        details = parse_sarkari_detail(url)
        if details:
            job_record = {
                "source": "SarkariResult",
                "url": url,
                "title": item["title"],
                "org": details["org"],
                "last_date": details["last_date"],
                "eligibility_snippet": details["eligibility_snippet"],
                "qualifications_found": details["qualifications_found"],
                "matched_keywords": [],
                "is_matched": len(details["qualifications_found"]) > 0,
                "scraped_at": datetime.now().strftime("%Y-%m-%d %H:%M"),
                "notified": 0
            }
            database.save_job(job_record)
            seen_urls.add(url)
            new_jobs_added += 1
            _notify_matching_users(job_record, details["full_text"], all_users)

    # 2. Fetch from FreeJobAlert
    fja_jobs = scrape_freejobalert(limit=max_per_source)
    for j in fja_jobs:
        url = j["url"]
        if url in seen_urls:
            continue
        job_record = {
            "source": "FreeJobAlert",
            "url": url,
            "title": j["title"],
            "org": j["org"],
            "last_date": j["last_date"],
            "eligibility_snippet": j["eligibility_snippet"],
            "qualifications_found": j["qualifications_found"],
            "matched_keywords": [],
            "is_matched": len(j["qualifications_found"]) > 0,
            "scraped_at": datetime.now().strftime("%Y-%m-%d %H:%M"),
            "notified": 0
        }
        database.save_job(job_record)
        seen_urls.add(url)
        new_jobs_added += 1
        _notify_matching_users(job_record, j["full_text"], all_users)

    # 3. Fetch from Rojgar Result
    rr_links = scrape_rojgar_result(limit=max_per_source)
    for item in rr_links:
        url = item["url"]
        if url in seen_urls:
            continue
        details = parse_rojgar_detail(url, item["title"], item.get("found_quals_pre", []))
        if details:
            job_record = {
                "source": "RojgarResult",
                "url": url,
                "title": item["title"],
                "org": details["org"],
                "last_date": details["last_date"],
                "eligibility_snippet": details["eligibility_snippet"],
                "qualifications_found": details["qualifications_found"],
                "matched_keywords": [],
                "is_matched": len(details["qualifications_found"]) > 0,
                "scraped_at": datetime.now().strftime("%Y-%m-%d %H:%M"),
                "notified": 0
            }
            database.save_job(job_record)
            seen_urls.add(url)
            new_jobs_added += 1
            _notify_matching_users(job_record, details["full_text"], all_users)

    database.sync_db_to_json()
    print(f"[MultiScraper] Finished. Added {new_jobs_added} new jobs across all sources.")
    return {"new_jobs_processed": new_jobs_added}

def _notify_matching_users(job_record, full_text, all_users):
    """Checks every registered user and notifies if this job matches their qualifications"""
    quals_found = job_record.get("qualifications_found", [])
    for user in all_users:
        user_quals = user.get("qualifications", [])
        user_kw = user.get("custom_keywords", [])
        matched = match_user_qualifications(quals_found, full_text, user_quals, user_kw)
        if matched and user.get("ntfy_topic"):
            user_job_copy = dict(job_record)
            user_job_copy["matched_keywords"] = matched
            notifier.dispatch_job_alert(user_job_copy, {"ntfy_topic": user["ntfy_topic"]})

def rematch_all_cached_jobs():
    return database.sync_db_to_json()

if __name__ == "__main__":
    print("Testing multi-source scraper...")
    res = run_scrape_cycle(max_per_source=3)
    print("Scrape result:", res)

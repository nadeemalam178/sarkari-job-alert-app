import re
import os
import sys
import requests
from bs4 import BeautifulSoup
from datetime import datetime
import database
import notifier

# Ensure unicode stdout for Windows consoles
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

# Comprehensive Indian Qualification Mapping (Hierarchy & Specific Streams)
QUALIFICATION_RULES = {
    # School Level
    "8TH": [r"\b8th\b", r"\bclass\s*8\b", r"\beighth\s*pass\b"],
    "10TH": [r"\b10th\b", r"\bclass\s*10\b", r"\bmatric(?:ulation)?\b", r"\bhigh\s*school\b"],
    "12TH / 10+2": [r"\b12th\b", r"\bclass\s*12\b", r"\b10\+2\b", r"\bintermediate\b", r"\bsenior\s*secondary\b"],
    "12TH PCM": [r"\b12th.*?(?:math|physics|pcm)\b", r"\bintermediate.*?(?:math|pcm)\b", r"\b10\+2.*?(?:math|pcm)\b"],
    "12TH PCB": [r"\b12th.*?(?:bio|pcb|science)\b", r"\bintermediate.*?(?:bio|pcb)\b"],
    "12TH COMMERCE": [r"\b12th.*?commerce\b", r"\bintermediate.*?commerce\b"],

    # ITI Trades
    "ITI": [r"\biti\b", r"\bindustrial\s*training\s*institute\b", r"\biti\s*certificate\b"],
    "ITI FITTER": [r"\biti.*?fitter\b", r"\bfitter\s*trade\b"],
    "ITI ELECTRICIAN": [r"\biti.*?electrician\b", r"\belectrician\s*trade\b"],
    "ITI WELDER": [r"\biti.*?welder\b", r"\bwelder\b"],
    "ITI COPA": [r"\bcopa\b", r"\bcomputer\s*operator\s*and\s*programming\s*assistant\b"],

    # Polytechnic & Diploma
    "DIPLOMA": [r"\bdiploma\b", r"\bpolytechnic\b"],
    "DIPLOMA CIVIL": [r"\bdiploma.*?civil\b", r"\bpolytechnic.*?civil\b"],
    "DIPLOMA MECHANICAL": [r"\bdiploma.*?mech\b", r"\bpolytechnic.*?mech\b"],
    "DIPLOMA ELECTRICAL": [r"\bdiploma.*?electr\b", r"\bpolytechnic.*?electr\b"],
    "D.PHARMA": [r"\bd\.?\s*pharm(?:a|acy)?\b", r"\bdiploma\s*in\s*pharmacy\b"],

    # Teaching Degrees (Teacher Recruitment)
    "B.ED": [r"\bb\.?\s*ed\b", r"\bbachelor\s*of\s*education\b"],
    "D.EL.ED / BTC": [r"\bd\.?\s*el\.?\s*ed\b", r"\bbtc\b", r"\bdiploma\s*in\s*elementary\s*education\b"],
    "CTET": [r"\bctet\b", r"\bcentral\s*teacher\s*eligibility\s*test\b"],
    "CTET PAPER 1": [r"\bctet.*?paper\s*[-–]?\s*i\b", r"\bctet.*?(?:primary|1\s*to\s*5)\b"],
    "CTET PAPER 2": [r"\bctet.*?paper\s*[-–]?\s*ii\b", r"\bctet.*?(?:upper|6\s*to\s*8)\b"],
    "STET": [r"\bstet\b", r"\bstate\s*teacher\s*eligibility\s*test\b"],
    "TEACHER": [r"\bteacher\b", r"\bprt\b", r"\btgt\b", r"\bpgt\b", r"\bheadmaster\b", r"\bprincipal\b", r"\blecturer\b", r"\bprofessor\b", r"\bfaculty\b", r"\beducator\b"],
    "NTT": [r"\bntt\b", r"\bnursery\s*teacher\b"],

    # Graduation (Bachelor Degrees)
    "GRADUATE": [r"\bgraduate\b", r"\bgraduation\b", r"\bbachelor'?s?\s*degree\b", r"\bany\s*graduate\b", r"\bdegree\s*in\s*any\s*stream\b", r"\bdegree\s*from\s*any\s*recognized\b"],
    "BA": [r"\bb\.?a\.\b", r"\bbachelor\s*of\s*arts\b"],
    "B.SC": [r"\bb\.?sc\b", r"\bbachelor\s*of\s*science\b"],
    "B.COM": [r"\bb\.?com\b", r"\bbachelor\s*of\s*commerce\b"],
    "BBA": [r"\bbba\b", r"\bbachelor\s*of\s*business\b"],
    "BCA": [r"\bbca\b", r"\bbachelor\s*of\s*computer\s*application\b"],
    "B.LIB": [r"\bb\.?\s*lib\b", r"\blibrary\s*science\b"],

    # Engineering Degrees (B.Tech / B.E)
    "B.TECH / B.E": [r"\bb\.?\s*tech\b", r"\bb\.e\.\b", r"\bb\.e\b(?!\s*a\b)", r"\bbachelor\s*of\s*engineering\b", r"\bbachelor\s*of\s*technology\b", r"\bengineering\s*degree\b"],
    "B.TECH CIVIL": [r"\bb\.?tech.*?civil\b", r"\bb\.?e.*?civil\b"],
    "B.TECH MECHANICAL": [r"\bb\.?tech.*?mech\b", r"\bb\.?e.*?mech\b"],
    "B.TECH ELECTRICAL": [r"\bb\.?tech.*?electr\b", r"\bb\.?e.*?electr\b"],
    "B.TECH CS / IT": [r"\bb\.?tech.*?(?:cs|computer|it)\b", r"\bb\.?e.*?(?:cs|computer|it)\b"],

    # Medical, Nursing & Pharmacy
    "ANM": [r"\banm\b", r"\bauxiliary\s*nurse\b"],
    "GNM": [r"\bgnm\b", r"\bgeneral\s*nursing\b"],
    "B.SC NURSING": [r"\bb\.?sc\s*nursing\b"],
    "B.PHARMA": [r"\bb\.?\s*pharm(?:a|acy)?\b", r"\bbachelor\s*of\s*pharmacy\b"],
    "MBBS": [r"\bmbbs\b", r"\bmedical\s*degree\b"],

    # Post Graduate (Master Degrees)
    "POST GRADUATE": [r"\bpost\s*graduate\b", r"\bany\s*post\s*graduate\b", r"\bmaster'?s?\s*degree\b", r"\bpg\s*degree\b"],
    "MA": [r"\bm\.?a\.\b", r"\bmaster\s*of\s*arts\b"],
    "M.SC": [r"\bm\.?sc\b", r"\bmaster\s*of\s*science\b"],
    "M.COM": [r"\bm\.?com\b", r"\bmaster\s*of\s*commerce\b"],
    "MCA": [r"\bmca\b", r"\bmaster\s*of\s*computer\s*application\b"],
    "MBA / PGDM": [r"\bmba\b", r"\bpgdm\b", r"\bmaster\s*of\s*business\b"],
    "M.TECH": [r"\bm\.?\s*tech\b", r"\bmaster\s*of\s*technology\b"],

    # Law & Accounts
    "LLB": [r"\bllb\b", r"\blaw\s*degree\b", r"\bbachelor\s*of\s*law\b"],
    "CA / ICWA": [r"\bca\b", r"\bchartered\s*accountant\b", r"\bicwa\b", r"\bcma\b"],

    # Special Skills
    "TYPING": [r"\btyping\b", r"\bwpm\b", r"\bdata\s*entry\b", r"\bdeo\b"],
    "STENOGRAPHER": [r"\bstenographer\b", r"\bsteno\b", r"\bshorthand\b"],
    "POLICE / DEFENCE": [r"\bpolice\b", r"\bconstable\b", r"\bsub\s*inspector\b", r"\bsi\b", r"\barmy\b", r"\bnavy\b", r"\bairforce\b", r"\bagniveer\b"],
    "COMPUTER": [r"\bcomputer\b", r"\bccc\b", r"\bo\s*level\b", r"\bit\b", r"\bsoftware\b", r"\bprogrammer\b"]
}

# Strict Blacklist: Drop any item that is NOT an active recruitment/job!
NON_JOB_EXCLUSION_KEYWORDS = [
    r"\bresult\b", r"\badmit\s*card\b", r"\banswer\s*key\b", r"\bscore\s*card\b",
    r"\ballotment\b", r"\bmerit\s*list\b", r"\bcounselling\b", r"\bscholarship\b",
    r"\badmission\b", r"\bsyllabus\b", r"\bcertificate\b", r"\bpostponed\b",
    r"\bexam\s*date\b", r"\bexam\s*city\b", r"\bcutoff\b", r"\bcut-off\b"
]

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.9,hi;q=0.8"
}

def is_non_job(title):
    """Returns True if title is an admit card, result, syllabus, or scholarship (NOT a vacancy)"""
    title_lower = title.lower()
    for pat in NON_JOB_EXCLUSION_KEYWORDS:
        if re.search(pat, title_lower):
            return True
    return False

def normalize_title_for_dedup(title, org=""):
    """Creates a normalized semantic key to identify duplicate postings across portals"""
    combined = f"{org} {title}".lower()
    combined = re.sub(r'202\d', '', combined)
    combined = re.sub(r'\b(online\s*form|recruitment|bharti|vacancy|notification|apply\s*online|latest|posts?|exam|advertisement|details|direct)\b', '', combined, flags=re.I)
    words = re.findall(r'[a-z]{3,}', combined)
    stop = {'for', 'and', 'the', 'with', 'various', 'main', 'level', 'trade', 'check', 'view', 'now', 'date', 'last'}
    key_words = sorted(list(set(w for w in words if w not in stop)))
    return " ".join(key_words)

def are_titles_duplicate(key1, key2):
    s1, s2 = set(key1.split()), set(key2.split())
    if not s1 or not s2:
        return False
    intersection = s1.intersection(s2)
    min_len = min(len(s1), len(s2))
    if min_len == 0:
        return False
    similarity = len(intersection) / min_len
    return similarity >= 0.70

def extract_qualifications_from_text(text):
    found = []
    text_lower = text.lower()
    for category, patterns in QUALIFICATION_RULES.items():
        for pat in patterns:
            if re.search(pat, text_lower):
                found.append(category)
                break
    return list(dict.fromkeys(found))

# --- Scraper 1: Sarkari Result (HIGHEST PRIORITY) ---
def scrape_sarkari_result(limit=20):
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
                title_clean = re.sub(r'\s+', ' ', title).strip()
                if len(title_clean) > 8:
                    if is_non_job(title_clean):
                        continue
                    if any(k in title_clean.lower() for k in ["apply", "online", "form", "recruitment", "vacancy", "post", "bharti", "202"]):
                        seen_urls.add(href)
                        jobs.append({"url": href, "title": title_clean, "source": "SarkariResult"})
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
            if any(w in row_text.lower() for w in ["eligibility", "qualification", "passed", "degree", "diploma", "b.ed", "ctet", "graduate"]):
                if 25 < len(row_text) < 600:
                    snippet += row_text + " | "

        if not snippet:
            match = re.search(r"(?:Eligibility|Qualification|Educational Qualification)[^.\n]{20,400}", page_text, re.I)
            if match:
                snippet = match.group(0)

        snippet = re.sub(r'\s+', ' ', snippet).strip()[:800]
        if not snippet:
            snippet = "Refer to the official Sarkari Result notification link for full eligibility details."

        found_quals = extract_qualifications_from_text(page_text)
        return {
            "last_date": last_date or "Check Notification",
            "org": org[:150],
            "eligibility_snippet": snippet,
            "qualifications_found": found_quals,
            "full_text": page_text
        }
    except Exception as e:
        print(f"[Scraper] Failed parsing Sarkari detail {job_url}: {e}")
        return None

# --- Scraper 2: FreeJobAlert ---
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

                title = f"{org} - {post_name}"
                title = re.sub(r'\s+', ' ', title).strip()
                if is_non_job(title) or is_non_job(post_name):
                    continue

                a = tr.find("a", href=True)
                if not a or not a["href"].startswith("http"):
                    continue

                href = a["href"].strip()
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

# --- Scraper 3: Rojgar Result ---
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

            clean_title = re.sub(r'\s+', ' ', title).strip()
            # Strictly filter out Admit Card, Results, Scholarships
            if is_non_job(clean_title):
                continue

            if any(k in clean_title.lower() for k in ["online form", "apply now", "recruitment", "vacancy", "bharti", "202"]):
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

        if is_non_job(text[:400]):
            return None

        last_date = ""
        dm = re.search(r"Last Date\s*(?:for Apply Online)?\s*:\s*(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})", text, re.I)
        if dm:
            last_date = dm.group(1)

        org = ""
        h1 = soup.find("h1") or soup.find("h2")
        if h1:
            org = h1.get_text(strip=True)

        found_quals = list(dict.fromkeys(pre_quals + extract_qualifications_from_text(text)))
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

# --- Unified Deduplicated Scrape Cycle with Sarkari Result Priority ---
def run_scrape_cycle(max_per_source=12):
    seen_urls = database.get_seen_urls()
    print(f"[MultiScraper] Starting cycle. Existing URLs: {len(seen_urls)}")

    all_users = database.get_all_users_for_notifications()
    new_jobs_added = 0

    # Cache normalized keys of all existing jobs in DB to prevent duplicates across portals
    existing_jobs = database.get_all_jobs(limit=500)
    existing_keys = []
    for ej in existing_jobs:
        k = normalize_job_key(ej["title"], ej.get("org", ""))
        existing_keys.append({"key": k, "source": ej.get("source", "SarkariResult"), "id": ej["id"]})

    # 1. PRIMARY SOURCE: Sarkari Result (Always preferred!)
    sr_links = scrape_sarkari_result(limit=max_per_source)
    for item in sr_links:
        url = item["url"]
        if url in seen_urls:
            continue
        details = parse_sarkari_detail(url)
        if not details:
            continue

        item_key = normalize_job_key(item["title"], details["org"])
        
        # Check if another portal added this job previously; if so, replace/upgrade it to Sarkari Result!
        dup_found = False
        for ek in existing_keys:
            if are_titles_duplicate(item_key, ek["key"]):
                dup_found = True
                break

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
        existing_keys.append({"key": item_key, "source": "SarkariResult", "id": 0})
        new_jobs_added += 1
        _notify_matching_users(job_record, details["full_text"], all_users)

    # 2. SECONDARY SOURCE: FreeJobAlert (Skipped if Sarkari Result already has it)
    fja_jobs = scrape_freejobalert(limit=max_per_source)
    for j in fja_jobs:
        url = j["url"]
        if url in seen_urls:
            continue

        item_key = normalize_job_key(j["title"], j["org"])
        if any(are_titles_duplicate(item_key, ek["key"]) for ek in existing_keys):
            # Duplicate job already present from Sarkari Result / existing! Skip!
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
        existing_keys.append({"key": item_key, "source": "FreeJobAlert", "id": 0})
        new_jobs_added += 1
        _notify_matching_users(job_record, j["full_text"], all_users)

    # 3. TERTIARY SOURCE: Rojgar Result (Skipped if Sarkari Result / FreeJobAlert already has it)
    rr_links = scrape_rojgar_result(limit=max_per_source)
    for item in rr_links:
        url = item["url"]
        if url in seen_urls:
            continue

        details = parse_rojgar_detail(url, item["title"], item.get("found_quals_pre", []))
        if not details:
            continue

        item_key = normalize_job_key(item["title"], details["org"])
        if any(are_titles_duplicate(item_key, ek["key"]) for ek in existing_keys):
            # Duplicate job! Skip!
            continue

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
        existing_keys.append({"key": item_key, "source": "RojgarResult", "id": 0})
        new_jobs_added += 1
        _notify_matching_users(job_record, details["full_text"], all_users)

    database.sync_db_to_json()
    print(f"[MultiScraper] Finished cycle. Added {new_jobs_added} clean jobs (Duplicates & Non-jobs filtered).")
    return {"new_jobs_processed": new_jobs_added}

def normalize_job_key(title, org=""):
    return normalize_title_for_dedup(title, org)

def _notify_matching_users(job_record, full_text, all_users):
    quals_found = job_record.get("qualifications_found", [])
    for user in all_users:
        user_quals = user.get("qualifications", [])
        user_kw = user.get("custom_keywords", [])
        matched = []
        for uq in user_quals:
            for qf in quals_found:
                if uq.upper() in qf.upper() or qf.upper() in uq.upper():
                    matched.append(qf)
                    break
        for kw in user_kw:
            if kw and kw.lower() in full_text.lower():
                matched.append(kw.upper())
        matched = list(dict.fromkeys(matched))
        if matched and user.get("ntfy_topic"):
            copy = dict(job_record)
            copy["matched_keywords"] = matched
            notifier.dispatch_job_alert(copy, {"ntfy_topic": user["ntfy_topic"]})

def rematch_all_cached_jobs():
    return database.sync_db_to_json()

if __name__ == "__main__":
    print("Testing deduplicated scrape...")
    run_scrape_cycle(max_per_source=3)

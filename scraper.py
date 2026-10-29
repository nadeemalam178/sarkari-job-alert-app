import re
import os
import sys
import requests
from bs4 import BeautifulSoup
from datetime import datetime
import database
import notifier
from concurrent.futures import ThreadPoolExecutor

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
    "GRADUATE": [r"\bany\s*graduate\b", r"\bdegree\s*in\s*any\s*stream\b", r"\bbachelor\s*degree\s*in\s*any\s*stream\b", r"\bgraduation\b", r"\bgraduate\b"],
    "BA": [r"\bb\.?a\.\b", r"\bbachelor\s*of\s*arts\b"],
    "B.SC": [r"\bb\.?\s*sc\b(?!\s*\(?\s*engg)", r"\bbachelor\s*of\s*science\b"],
    "B.COM": [r"\bb\.?com\b", r"\bbachelor\s*of\s*commerce\b"],
    "BBA": [r"\bbba\b", r"\bbachelor\s*of\s*business\b"],
    "BCA": [r"\bbca\b", r"\bbachelor\s*of\s*computer\s*application\b"],
    "B.LIB": [r"\bb\.?\s*lib\b", r"\blibrary\s*science\b"],

    # Engineering Degrees (B.Tech / B.E)
    "B.TECH / B.E": [r"\bb\.?\s*tech\b", r"\bb\.e\.\b", r"\bbachelor\s*of\s*engineering\b", r"\bbachelor\s*of\s*technology\b", r"\bengineering\s*degree\b", r"\bb\.?\s*e\s*/\s*b\.?\s*tech\b", r"\bb\.?tech\s*/\s*b\.?e\b"],
    "B.TECH CIVIL": [r"\bb\.?tech.*?civil\b", r"\bb\.e\..*?civil\b", r"\bcivil\s*engineering\b"],
    "B.TECH MECHANICAL": [r"\bb\.?tech.*?mech\b", r"\bb\.e\..*?mech\b", r"\bmechanical\s*engineering\b"],
    "B.TECH ELECTRICAL": [r"\bb\.?tech.*?electr\b", r"\bb\.e\..*?electr\b", r"\belectrical\s*engineering\b"],
    "B.TECH CS / IT": [r"\bb\.?\s*tech.*?(?:cs|computer|information\s*technology|it\b)", r"\bb\.e\..*?(?:cs|computer|information\s*technology)", r"\bcomputer\s*science\s*engineering\b"],

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
    "POLICE / DEFENCE": [r"\bpolice\b", r"\bconstable\b", r"\bsub\s*inspector\b", r"\bs\.i\.\b", r"\barmy\b", r"\bnavy\b", r"\bairforce\b", r"\bagniveer\b"],
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


# --- Scraper 1A: Sarkari Result (.com.cm Latest Jobs - HIGHEST PRIORITY) ---
def scrape_sarkari_cm_latest_jobs(limit=None):
    """Scrapes all active recruitment listings directly from https://sarkariresult.com.cm/latest-jobs/"""
    url = "https://sarkariresult.com.cm/latest-jobs/"
    jobs = []
    try:
        res = requests.get(url, headers=HEADERS, timeout=15)
        if res.status_code != 200:
            print(f"[Scraper] Failed to fetch {url}, status: {res.status_code}")
            return []
        soup = BeautifulSoup(res.text, "html.parser")
        seen_urls = set()

        for a in soup.find_all("a", href=True):
            href = a["href"].strip()
            title = a.get_text(" ", strip=True)
            if not href.startswith("http") or "sarkariresult.com.cm" not in href or href in seen_urls:
                continue
            # Skip non-job site navigation pages
            if any(href.rstrip("/").endswith(x) for x in ["/admit-card", "/result", "/admission", "/answer-key", "/syllabus", "/contact", "/privacy-policy", "/disclaimer", "/latest-jobs", "/latest-posts", "/about-us"]):
                continue
            if href.rstrip("/") == "https://sarkariresult.com.cm":
                continue
            if any(p in href for p in ["/category/", "/tag/", "/author/", "/page/"]):
                continue

            clean_title = re.sub(r"\s+", " ", title).strip()
            if len(clean_title) > 8 and not is_non_job(clean_title):
                seen_urls.add(href)
                jobs.append({
                    "url": href,
                    "title": clean_title,
                    "source": "SarkariResult"
                })
                if limit and len(jobs) >= limit:
                    break
        print(f"[Scraper] Found {len(jobs)} total jobs on sarkariresult.com.cm/latest-jobs/")
    except Exception as e:
        print("[Scraper] sarkariresult.com.cm error:", e)
    return jobs

def parse_sarkari_cm_detail(job_url, pre_title):
    """Parses comprehensive job intelligence from a sarkariresult.com.cm detail page"""
    try:
        res = requests.get(job_url, headers=HEADERS, timeout=12)
        if res.status_code != 200:
            return None
        soup = BeautifulSoup(res.text, "html.parser")
        page_text = soup.get_text("\n", strip=True)

        # 1. Start date & Last date
        start_date = ""
        start_patterns = [
            r"Application\s*(?:Begin|Start)\s*:\s*\n*([^\n\r|]{5,40})",
            r"Apply\s*Online\s*Start\s*Date\s*:\s*\n*([^\n\r|]{5,40})",
            r"start\s*date\s*is\s*\n*([^\n\r|]{5,40})",
            r"Online\s*Application\s*Starts?\s*:\s*\n*([^\n\r|]{5,40})",
            r"Opening\s*Date\s*:\s*\n*([^\n\r|]{5,40})",
            r"Link\s*Activate\s*(?:on|from)?\s*:\s*\n*([^\n\r|]{5,40})",
            r"Registration\s*Start\s*Date\s*:\s*\n*([^\n\r|]{5,40})",
            r"Starting\s*Date\s*:\s*\n*([^\n\r|]{5,40})",
        ]
        for sp in start_patterns:
            sm = re.search(sp, page_text, re.I)
            if sm:
                raw_sd = sm.group(1).strip()
                raw_sd = re.sub(r"\s*\.\s*Minimum.*", "", raw_sd, flags=re.I)
                raw_sd = re.sub(r"\s*upto.*", "", raw_sd, flags=re.I)
                raw_sd = re.sub(r"\s*\(.*?\)", "", raw_sd).strip()
                start_date = raw_sd[:35]
                break

        if not start_date and any(w in page_text.lower() for w in ["link activate soon", "link will be active soon", "notify soon"]):
            start_date = "Link Activate Soon"
        if not start_date and "2027" in pre_title:
            start_date = "Link Activate Soon"

        last_date = ""
        last_patterns = [
            r"Apply\s*Online\s*Last\s*Date\s*:\s*\n*([^\n\r|]{5,40})",
            r"Last\s*Date\s*(?:for\s*Apply\s*Online)?\s*:\s*\n*([^\n\r|]{5,40})",
            r"Closing\s*Date\s*:\s*\n*([^\n\r|]{5,40})",
            r"Registration\s*Last\s*Date\s*:\s*\n*([^\n\r|]{5,40})",
            r"Last\s*Date\s*to\s*Apply\s*:\s*\n*([^\n\r|]{5,40})",
        ]
        for lp in last_patterns:
            lm = re.search(lp, page_text, re.I)
            if lm:
                raw_ld = lm.group(1).strip()
                raw_ld = re.sub(r"\s*\.\s*Minimum.*", "", raw_ld, flags=re.I)
                raw_ld = re.sub(r"\s*upto.*", "", raw_ld, flags=re.I)
                raw_ld = re.sub(r"\s*\(.*?\)", "", raw_ld).strip()
                last_date = raw_ld[:35]
                break

        # 2. Total Posts
        total_posts = ""
        tm = re.search(r"\((\d+[\d,]*)\s*Posts?\)", pre_title, re.I)
        if tm:
            total_posts = f"{tm.group(1)} Posts"
        else:
            pm = re.search(r"Total\s*(?:Vacancy|Post)[^\d:\n]*[:\s]*(\d+[\d,]*)\s*(?:Post)?", page_text, re.I)
            if pm:
                total_posts = f"{pm.group(1).strip()} Posts"
            else:
                tbl = soup.find("table")
                if tbl:
                    total_sum = 0
                    for tr in tbl.find_all("tr"):
                        tds = tr.find_all(["td", "th"])
                        if len(tds) >= 2:
                            val = re.sub(r"[^\d]", "", tds[1].get_text())
                            if val and val.isdigit():
                                total_sum += int(val)
                    if total_sum > 0:
                        total_posts = f"{total_sum} Posts"

        # 3. Age Limit
        age_limit = ""
        am = re.search(r"Age\s*Limit[^\n:]*:\s*\n*([^\n\r|]{10,120})", page_text, re.I)
        if not am:
            min_age = re.search(r"Minimum\s*Age\s*:\s*\n*([^\n\r|]{3,30})", page_text, re.I)
            max_age = re.search(r"Maximum\s*Age\s*:\s*\n*([^\n\r|]{3,30})", page_text, re.I)
            if min_age or max_age:
                min_str = min_age.group(1).strip() if min_age else "N/A"
                max_str = max_age.group(1).strip() if max_age else "N/A"
                age_limit = f"Min: {min_str}, Max: {max_str}"
        else:
            age_limit = am.group(1).strip()

        # 4. Application Fee
        app_fee = ""
        fee_lines = []
        lines = [l.strip() for l in page_text.splitlines() if l.strip()]
        for i, line in enumerate(lines):
            if "application fee" in line.lower() and i + 1 < len(lines):
                for sub in lines[i+1:min(len(lines), i+6)]:
                    if any(x in sub.lower() for x in ["general", "obc", "sc", "st", "ews", "fee refund", "₹", "rs."]):
                        fee_lines.append(sub)
                    elif len(fee_lines) > 0:
                        break
        if fee_lines:
            app_fee = " | ".join(fee_lines[:3])

        # 5. Action links (Apply, Notification, Official Website)
        apply_link = ""
        notification_link = ""
        official_website = ""

        for tr in soup.find_all("tr"):
            row_txt = tr.get_text(" ", strip=True).lower()
            a = tr.find("a", href=True)
            if not a:
                continue
            href = a["href"].strip()
            if not href.startswith("http"):
                continue
            if "apply online" in row_txt and not apply_link:
                apply_link = href
            elif any(w in row_txt for w in ["official notification", "check notification", "download notification"]) and not notification_link:
                notification_link = href
            elif any(w in row_txt for w in ["official website", "rrb official website", "website link"]) and not official_website:
                official_website = href

        # 6. Organization & Eligibility
        h1 = soup.find("h1") or soup.find("h2")
        org = h1.get_text(strip=True) if h1 else ""

        snippet = ""
        for tr in soup.find_all("tr"):
            txt = tr.get_text(" ", strip=True)
            if any(w in txt.lower() for w in ["eligibility", "qualification", "degree", "passed", "diploma", "graduate", "10th", "12th"]):
                if 20 < len(txt) < 500:
                    snippet += txt + " | "
        if not snippet:
            em = re.search(r"Eligibility\s*Criteria[^\n]*\n*([^\n\r]{20,400})", page_text, re.I)
            if em:
                snippet = em.group(1).strip()

        quals_found = extract_qualifications_from_text(f"{pre_title} | {snippet}")
        if not quals_found and page_text:
            quals_found = extract_qualifications_from_text(f"{pre_title} | {page_text[:600]}")

        return {
            "start_date": start_date or "Active Now",
            "last_date": last_date or "Check Notification",
            "total_posts": total_posts or "Various Posts",
            "age_limit": age_limit or "As per recruitment rules",
            "application_fee": app_fee or "Check official notice",
            "apply_link": apply_link or job_url,
            "notification_link": notification_link or job_url,
            "official_website": official_website or "",
            "org": org[:150],
            "eligibility_snippet": snippet[:500] or "Refer to official notification.",
            "qualifications_found": quals_found,
            "full_text": page_text[:2000]
        }
    except Exception as e:
        print(f"[Scraper] Failed parsing sarkariresult.com.cm {job_url}: {e}")
        return None

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
        page_text = soup.get_text(separator=" ", strip=True)

        # 1. Dates (Start & Last Date)
        start_date = ""
        start_m = re.search(r"Application\s*Begin\s*:\s*(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})", page_text, re.I)
        if start_m:
            start_date = start_m.group(1)
        elif any(w in page_text.lower() for w in ["link activate soon", "link will be active soon", "notify soon", "available soon"]):
            start_date = "Link Activate Soon"

        last_date = ""
        date_match = re.search(r"Last Date\s*(?:for Apply Online)?\s*:\s*(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})", page_text, re.I)
        if date_match:
            last_date = date_match.group(1)
        else:
            dm2 = re.search(r"(\d{1,2}/\d{1,2}/202\d)", page_text)
            if dm2:
                last_date = dm2.group(1)
            else:
                dm_word = re.search(r"Last Date\s*(?:for Apply Online)?\s*:\s*([^\n\r|]{5,35})", page_text, re.I)
                if dm_word:
                    last_date = dm_word.group(1).strip()

        # 2. Total Posts / Vacancy
        total_posts = ""
        post_match = re.search(r"Total\s*(?:Vacancy|Post)[^\d:]*[:\s]*(\d+[\d,]*)\s*(?:Post)?", page_text, re.I)
        if post_match:
            total_posts = f"{post_match.group(1).strip()} Posts"
        else:
            # Check table headers or cells
            for td in soup.find_all(["td", "th", "h2", "h3"]):
                td_txt = td.get_text(strip=True)
                m = re.search(r"(\d+[\d,]*)\s*(?:Posts?|Vacanc(?:y|ies))", td_txt, re.I)
                if m and int(m.group(1).replace(",", "")) > 0:
                    total_posts = f"{m.group(1)} Posts"
                    break

        # 3. Age Limit & Application Fee
        age_limit = ""
        age_m = re.search(r"Age Limit as on[^:\n]*:\s*([^\n\r|]{10,120})", page_text, re.I)
        if age_m:
            age_limit = re.sub(r"\s+", " ", age_m.group(1)).strip()

        app_fee = ""
        fee_m = re.search(r"Application Fee\s*:\s*([^\n\r|]{10,120})", page_text, re.I)
        if fee_m:
            app_fee = re.sub(r"\s+", " ", fee_m.group(1)).strip()

        # 4. Action Links: Apply Online, Download Notification, Official Website
        apply_link = ""
        notification_link = ""
        official_website = ""

        for tr in soup.find_all("tr"):
            row_txt = tr.get_text(" ", strip=True).lower()
            a = tr.find("a", href=True)
            if not a:
                continue
            href = a["href"].strip()
            if not href.startswith("http"):
                continue

            if "apply online" in row_txt and not apply_link:
                apply_link = href
            elif any(w in row_txt for w in ["download notification", "notification"]) and not notification_link:
                notification_link = href
            elif any(w in row_txt for w in ["official website", "website"]) and not official_website:
                official_website = href

        # Fallbacks
        if not apply_link:
            apply_link = job_url
        if not notification_link:
            notification_link = job_url

        # Organization
        org = ""
        h1 = soup.find("h1") or soup.find("h2")
        if h1:
            org = h1.get_text(strip=True)

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

        found_quals = extract_qualifications_from_text(f"{org} | {snippet}")
        if not found_quals and page_text:
            found_quals = extract_qualifications_from_text(page_text[:600])
        return {
            "start_date": start_date or "Active Now",
            "last_date": last_date or "Check Notification",
            "total_posts": total_posts or "Various Posts",
            "age_limit": age_limit or "As per recruitment rules",
            "application_fee": app_fee or "Check official notification",
            "apply_link": apply_link,
            "notification_link": notification_link,
            "official_website": official_website,
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


# --- Scraper 4: GovtJobsAlert (Central & State Governments) ---
def scrape_govtjobsalert(limit=30):
    url = "https://govtjobsalert.in/"
    jobs = []
    seen = set()
    try:
        r = requests.get(url, headers=HEADERS, timeout=12)
        if r.status_code != 200:
            return []
        soup = BeautifulSoup(r.text, "html.parser")
        for a in soup.find_all("a", href=True):
            href = a["href"].strip()
            raw_txt = re.sub(r"\s+", " ", a.get_text(" ", strip=True)).strip()
            if not href.startswith("http") or "govtjobsalert.in" not in href or href in seen:
                continue
            if any(x in href for x in ["/privacy", "/disclaimer", "/contact", "/about", "/category/", "/tag/", "/author/", "/page/"]):
                continue
            if len(raw_txt) > 20 and any(w in raw_txt.lower() for w in ["recruitment", "posts", "last date", "apply", "officer", "engineer"]):
                if not is_non_job(raw_txt):
                    seen.add(href)
                    pm = re.search(r"([\d,]+)\s*Posts", raw_txt, re.I)
                    posts = f"{pm.group(1)} Posts" if pm else "Various Posts"
                    ld = re.search(r"Last\s*date\s*([^\s→]{3,20})", raw_txt, re.I)
                    last_date = ld.group(1) if ld else "Check Notification"
                    title = re.sub(r"[\d,]+\s*Posts.*", "", raw_txt).strip()
                    title = re.sub(r"Last\s*date.*", "", title).strip().rstrip("→").strip()
                    quals = extract_qualifications_from_text(raw_txt)
                    jobs.append({
                        "title": title or raw_txt[:80],
                        "url": href,
                        "total_posts": posts,
                        "last_date": last_date,
                        "source": "GovtJobsAlert",
                        "qualifications_found": quals,
                        "eligibility_snippet": f"Official notification on GovtJobsAlert for {title}. Vacancies: {posts}.",
                        "org": title.split(" ")[0] if title else "Govt of India",
                        "full_text": f"{raw_txt} {title} {posts}"
                    })
                    if len(jobs) >= limit:
                        break
    except Exception as e:
        print("[Scraper] GovtJobsAlert error:", e)
    return jobs

# --- Scraper 5: SarkariExam (Top Online Forms) ---
def scrape_sarkariexam(limit=30):
    url = "https://www.sarkariexam.com/"
    jobs = []
    seen = set()
    try:
        r = requests.get(url, headers=HEADERS, timeout=12)
        if r.status_code != 200:
            return []
        soup = BeautifulSoup(r.text, "html.parser")
        for a in soup.find_all("a", href=True):
            href = a["href"].strip()
            raw_txt = re.sub(r"\s+", " ", a.get_text(" ", strip=True)).strip()
            if not href.startswith("http") or "sarkariexam.com" not in href or href in seen:
                continue
            if any(x in href for x in ["/privacy", "/disclaimer", "/contact", "/about", "/category/", "/tag/", "/author/", "/page/", "/document-verification"]):
                continue
            if len(raw_txt) > 20 and any(w in raw_txt.lower() for w in ["online form", "recruitment", "posts", "vacancy", "bharti"]):
                if not is_non_job(raw_txt):
                    seen.add(href)
                    pm = re.search(r"\(([\d,]+)\s*Posts?\)", raw_txt, re.I)
                    posts = f"{pm.group(1)} Posts" if pm else "Various Posts"
                    quals = extract_qualifications_from_text(raw_txt)
                    clean_title = re.sub(r"–\s*Apply\s*Here.*", "", raw_txt).strip()
                    jobs.append({
                        "title": clean_title,
                        "url": href,
                        "total_posts": posts,
                        "last_date": "Check Notification",
                        "source": "SarkariExam",
                        "qualifications_found": quals,
                        "eligibility_snippet": f"Recruitment notice on SarkariExam: {clean_title}",
                        "org": clean_title.split(" ")[0],
                        "full_text": f"{clean_title} {posts}"
                    })
                    if len(jobs) >= limit:
                        break
    except Exception as e:
        print("[Scraper] SarkariExam error:", e)
    return jobs

# --- Scraper 6: IndGovtJobs (PSU & Central Vacancies) ---
def scrape_indgovtjobs(limit=25):
    url = "https://www.indgovtjobs.in/"
    jobs = []
    seen = set()
    try:
        r = requests.get(url, headers=HEADERS, timeout=12)
        if r.status_code != 200:
            return []
        soup = BeautifulSoup(r.text, "html.parser")
        for a in soup.find_all("a", href=True):
            href = a["href"].strip()
            raw_txt = re.sub(r"\s+", " ", a.get_text(" ", strip=True)).strip()
            if not href.startswith("http") or "indgovtjobs.in/20" not in href or href in seen:
                continue
            if len(raw_txt) > 20 and any(w in raw_txt.lower() for w in ["recruitment", "vacancies", "posts", "apply online"]):
                if not is_non_job(raw_txt):
                    seen.add(href)
                    pm = re.search(r"([\d,]+)\s*Posts?", raw_txt, re.I)
                    posts = f"{pm.group(1)} Posts" if pm else "Various Posts"
                    ld = re.search(r"Last\s*Date\s*([^\s|]{5,15})", raw_txt, re.I)
                    last_date = ld.group(1) if ld else "Check Notification"
                    clean_title = re.sub(r"\|\s*Last\s*Date.*", "", raw_txt).strip()
                    quals = extract_qualifications_from_text(raw_txt)
                    jobs.append({
                        "title": clean_title,
                        "url": href,
                        "total_posts": posts,
                        "last_date": last_date,
                        "source": "IndGovtJobs",
                        "qualifications_found": quals,
                        "eligibility_snippet": f"Central / State Government recruitment on IndGovtJobs: {clean_title}",
                        "org": clean_title.split(" ")[0],
                        "full_text": f"{clean_title} {posts} {last_date}"
                    })
                    if len(jobs) >= limit:
                        break
    except Exception as e:
        print("[Scraper] IndGovtJobs error:", e)
    return jobs

# --- Unified Deduplicated Scrape Cycle with Sarkari Result Priority ---
def run_scrape_cycle(max_per_source=150):
    seen_urls = database.get_seen_urls()
    print(f"[MultiScraper] Starting cycle. Existing URLs in DB: {len(seen_urls)}")

    all_users = database.get_all_users_for_notifications()
    new_jobs_added = 0

    existing_jobs = database.get_all_jobs(limit=1000)
    existing_keys = []
    for ej in existing_jobs:
        k = normalize_job_key(ej["title"], ej.get("org", ""))
        existing_keys.append({"key": k, "source": ej.get("source", "SarkariResult"), "id": ej["id"]})

    # 1. PRIMARY SOURCE: https://sarkariresult.com.cm/latest-jobs/ (FULL PAGE SCRAPE)
    cm_items = scrape_sarkari_cm_latest_jobs(limit=max_per_source)
    cm_unseen = [item for item in cm_items if item["url"] not in seen_urls]
    print(f"[MultiScraper] Fetching details for {len(cm_unseen)} new sarkariresult.com.cm jobs...")

    def _fetch_cm(item):
        try:
            det = parse_sarkari_cm_detail(item["url"], item["title"])
            if det:
                return {"item": item, "details": det}
        except Exception as e:
            print(f"[Scraper] Error fetching {item['url']}: {e}")
        return None

    if cm_unseen:
        with ThreadPoolExecutor(max_workers=8) as ex:
            for res in ex.map(_fetch_cm, cm_unseen):
                if not res:
                    continue
                item = res["item"]
                details = res["details"]
                url = item["url"]
                item_key = normalize_job_key(item["title"], details["org"])

                job_record = {
                    "source": "SarkariResult",
                    "url": url,
                    "title": item["title"],
                    "org": details["org"],
                    "last_date": details["last_date"],
                    "start_date": details.get("start_date", "Active Now"),
                    "total_posts": details.get("total_posts", "Various Posts"),
                    "apply_link": details.get("apply_link", url),
                    "notification_link": details.get("notification_link", url),
                    "official_website": details.get("official_website", ""),
                    "age_limit": details.get("age_limit", "As per notification rules"),
                    "application_fee": details.get("application_fee", "Check official notice"),
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

    # 1B. COMPLEMENTARY SOURCE: www.sarkariresult.com/latestjob/
    sr_links = scrape_sarkari_result(limit=30)
    for item in sr_links:
        url = item["url"]
        if url in seen_urls:
            continue
        details = parse_sarkari_detail(url)
        if not details:
            continue

        item_key = normalize_job_key(item["title"], details["org"])
        if any(are_titles_duplicate(item_key, ek["key"]) for ek in existing_keys):
            continue

        job_record = {
            "source": "SarkariResult",
            "url": url,
            "title": item["title"],
            "org": details["org"],
            "last_date": details["last_date"],
            "start_date": details.get("start_date", "Active Now"),
            "total_posts": details.get("total_posts", "Various Posts"),
            "apply_link": details.get("apply_link", url),
            "notification_link": details.get("notification_link", url),
            "official_website": details.get("official_website", ""),
            "age_limit": details.get("age_limit", "As per notification rules"),
            "application_fee": details.get("application_fee", "Check official notice"),
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

    # 2. SECONDARY SOURCE: FreeJobAlert (Skipped if already on SarkariResult)
    fja_jobs = scrape_freejobalert(limit=30)
    for j in fja_jobs:
        url = j["url"]
        if url in seen_urls:
            continue

        item_key = normalize_job_key(j["title"], j["org"])
        if any(are_titles_duplicate(item_key, ek["key"]) for ek in existing_keys):
            continue

        job_record = {
            "source": "FreeJobAlert",
            "url": url,
            "title": j["title"],
            "org": j["org"],
            "last_date": j["last_date"],
            "start_date": j.get("start_date", "Active Now"),
            "total_posts": j.get("total_posts", "Various Posts"),
            "apply_link": j.get("apply_link", url),
            "notification_link": j.get("notification_link", url),
            "official_website": j.get("official_website", ""),
            "age_limit": j.get("age_limit", "As per notification rules"),
            "application_fee": j.get("application_fee", "Check official notice"),
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

    # 3. TERTIARY SOURCE: Rojgar Result (Skipped if already on SarkariResult/FreeJobAlert)
    rr_links = scrape_rojgar_result(limit=30)
    for item in rr_links:
        url = item["url"]
        if url in seen_urls:
            continue

        details = parse_rojgar_detail(url, item["title"], item.get("found_quals_pre", []))
        if not details:
            continue

        item_key = normalize_job_key(item["title"], details["org"])
        if any(are_titles_duplicate(item_key, ek["key"]) for ek in existing_keys):
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

    # 4. QUATERNARY SOURCE: GovtJobsAlert (PSUs, Central, State Vacancies)
    gja_jobs = scrape_govtjobsalert(limit=30)
    for j in gja_jobs:
        url = j["url"]
        if url in seen_urls:
            continue

        item_key = normalize_job_key(j["title"], j.get("org", ""))
        if any(are_titles_duplicate(item_key, ek["key"]) for ek in existing_keys):
            continue

        job_record = {
            "source": "GovtJobsAlert",
            "url": url,
            "title": j["title"],
            "org": j.get("org", "Govt of India"),
            "last_date": j.get("last_date", "Check Notification"),
            "start_date": "Active Now",
            "total_posts": j.get("total_posts", "Various Posts"),
            "apply_link": url,
            "notification_link": url,
            "official_website": "",
            "age_limit": "As per notification rules",
            "application_fee": "Check official notice",
            "eligibility_snippet": j.get("eligibility_snippet", ""),
            "qualifications_found": j.get("qualifications_found", []),
            "matched_keywords": [],
            "is_matched": len(j.get("qualifications_found", [])) > 0,
            "scraped_at": datetime.now().strftime("%Y-%m-%d %H:%M"),
            "notified": 0
        }
        database.save_job(job_record)
        seen_urls.add(url)
        existing_keys.append({"key": item_key, "source": "GovtJobsAlert", "id": 0})
        new_jobs_added += 1
        _notify_matching_users(job_record, j.get("full_text", ""), all_users)

    # 5. QUINARY SOURCE: SarkariExam (Top Online Forms)
    se_jobs = scrape_sarkariexam(limit=30)
    for j in se_jobs:
        url = j["url"]
        if url in seen_urls:
            continue

        item_key = normalize_job_key(j["title"], j.get("org", ""))
        if any(are_titles_duplicate(item_key, ek["key"]) for ek in existing_keys):
            continue

        job_record = {
            "source": "SarkariExam",
            "url": url,
            "title": j["title"],
            "org": j.get("org", "Government Organization"),
            "last_date": j.get("last_date", "Check Notification"),
            "start_date": "Active Now",
            "total_posts": j.get("total_posts", "Various Posts"),
            "apply_link": url,
            "notification_link": url,
            "official_website": "",
            "age_limit": "As per notification rules",
            "application_fee": "Check official notice",
            "eligibility_snippet": j.get("eligibility_snippet", ""),
            "qualifications_found": j.get("qualifications_found", []),
            "matched_keywords": [],
            "is_matched": len(j.get("qualifications_found", [])) > 0,
            "scraped_at": datetime.now().strftime("%Y-%m-%d %H:%M"),
            "notified": 0
        }
        database.save_job(job_record)
        seen_urls.add(url)
        existing_keys.append({"key": item_key, "source": "SarkariExam", "id": 0})
        new_jobs_added += 1
        _notify_matching_users(job_record, j.get("full_text", ""), all_users)

    # 6. SENARY SOURCE: IndGovtJobs (PSU, Research & Central Vacancies)
    igj_jobs = scrape_indgovtjobs(limit=25)
    for j in igj_jobs:
        url = j["url"]
        if url in seen_urls:
            continue

        item_key = normalize_job_key(j["title"], j.get("org", ""))
        if any(are_titles_duplicate(item_key, ek["key"]) for ek in existing_keys):
            continue

        job_record = {
            "source": "IndGovtJobs",
            "url": url,
            "title": j["title"],
            "org": j.get("org", "Government PSU"),
            "last_date": j.get("last_date", "Check Notification"),
            "start_date": "Active Now",
            "total_posts": j.get("total_posts", "Various Posts"),
            "apply_link": url,
            "notification_link": url,
            "official_website": "",
            "age_limit": "As per notification rules",
            "application_fee": "Check official notice",
            "eligibility_snippet": j.get("eligibility_snippet", ""),
            "qualifications_found": j.get("qualifications_found", []),
            "matched_keywords": [],
            "is_matched": len(j.get("qualifications_found", [])) > 0,
            "scraped_at": datetime.now().strftime("%Y-%m-%d %H:%M"),
            "notified": 0
        }
        database.save_job(job_record)
        seen_urls.add(url)
        existing_keys.append({"key": item_key, "source": "IndGovtJobs", "id": 0})
        new_jobs_added += 1
        _notify_matching_users(job_record, j.get("full_text", ""), all_users)

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
    print("Executing full multi-portal scrape cycle including sarkariresult.com.cm/latest-jobs/...")
    run_scrape_cycle(max_per_source=150)

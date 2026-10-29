import os
import sys
import json
import sqlite3
import re
from datetime import datetime

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import database
import scraper

def parse_date(date_str):
    if not date_str:
        return None
    s = date_str.lower().strip()
    m = re.search(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})', s)
    if m:
        d, mth, y = int(m.group(1)), int(m.group(2)), int(m.group(3))
        if y < 100: y += 2000
        try: return datetime(y, mth, d)
        except: return None
    m = re.search(r'(\d{1,2})(?:st|nd|rd|th)?\s+([a-z]+)\s+(\d{4})', s)
    if m:
        d = int(m.group(1))
        m_name = m.group(2)[:3]
        y = int(m.group(3))
        months = {'jan':1,'feb':2,'mar':3,'apr':4,'may':5,'jun':6,'jul':7,'aug':8,'sep':9,'oct':10,'nov':11,'dec':12}
        if m_name in months:
            try: return datetime(y, months[m_name], d)
            except: return None
    m = re.search(r'([a-z]+)\s+(\d{1,2}),?\s+(\d{4})', s)
    if m:
        m_name = m.group(1)[:3]
        d = int(m.group(2))
        y = int(m.group(3))
        months = {'jan':1,'feb':2,'mar':3,'apr':4,'may':5,'jun':6,'jul':7,'aug':8,'sep':9,'oct':10,'nov':11,'dec':12}
        if m_name in months:
            try: return datetime(y, months[m_name], d)
            except: return None
    return None

today = datetime(2026, 10, 29)
print(f"Current System Benchmark Date: {today.strftime('%Y-%m-%d')}")

# Step 1: Scrape fresh live jobs from sarkariresult.com
print("\n[Step 1] Fetching live vacancies from sarkariresult.com/latestjob/...")
fresh_sr = scraper.scrape_sarkari_result(limit=50)
print(f"Found {len(fresh_sr)} recent links on SarkariResult.")
added_count = 0
for item in fresh_sr:
    url = item["url"]
    details = scraper.parse_sarkari_detail(url)
    if details:
        p_last = parse_date(details.get("last_date", ""))
        # Only add if not expired
        if p_last and p_last < today:
            continue
            
        scoped_text = f"{details.get('org', '')} | {item['title']} | {details.get('eligibility_snippet', '')}"
        clean_quals = scraper.extract_qualifications_from_text(scoped_text)
        
        job_record = {
            "source": "SarkariResult",
            "url": url,
            "title": item["title"],
            "org": details.get("org", "Government Organization"),
            "last_date": details.get("last_date", "Check Notification"),
            "start_date": details.get("start_date", "Active Now"),
            "total_posts": details.get("total_posts", "Various Posts"),
            "apply_link": details.get("apply_link", url),
            "notification_link": details.get("notification_link", url),
            "official_website": details.get("official_website", ""),
            "age_limit": details.get("age_limit", "As per notification rules"),
            "application_fee": details.get("application_fee", "Check official notice"),
            "eligibility_snippet": details.get("eligibility_snippet", ""),
            "qualifications_found": clean_quals,
            "matched_keywords": [],
            "is_matched": len(clean_quals) > 0,
            "scraped_at": datetime.now().strftime("%Y-%m-%d %H:%M"),
            "notified": 0
        }
        database.save_job(job_record)
        added_count += 1
print(f"Added / updated {added_count} live postings.")

# Step 2: Clean up database
print("\n[Step 2] Cleaning up expired and corrupted records from SQLite...")
conn = database.get_db()
cur = conn.cursor()
cur.execute("SELECT id, title, last_date, start_date, eligibility_snippet, org FROM jobs")
all_rows = cur.fetchall()

deleted_ids = []
updated_count = 0
for r in all_rows:
    jid = r["id"]
    title = r["title"] or ""
    last_d = r["last_date"] or ""
    start_d = r["start_date"] or ""
    snippet = r["eligibility_snippet"] or ""
    org = r["org"] or ""
    
    p_last = parse_date(last_d)
    
    # 1. Purge expired jobs (deadline has passed)
    if (p_last and p_last < today) or any(k in last_d.lower() for k in ["cancelled", "closed"]):
        deleted_ids.append(jid)
        continue
        
    # 2. Re-extract clean qualifications
    scoped_text = f"{org} | {title} | {snippet}"
    clean_quals = scraper.extract_qualifications_from_text(scoped_text)
    
    # If start date was empty, assign Active Now or Link Activate Soon
    if not start_d:
        if any(w in (title + snippet).lower() for w in ["activate soon", "coming soon", "notify soon", "2027"]):
            start_d = "Link Activate Soon"
        else:
            start_d = "Active Now"
            
    cur.execute('''
        UPDATE jobs 
        SET qualifications_found = ?, start_date = ?
        WHERE id = ?
    ''', (json.dumps(clean_quals), start_d, jid))
    updated_count += 1

if deleted_ids:
    cur.execute(f"DELETE FROM jobs WHERE id IN ({','.join(map(str, deleted_ids))})")
    conn.commit()
print(f"Purged {len(deleted_ids)} expired postings.")
print(f"Updated qualifications for {updated_count} valid postings.")
conn.close()

# Step 3: Export clean SQLite to jobs.json
print("\n[Step 3] Syncing clean SQLite database to data/jobs.json...")
database.sync_db_to_json()

# Step 4: Verification of the final jobs.json
with open('data/jobs.json', encoding='utf-8') as f:
    final_jobs = json.load(f)

active_list = []
upcoming_list = []
btech_list = []
bsc_list = []
teaching_list = []

for j in final_jobs:
    t = j['title'].lower()
    sd = j.get('start_date', '').lower()
    ld = j.get('last_date', '').lower()
    quals = j.get('qualifications_found', [])
    p_start = parse_date(sd)
    
    is_up = False
    if any(k in sd for k in ['activate soon', 'notify soon', 'coming soon', 'soon', 'opening soon', 'calendar']) or '2027' in t or (p_start and p_start > today):
        is_up = True
        
    if is_up:
        upcoming_list.append(j)
    else:
        active_list.append(j)
        
    if 'B.TECH / B.E' in quals:
        btech_list.append(j)
    if 'B.SC' in quals:
        bsc_list.append(j)
    if 'TEACHER' in quals or 'B.ED' in quals:
        teaching_list.append(j)

print("\n" + "="*50)
print("FINAL VERIFIED DATASET BREAKDOWN:")
print(f"Total Valid Postings: {len(final_jobs)}")
print(f"Active Vacancies:     {len(active_list)}")
print(f"Upcoming Vacancies:   {len(upcoming_list)}")
print(f"B.Tech Jobs:          {len(btech_list)}")
print(f"B.Sc Jobs:            {len(bsc_list)}")
print(f"Teaching Jobs:        {len(teaching_list)}")
print("="*50)

print("\nSample B.Tech Vacancies (Should ONLY be Engineering):")
for j in btech_list[:5]:
    print(f"  - {j['title'][:55]} | Quals: {j.get('qualifications_found')}")

print("\nSample Upcoming Vacancies:")
for j in upcoming_list[:5]:
    print(f"  - {j['title'][:45]} | Start: {j.get('start_date')} | Last: {j.get('last_date')}")


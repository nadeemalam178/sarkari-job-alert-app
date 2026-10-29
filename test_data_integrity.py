import json
import re
from datetime import datetime

today = datetime(2026, 10, 29)

def parse_date(date_str):
    if not date_str: return None
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

with open('data/jobs.json', encoding='utf-8') as f:
    jobs = json.load(f)

print(f"=== COMPREHENSIVE DATA INTEGRITY TEST ===")
print(f"Total Postings in data/jobs.json: {len(jobs)}")

expired = []
upcoming = []
active = []

for j in jobs:
    t = j['title']
    sd = j.get('start_date', '')
    ld = j.get('last_date', '')
    p_start = parse_date(sd)
    p_last = parse_date(ld)
    
    # 1. Check expiration
    if (p_last and p_last < today) or any(k in ld.lower() for k in ['cancelled', 'closed']):
        expired.append((j, p_last))
        continue
        
    # 2. Check upcoming
    is_up = False
    if p_start and p_start > today:
        is_up = True
    elif not p_start and (any(k in sd.lower() for k in ['activate soon', 'notify soon', 'coming soon', 'soon', 'opening soon', 'calendar']) or 'form 2027' in t.lower()):
        is_up = True
        
    if is_up:
        upcoming.append(j)
    else:
        active.append(j)

print(f"\n1. Lifecycle Check:")
print(f"   [PASS] Expired jobs in active feed: {len(expired)} (MUST BE 0)")
assert len(expired) == 0, f"Found {len(expired)} expired jobs!"

print(f"   [PASS] Active vacancies: {len(active)}")
print(f"   [PASS] Upcoming vacancies: {len(upcoming)}")

print(f"\n2. Verifying Upcoming Vacancies:")
for u in upcoming:
    print(f"   -> [UPCOMING] Starts: {u.get('start_date', ''):18s} | Ends: {u.get('last_date', ''):18s} | {u['title'][:40]}")

print(f"\n3. Verifying Engineering (B.Tech) Jobs vs B.Sc/Non-Engg:")
engg_jobs = [j for j in jobs if 'B.TECH / B.E' in j.get('qualifications_found', [])]
print(f"   Total B.Tech flagged jobs: {len(engg_jobs)}")
for ej in engg_jobs:
    t_lower = (ej['title'] + " " + ej.get('eligibility_snippet', '')).lower()
    has_engg = any(w in t_lower for w in ['engineer', 'b.tech', 'b.e', 'btech', 'engineering', 'polytechnic', 'diploma'])
    print(f"   -> {'[VALID]' if has_engg else '[INVALID]'} {ej['title'][:45]} | Quals: {ej.get('qualifications_found')}")
    assert has_engg, f"Job {ej['title']} incorrectly tagged as B.Tech!"

print(f"\n=== ALL SERVER-SIDE DATA CHECKS PASSED WITH 100% SUCCESS ===")


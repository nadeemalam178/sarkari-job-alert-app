import requests
import json

def send_ntfy_notification(topic, title, message, click_url=None, tags=["briefcase", "bell"]):
    """
    Sends an instant push notification via ntfy.sh (100% Free, Zero-Login)
    Direct to phone lockscreen!
    """
    if not topic:
        return False, "No ntfy topic provided"

    # HTTP header values in requests must be ASCII/Latin-1 safe
    clean_title = title.encode('ascii', 'ignore').decode('ascii').strip()
    if not clean_title:
        clean_title = "Sarkari Job Match Alert"

    headers = {
        "Title": clean_title[:200],
        "Tags": ",".join(tags),
        "Priority": "high"
    }
    if click_url:
        headers["Click"] = click_url

    try:
        url = f"https://ntfy.sh/{topic.strip()}"
        response = requests.post(
            url,
            data=message.encode("utf-8"),
            headers=headers,
            timeout=8
        )
        return (response.status_code == 200), response.text
    except Exception as e:
        return False, str(e)

def send_telegram_notification(bot_token, chat_id, message, click_url=None):
    """
    Optional Telegram notification
    """
    if not bot_token or not chat_id:
        return False, "Telegram credentials missing"

    text = message
    if click_url:
        text += f"\n\n🔗 [Apply / View Details]({click_url})"

    payload = {
        "chat_id": chat_id,
        "text": text,
        "parse_mode": "Markdown",
        "disable_web_page_preview": False
    }

    try:
        url = f"https://api.telegram.org/bot{bot_token}/sendMessage"
        resp = requests.post(url, json=payload, timeout=8)
        return (resp.status_code == 200), resp.text
    except Exception as e:
        return False, str(e)

def dispatch_job_alert(job, settings):
    """
    Dispatches alerts across all configured channels
    """
    matched_str = ", ".join(job.get("matched_keywords", []))
    title = f"🎯 Job Match: {matched_str}"
    last_date = job.get('last_date', 'Check notification')
    body = (
        f"📌 {job.get('title')}\n"
        f"🎓 Qualifications Matched: {matched_str}\n"
        f"📅 Last Date: {last_date}"
    )
    click_url = job.get("url")

    results = {}

    # 1. ntfy.sh Mobile Push
    ntfy_topic = settings.get("ntfy_topic")
    if ntfy_topic:
        ok, res = send_ntfy_notification(ntfy_topic, title, body, click_url=click_url)
        results["ntfy"] = {"success": ok, "response": res}

    # 2. Telegram (Optional)
    tg_token = settings.get("telegram_bot_token")
    tg_chat = settings.get("telegram_chat_id")
    if tg_token and tg_chat:
        ok, res = send_telegram_notification(tg_token, tg_chat, body, click_url=click_url)
        results["telegram"] = {"success": ok, "response": res}

    return results

if __name__ == "__main__":
    sample_job = {
        "title": "BPSC Teacher / PGT Computer Science Recruitment 2026",
        "matched_keywords": ["B.ED", "CTET", "MCA"],
        "last_date": "30/11/2026",
        "url": "https://www.sarkariresult.com"
    }
    sample_settings = {
        "ntfy_topic": "sarkari_job_alert_user"
    }
    print("Testing dispatch to ntfy topic 'sarkari_job_alert_user'...")
    res = dispatch_job_alert(sample_job, sample_settings)
    print("Dispatch result:", res["ntfy"]["success"])

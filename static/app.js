// State Management
let currentSettings = {
  selected_qualifications: [],
  custom_keywords: [],
  ntfy_topic: "sarkari_job_alert_user",
  enable_browser_push: true,
  enable_sound: true,
  check_interval_minutes: 60
};

let cachedMatchedJobs = [];
let cachedAllJobs = [];

// Web Audio API Chime Generator
function playAlertChime() {
  if (!currentSettings.enable_sound) return;
  try {
    const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    const osc = audioCtx.createOscillator();
    const gain = audioCtx.createGain();
    
    osc.type = 'sine';
    // Two-tone notification chime: 587.33Hz (D5) -> 880Hz (A5)
    osc.frequency.setValueAtTime(587.33, audioCtx.currentTime);
    osc.frequency.setValueAtTime(880, audioCtx.currentTime + 0.12);
    
    gain.gain.setValueAtTime(0.2, audioCtx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + 0.5);
    
    osc.connect(gain);
    gain.connect(audioCtx.destination);
    
    osc.start();
    osc.stop(audioCtx.currentTime + 0.5);
  } catch (e) {
    console.log("Audio chime error:", e);
  }
}

// Register PWA Service Worker
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/sw.js')
      .then(reg => console.log('Service Worker registered with scope:', reg.scope))
      .catch(err => console.log('Service Worker registration failed:', err));
  });
}

// Request Browser Notification Permission
async function requestNotificationPermission() {
  if (!("Notification" in window)) {
    alert("This browser does not support desktop notifications.");
    return;
  }
  const perm = await Notification.requestPermission();
  if (perm === "granted") {
    new Notification("🎯 Sarkari Job Alert", {
      body: "Browser notifications enabled! You will now receive instant alerts when jobs match.",
      icon: "/icons/icon-192.png"
    });
    playAlertChime();
  } else {
    alert("Notification permission was denied. Please allow notifications in your browser settings.");
  }
}

// DOM Elements
document.addEventListener("DOMContentLoaded", () => {
  initTabs();
  loadSettings();
  loadStats();
  loadJobs();

  // Event Listeners
  document.getElementById("btn-check-now").addEventListener("click", triggerScrapeNow);
  document.getElementById("btn-save-qualifications").addEventListener("click", saveQualifications);
  document.getElementById("btn-save-settings").addEventListener("click", saveAlertSettings);
  document.getElementById("btn-test-notification").addEventListener("click", testNotification);
  document.getElementById("btn-request-perm").addEventListener("click", requestNotificationPermission);
  
  // Custom keywords input
  document.getElementById("btn-add-keyword").addEventListener("click", addCustomKeyword);
  document.getElementById("new-keyword-input").addEventListener("keypress", (e) => {
    if (e.key === "Enter") addCustomKeyword();
  });

  // Search inputs
  document.getElementById("matched-search-input").addEventListener("input", filterMatchedJobs);
  document.getElementById("all-search-input").addEventListener("input", filterAllJobs);
});

// Tab Switcher
function initTabs() {
  const tabs = document.querySelectorAll(".tab-btn");
  tabs.forEach(tab => {
    tab.addEventListener("click", () => {
      tabs.forEach(t => t.classList.remove("active"));
      document.querySelectorAll(".tab-panel").forEach(p => p.classList.remove("active"));

      tab.classList.add("active");
      const targetId = tab.getAttribute("data-tab");
      const targetPanel = document.getElementById(targetId);
      if (targetPanel) targetPanel.classList.add("active");
    });
  });
}

// Load Settings from API
async function loadSettings() {
  try {
    const res = await fetch("/api/settings");
    const data = await res.json();
    if (data.success && data.settings) {
      currentSettings = data.settings;
      populateQualificationsUI();
      populateAlertsUI();
    }
  } catch (err) {
    console.error("Failed to load settings:", err);
  }
}

// Populate Checkboxes & Keywords
function populateQualificationsUI() {
  const selected = currentSettings.selected_qualifications || [];
  document.querySelectorAll("input[name='qual']").forEach(cb => {
    cb.checked = selected.includes(cb.value);
  });
  renderKeywordTags();
}

// Populate Alerts UI
function populateAlertsUI() {
  document.getElementById("ntfy-topic-input").value = currentSettings.ntfy_topic || "sarkari_job_alert_user";
  updateNtfyLink(currentSettings.ntfy_topic || "sarkari_job_alert_user");
  document.getElementById("toggle-browser-push").checked = !!currentSettings.enable_browser_push;
  document.getElementById("toggle-sound").checked = !!currentSettings.enable_sound;
  document.getElementById("select-interval").value = currentSettings.check_interval_minutes || 60;
  document.getElementById("tg-token-input").value = currentSettings.telegram_bot_token || "";
  document.getElementById("tg-chat-input").value = currentSettings.telegram_chat_id || "";
}

function updateNtfyLink(topic) {
  const link = document.getElementById("ntfy-link");
  if (link) {
    link.href = `https://ntfy.sh/${topic}`;
    link.textContent = `ntfy.sh/${topic}`;
  }
}

// Render Custom Keywords Tags
function renderKeywordTags() {
  const container = document.getElementById("keywords-tags-container");
  container.innerHTML = "";
  const keywords = currentSettings.custom_keywords || [];
  keywords.forEach((kw, index) => {
    const tag = document.createElement("span");
    tag.className = "keyword-tag";
    tag.innerHTML = `${kw} <span class="remove-tag" data-index="${index}">&times;</span>`;
    container.appendChild(tag);
  });

  // Attach delete handlers
  container.querySelectorAll(".remove-tag").forEach(btn => {
    btn.addEventListener("click", (e) => {
      const idx = parseInt(e.target.getAttribute("data-index"));
      currentSettings.custom_keywords.splice(idx, 1);
      renderKeywordTags();
    });
  });
}

function addCustomKeyword() {
  const input = document.getElementById("new-keyword-input");
  const val = input.value.trim().toUpperCase();
  if (val && !currentSettings.custom_keywords.includes(val)) {
    currentSettings.custom_keywords.push(val);
    renderKeywordTags();
    input.value = "";
  }
}

// Load Stats
async function loadStats() {
  try {
    const res = await fetch("/api/stats");
    const data = await res.json();
    if (data.success && data.stats) {
      document.getElementById("stat-matched-count").textContent = data.stats.total_matched || 0;
      document.getElementById("stat-total-count").textContent = data.stats.total_checked || 0;
      document.getElementById("stat-last-time").textContent = data.stats.last_checked_at || "Just now";
      document.getElementById("badge-matched").textContent = data.stats.total_matched || 0;
    }
  } catch (err) {
    console.error("Failed to load stats:", err);
  }
}

// Load Jobs
async function loadJobs() {
  try {
    // 1. Matched Jobs
    const resMatched = await fetch("/api/jobs?matched_only=true&limit=100");
    const dataMatched = await resMatched.json();
    cachedMatchedJobs = dataMatched.jobs || [];
    renderJobsList(cachedMatchedJobs, "matched-jobs-list", true);

    // 2. All Jobs
    const resAll = await fetch("/api/jobs?matched_only=false&limit=100");
    const dataAll = await resAll.json();
    cachedAllJobs = dataAll.jobs || [];
    renderJobsList(cachedAllJobs, "all-jobs-list", false);

    document.getElementById("badge-matched").textContent = cachedMatchedJobs.length;
    document.getElementById("stat-matched-count").textContent = cachedMatchedJobs.length;
    document.getElementById("stat-total-count").textContent = cachedAllJobs.length;
  } catch (err) {
    console.error("Failed to load jobs:", err);
  }
}

// Render Job Cards
function renderJobsList(jobs, containerId, isMatchedTab) {
  const container = document.getElementById(containerId);
  if (!container) return;

  if (jobs.length === 0) {
    container.innerHTML = `
      <div class="empty-state">
        <p>No jobs found.</p>
        ${isMatchedTab ? '<p style="margin-top:6px; font-size:0.85rem;">Tip: Try adding more qualifications in the <strong>My Qualifications</strong> tab!</p>' : ''}
      </div>
    `;
    return;
  }

  container.innerHTML = jobs.map(job => {
    const matchedTags = (job.matched_keywords || []).map(k => `<span class="tag-badge tag-matched">${k}</span>`).join(" ");
    const otherTags = (job.qualifications_found || [])
      .filter(q => !(job.matched_keywords || []).includes(q))
      .slice(0, 4)
      .map(k => `<span class="tag-badge tag-other">${k}</span>`).join(" ");

    return `
      <article class="job-card ${job.is_matched ? 'is-matched-card' : ''}">
        <div class="job-card-top">
          <h3 class="job-title">${escapeHtml(job.title)}</h3>
          <a href="${escapeHtml(job.url)}" target="_blank" rel="noopener" class="btn btn-sm btn-primary">
            Apply / View &rarr;
          </a>
        </div>
        
        ${job.org ? `<div class="job-org"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path><circle cx="12" cy="7" r="4"></circle></svg> ${escapeHtml(job.org)}</div>` : ''}

        <div class="job-tags-row">
          ${matchedTags}
          ${otherTags}
        </div>

        <div class="job-snippet">
          ${escapeHtml(job.eligibility_snippet || "Check official advertisement on Sarkari Result.")}
        </div>

        <div class="job-card-bottom">
          <div class="job-date-info">
            📅 Last Date: <span class="date-val">${escapeHtml(job.last_date || "Refer notification")}</span>
          </div>
          <span style="font-size:0.75rem; color:var(--text-dim);">Scraped: ${escapeHtml(job.scraped_at || "")}</span>
        </div>
      </article>
    `;
  }).join("");
}

// Live Search Handlers
function filterMatchedJobs(e) {
  const query = e.target.value.toLowerCase().trim();
  const filtered = cachedMatchedJobs.filter(j => 
    j.title.toLowerCase().includes(query) ||
    (j.org && j.org.toLowerCase().includes(query)) ||
    (j.matched_keywords && j.matched_keywords.some(k => k.toLowerCase().includes(query))) ||
    (j.eligibility_snippet && j.eligibility_snippet.toLowerCase().includes(query))
  );
  renderJobsList(filtered, "matched-jobs-list", true);
}

function filterAllJobs(e) {
  const query = e.target.value.toLowerCase().trim();
  const filtered = cachedAllJobs.filter(j => 
    j.title.toLowerCase().includes(query) ||
    (j.org && j.org.toLowerCase().includes(query)) ||
    (j.qualifications_found && j.qualifications_found.some(k => k.toLowerCase().includes(query))) ||
    (j.eligibility_snippet && j.eligibility_snippet.toLowerCase().includes(query))
  );
  renderJobsList(filtered, "all-jobs-list", false);
}

// Save Qualifications & Re-Filter
async function saveQualifications() {
  const selected = [];
  document.querySelectorAll("input[name='qual']:checked").forEach(cb => selected.push(cb.value));
  
  const statusEl = document.getElementById("save-qual-status");
  statusEl.textContent = "Updating and re-filtering cached jobs...";
  statusEl.className = "status-msg";

  try {
    const res = await fetch("/api/settings", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        selected_qualifications: selected,
        custom_keywords: currentSettings.custom_keywords
      })
    });
    const data = await res.json();
    if (data.success) {
      statusEl.textContent = `Saved! ${data.rematched_jobs} jobs now match your criteria.`;
      statusEl.classList.add("status-success");
      currentSettings.selected_qualifications = selected;
      playAlertChime();
      loadJobs();
      loadStats();
    }
  } catch (err) {
    statusEl.textContent = "Error saving: " + err.message;
  }
}

// Save Alert Settings
async function saveAlertSettings() {
  const ntfyTopic = document.getElementById("ntfy-topic-input").value.trim();
  const browserPush = document.getElementById("toggle-browser-push").checked;
  const sound = document.getElementById("toggle-sound").checked;
  const interval = parseInt(document.getElementById("select-interval").value);
  const tgToken = document.getElementById("tg-token-input").value.trim();
  const tgChat = document.getElementById("tg-chat-input").value.trim();

  const statusEl = document.getElementById("save-settings-status");
  statusEl.textContent = "Saving settings...";
  statusEl.className = "status-msg";

  try {
    const res = await fetch("/api/settings", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        ntfy_topic: ntfyTopic,
        enable_browser_push: browserPush,
        enable_sound: sound,
        check_interval_minutes: interval,
        telegram_bot_token: tgToken,
        telegram_chat_id: tgChat
      })
    });
    const data = await res.json();
    if (data.success) {
      currentSettings = data.settings;
      updateNtfyLink(ntfyTopic);
      statusEl.textContent = "Notification preferences updated successfully!";
      statusEl.classList.add("status-success");
      playAlertChime();
    }
  } catch (err) {
    statusEl.textContent = "Error: " + err.message;
  }
}

// Trigger Manual Scrape
async function triggerScrapeNow() {
  const btn = document.getElementById("btn-check-now");
  const icon = btn.querySelector(".spin-icon");
  const text = btn.querySelector(".btn-text");

  btn.disabled = true;
  icon.classList.add("active");
  text.textContent = "Checking...";

  try {
    const res = await fetch("/api/scrape-now", { method: "POST" });
    const data = await res.json();
    if (data.success) {
      const matchCount = data.result.new_matches || 0;
      const processed = data.result.new_jobs_processed || 0;
      if (matchCount > 0) {
        playAlertChime();
        if (Notification.permission === "granted" && currentSettings.enable_browser_push) {
          new Notification("🎯 New Sarkari Job Match!", {
            body: `${matchCount} newly discovered vacancies match your qualifications!`,
            icon: "/icons/icon-192.png"
          });
        }
      }
      text.textContent = `Done (${matchCount} matched)`;
      await loadJobs();
      await loadStats();
    } else {
      text.textContent = "Check Failed";
    }
  } catch (err) {
    text.textContent = "Error";
    console.error(err);
  } finally {
    setTimeout(() => {
      btn.disabled = false;
      icon.classList.remove("active");
      text.textContent = "Check Now";
    }, 2000);
  }
}

// Test Notification Dispatch
async function testNotification() {
  const btn = document.getElementById("btn-test-notification");
  btn.disabled = true;
  btn.textContent = "Sending...";
  playAlertChime();

  if (Notification.permission === "granted") {
    new Notification("🔔 Test Alert: Sarkari Result Tracker", {
      body: "Sample notification! Your qualifications: B.Ed, CTET, Graduate.",
      icon: "/icons/icon-192.png"
    });
  }

  try {
    const res = await fetch("/api/test-notification", { method: "POST" });
    const data = await res.json();
    alert("Test alert sent! Check your phone lockscreen via ntfy (Topic: " + currentSettings.ntfy_topic + ")");
  } catch (err) {
    alert("Test alert dispatch error: " + err.message);
  } finally {
    btn.disabled = false;
    btn.textContent = "Test Notification";
  }
}

function escapeHtml(str) {
  if (!str) return "";
  return String(str)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

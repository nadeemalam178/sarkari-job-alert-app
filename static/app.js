// Application State
let currentUser = null;
let currentToken = localStorage.getItem("sarkari_auth_token") || null;
let activeSourceFilter = "all";
let cachedMatchedJobs = [];
let cachedAllJobs = [];

// Audio Chime (Web Audio API)
function playAlertChime() {
  try {
    const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    const osc = audioCtx.createOscillator();
    const gain = audioCtx.createGain();
    osc.type = 'sine';
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

// PWA Service Worker
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/sw.js').catch(e => console.log('SW error:', e));
  });
}

// Helper to make authenticated requests
async function authFetch(url, options = {}) {
  const headers = options.headers || {};
  if (currentToken) {
    headers["Authorization"] = `Bearer ${currentToken}`;
  }
  options.headers = headers;
  return fetch(url, options);
}

// Document Ready Initialization
document.addEventListener("DOMContentLoaded", async () => {
  initTabs();
  initModal();
  initSourceFilters();

  // Try authenticating existing session
  await checkAuthStatus();

  // Load jobs and stats
  await loadStats();
  await loadJobs();

  // Event Listeners
  document.getElementById("btn-check-now").addEventListener("click", triggerScrapeNow);
  document.getElementById("btn-save-profile").addEventListener("click", saveProfileSettings);
  document.getElementById("btn-test-notification").addEventListener("click", testNotification);
  document.getElementById("btn-request-perm").addEventListener("click", requestNotificationPermission);
  document.getElementById("btn-logout").addEventListener("click", handleLogout);
  document.getElementById("btn-open-auth").addEventListener("click", () => openModal('register'));
  document.getElementById("btn-edit-quals-banner").addEventListener("click", () => {
    switchTab("tab-profile");
  });

  // Custom Keywords
  document.getElementById("btn-add-keyword").addEventListener("click", addCustomKeyword);
  document.getElementById("new-keyword-input").addEventListener("keypress", (e) => {
    if (e.key === "Enter") addCustomKeyword();
  });

  // Search Inputs
  document.getElementById("matched-search-input").addEventListener("input", filterMatchedJobs);
  document.getElementById("all-search-input").addEventListener("input", filterAllJobs);
});

// --- Tab Switching ---
function initTabs() {
  const tabs = document.querySelectorAll(".tab-btn");
  tabs.forEach(tab => {
    tab.addEventListener("click", () => {
      switchTab(tab.getAttribute("data-tab"));
    });
  });
}

function switchTab(targetId) {
  document.querySelectorAll(".tab-btn").forEach(t => {
    t.classList.toggle("active", t.getAttribute("data-tab") === targetId);
  });
  document.querySelectorAll(".tab-panel").forEach(p => {
    p.classList.toggle("active", p.id === targetId);
  });
}

// --- Source Filter Chips ---
function initSourceFilters() {
  const chips = document.querySelectorAll(".source-chip");
  chips.forEach(chip => {
    chip.addEventListener("click", () => {
      chips.forEach(c => c.classList.remove("active"));
      chip.classList.add("active");
      activeSourceFilter = chip.getAttribute("data-source");
      loadJobs();
    });
  });
}

// --- Auth & Session ---
async function checkAuthStatus() {
  if (currentToken) {
    try {
      const res = await authFetch("/api/auth/me");
      const data = await res.json();
      if (data.success && data.user) {
        setLoggedInUser(data.user);
        return;
      }
    } catch (e) {
      console.error(e);
    }
  }

  // Not authenticated: Prompt onboarding modal on first visit
  const guestDismissed = sessionStorage.getItem("sarkari_guest_dismissed");
  if (!guestDismissed) {
    openModal('register');
  }
}

function setLoggedInUser(user) {
  currentUser = user;
  document.getElementById("user-header-profile").style.display = "flex";
  document.getElementById("btn-open-auth").style.display = "none";
  document.getElementById("header-user-name").textContent = user.name;
  document.getElementById("header-user-state").textContent = user.state || "All India";
  document.getElementById("header-user-avatar").textContent = (user.name || "U")[0].toUpperCase();

  // Populate Banner
  const banner = document.getElementById("user-quals-banner");
  const chipsContainer = document.getElementById("banner-chips");
  chipsContainer.innerHTML = "";
  (user.qualifications || []).forEach(q => {
    const chip = document.createElement("span");
    chip.className = "banner-chip";
    chip.textContent = q;
    chipsContainer.appendChild(chip);
  });
  banner.style.display = (user.qualifications && user.qualifications.length > 0) ? "block" : "none";

  // Populate Profile Form
  document.getElementById("profile-name-input").value = user.name || "";
  document.getElementById("profile-state-select").value = user.state || "All India";
  document.querySelectorAll("input[name='qual']").forEach(cb => {
    cb.checked = (user.qualifications || []).includes(cb.value);
  });
  renderKeywordTags();

  // Populate Alert Settings
  const topic = user.ntfy_topic || "sarkari_job_alert_user";
  document.getElementById("ntfy-topic-input").value = topic;
  document.getElementById("ntfy-topic-display").textContent = topic;
  const link = document.getElementById("ntfy-link");
  if (link) {
    link.href = `https://ntfy.sh/${topic}`;
    link.textContent = `ntfy.sh/${topic}`;
  }
}

async function handleLogout() {
  await authFetch("/api/auth/logout", { method: "POST" });
  localStorage.removeItem("sarkari_auth_token");
  currentToken = null;
  currentUser = null;
  document.getElementById("user-header-profile").style.display = "none";
  document.getElementById("btn-open-auth").style.display = "inline-flex";
  document.getElementById("user-quals-banner").style.display = "none";
  openModal('login');
  loadJobs();
  loadStats();
}

// --- Onboarding Modal Handlers ---
function initModal() {
  const modal = document.getElementById("auth-modal");
  document.getElementById("btn-close-modal").addEventListener("click", () => {
    modal.style.display = "none";
    sessionStorage.setItem("sarkari_guest_dismissed", "true");
  });
  document.getElementById("link-guest-browse").addEventListener("click", (e) => {
    e.preventDefault();
    modal.style.display = "none";
    sessionStorage.setItem("sarkari_guest_dismissed", "true");
  });

  const btnTabReg = document.getElementById("btn-tab-register");
  const btnTabLogin = document.getElementById("btn-tab-login");
  const formReg = document.getElementById("form-register");
  const formLogin = document.getElementById("form-login");
  const heading = document.getElementById("modal-heading");

  btnTabReg.addEventListener("click", () => {
    btnTabReg.classList.add("active");
    btnTabLogin.classList.remove("active");
    formReg.style.display = "block";
    formLogin.style.display = "none";
    heading.textContent = "Quick Setup: Tell Us Your Qualifications";
  });

  btnTabLogin.addEventListener("click", () => {
    btnTabLogin.classList.add("active");
    btnTabReg.classList.remove("active");
    formReg.style.display = "none";
    formLogin.style.display = "block";
    heading.textContent = "Log In to Your Profile";
  });

  // Handle Register Submit
  formReg.addEventListener("submit", async (e) => {
    e.preventDefault();
    const name = document.getElementById("reg-name").value.trim();
    const email = document.getElementById("reg-email").value.trim();
    const password = document.getElementById("reg-password").value;
    const state = document.getElementById("reg-state").value;
    const quals = [];
    document.querySelectorAll("input[name='reg-qual']:checked").forEach(cb => quals.push(cb.value));

    const errEl = document.getElementById("reg-error-msg");
    errEl.textContent = "";

    try {
      const res = await fetch("/api/auth/register", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          name, email, password, state,
          qualifications: quals.length > 0 ? quals : ["GRADUATE"]
        })
      });
      const data = await res.json();
      if (data.success) {
        currentToken = data.token;
        localStorage.setItem("sarkari_auth_token", data.token);
        setLoggedInUser(data.user);
        modal.style.display = "none";
        playAlertChime();
        await loadJobs();
        await loadStats();
      } else {
        errEl.textContent = data.error || "Registration failed";
      }
    } catch (err) {
      errEl.textContent = err.message;
    }
  });

  // Handle Login Submit
  formLogin.addEventListener("submit", async (e) => {
    e.preventDefault();
    const email = document.getElementById("login-email").value.trim();
    const password = document.getElementById("login-password").value;
    const errEl = document.getElementById("login-error-msg");
    errEl.textContent = "";

    try {
      const res = await fetch("/api/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password })
      });
      const data = await res.json();
      if (data.success) {
        currentToken = data.token;
        localStorage.setItem("sarkari_auth_token", data.token);
        setLoggedInUser(data.user);
        modal.style.display = "none";
        playAlertChime();
        await loadJobs();
        await loadStats();
      } else {
        errEl.textContent = data.error || "Invalid login credentials";
      }
    } catch (err) {
      errEl.textContent = err.message;
    }
  });
}

function openModal(tab = 'register') {
  const modal = document.getElementById("auth-modal");
  modal.style.display = "flex";
  if (tab === 'register') {
    document.getElementById("btn-tab-register").click();
  } else {
    document.getElementById("btn-tab-login").click();
  }
}

// --- Jobs & Stats Fetching ---
async function loadJobs() {
  try {
    const srcParam = activeSourceFilter !== "all" ? `&source=${encodeURIComponent(activeSourceFilter)}` : "";

    // 1. Matched Jobs for user
    const resMatched = await authFetch(`/api/jobs?matched_only=true&limit=100${srcParam}`);
    const dataMatched = await resMatched.json();
    cachedMatchedJobs = dataMatched.jobs || [];
    renderJobsList(cachedMatchedJobs, "matched-jobs-list", true);

    // 2. All Jobs
    const resAll = await authFetch(`/api/jobs?matched_only=false&limit=100${srcParam}`);
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

async function loadStats() {
  try {
    const res = await authFetch("/api/stats");
    const data = await res.json();
    if (data.success && data.stats) {
      document.getElementById("stat-matched-count").textContent = data.stats.total_matched || 0;
      document.getElementById("stat-total-count").textContent = data.stats.total_checked || 0;
      const srcCount = Object.keys(data.stats.sources || {}).length || 3;
      document.getElementById("stat-sources-count").textContent = `${srcCount} Portals Live`;
    }
  } catch (err) {
    console.error("Failed to load stats:", err);
  }
}

// Render Job Cards with Source Badges
function renderJobsList(jobs, containerId, isMatchedTab) {
  const container = document.getElementById(containerId);
  if (!container) return;

  if (jobs.length === 0) {
    container.innerHTML = `
      <div class="empty-state">
        <p>No jobs found for the selected criteria.</p>
        ${isMatchedTab ? '<p style="margin-top:6px; font-size:0.85rem;">Tip: Open <strong>My Qualifications</strong> tab to select degrees or add custom keywords!</p>' : ''}
      </div>
    `;
    return;
  }

  container.innerHTML = jobs.map(job => {
    // Determine Source Badge style
    let sourceBadge = `<span class="source-badge source-sr">SarkariResult</span>`;
    if (job.source === "FreeJobAlert") {
      sourceBadge = `<span class="source-badge source-fja">FreeJobAlert</span>`;
    } else if (job.source === "RojgarResult") {
      sourceBadge = `<span class="source-badge source-rr">RojgarResult</span>`;
    }

    const matchedTags = (job.matched_keywords || []).map(k => `<span class="tag-badge tag-matched">MATCH: ${k}</span>`).join(" ");
    const otherTags = (job.qualifications_found || [])
      .filter(q => !(job.matched_keywords || []).includes(q))
      .slice(0, 3)
      .map(k => `<span class="tag-badge tag-other">${k}</span>`).join(" ");

    return `
      <article class="job-card ${job.is_matched ? 'is-matched-card' : ''}">
        <div class="job-card-top">
          <div class="job-title-row">
            ${sourceBadge}
            <h3 class="job-title">${escapeHtml(job.title)}</h3>
          </div>
          <a href="${escapeHtml(job.url)}" target="_blank" rel="noopener" class="btn btn-sm btn-primary">
            Apply / View on Source &rarr;
          </a>
        </div>
        
        ${job.org ? `<div class="job-org">🏢 ${escapeHtml(job.org)}</div>` : ''}

        <div class="job-tags-row">
          ${matchedTags}
          ${otherTags}
        </div>

        <div class="job-snippet">
          ${escapeHtml(job.eligibility_snippet || "Check official source notification for details.")}
        </div>

        <div class="job-card-bottom">
          <div class="job-date-info">
            📅 Last Date: <span class="date-val">${escapeHtml(job.last_date || "Refer notification")}</span>
          </div>
          <span style="font-size:0.75rem; color:var(--text-dim);">Portal: ${escapeHtml(job.source || "SarkariResult")}</span>
        </div>
      </article>
    `;
  }).join("");
}

// Live Search Filters
function filterMatchedJobs(e) {
  const query = e.target.value.toLowerCase().trim();
  const filtered = cachedMatchedJobs.filter(j => 
    j.title.toLowerCase().includes(query) ||
    (j.org && j.org.toLowerCase().includes(query)) ||
    (j.source && j.source.toLowerCase().includes(query)) ||
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
    (j.source && j.source.toLowerCase().includes(query)) ||
    (j.qualifications_found && j.qualifications_found.some(k => k.toLowerCase().includes(query))) ||
    (j.eligibility_snippet && j.eligibility_snippet.toLowerCase().includes(query))
  );
  renderJobsList(filtered, "all-jobs-list", false);
}

// Custom Keywords
function renderKeywordTags() {
  const container = document.getElementById("keywords-tags-container");
  container.innerHTML = "";
  const keywords = (currentUser && currentUser.custom_keywords) ? currentUser.custom_keywords : [];
  keywords.forEach((kw, index) => {
    const tag = document.createElement("span");
    tag.className = "keyword-tag";
    tag.innerHTML = `${kw} <span class="remove-tag" data-index="${index}">&times;</span>`;
    container.appendChild(tag);
  });

  container.querySelectorAll(".remove-tag").forEach(btn => {
    btn.addEventListener("click", (e) => {
      const idx = parseInt(e.target.getAttribute("data-index"));
      if (currentUser && currentUser.custom_keywords) {
        currentUser.custom_keywords.splice(idx, 1);
        renderKeywordTags();
      }
    });
  });
}

function addCustomKeyword() {
  const input = document.getElementById("new-keyword-input");
  const val = input.value.trim().toUpperCase();
  if (val) {
    if (!currentUser) currentUser = { custom_keywords: [] };
    if (!currentUser.custom_keywords) currentUser.custom_keywords = [];
    if (!currentUser.custom_keywords.includes(val)) {
      currentUser.custom_keywords.push(val);
      renderKeywordTags();
      input.value = "";
    }
  }
}

// Save Profile & Re-filter
async function saveProfileSettings() {
  const name = document.getElementById("profile-name-input").value.trim();
  const state = document.getElementById("profile-state-select").value;
  const quals = [];
  document.querySelectorAll("input[name='qual']:checked").forEach(cb => quals.push(cb.value));

  const statusEl = document.getElementById("save-profile-status");
  statusEl.textContent = "Updating profile & re-matching jobs...";
  statusEl.className = "status-msg";

  if (!currentToken) {
    // If not logged in, prompt registration modal
    openModal('register');
    return;
  }

  try {
    const res = await authFetch("/api/auth/profile", {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        name,
        state,
        qualifications: quals,
        custom_keywords: currentUser ? currentUser.custom_keywords : []
      })
    });
    const data = await res.json();
    if (data.success) {
      setLoggedInUser(data.user);
      statusEl.textContent = "Profile saved! Jobs updated.";
      statusEl.classList.add("status-success");
      playAlertChime();
      await loadJobs();
      await loadStats();
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
  text.textContent = "Scraping 3 Portals...";

  try {
    const res = await authFetch("/api/scrape-now", { method: "POST" });
    const data = await res.json();
    if (data.success) {
      playAlertChime();
      text.textContent = "Updated!";
      await loadJobs();
      await loadStats();
    } else {
      text.textContent = "Failed";
    }
  } catch (err) {
    text.textContent = "Error";
    console.error(err);
  } finally {
    setTimeout(() => {
      btn.disabled = false;
      icon.classList.remove("active");
      text.textContent = "Refresh";
    }, 2000);
  }
}

// Test Notification Dispatch
async function testNotification() {
  const btn = document.getElementById("btn-test-notification");
  btn.disabled = true;
  btn.textContent = "Sending Alert...";
  playAlertChime();

  try {
    const res = await authFetch("/api/test-notification", { method: "POST" });
    const data = await res.json();
    alert(`🎯 Test alert sent to topic '${data.topic}'!\nCheck your phone lockscreen via the ntfy app.`);
  } catch (err) {
    alert("Alert dispatch error: " + err.message);
  } finally {
    btn.disabled = false;
    btn.textContent = "Test Notification";
  }
}

// Browser Push Notification Permission
async function requestNotificationPermission() {
  if (!("Notification" in window)) {
    alert("This browser does not support desktop notifications.");
    return;
  }
  const perm = await Notification.requestPermission();
  if (perm === "granted") {
    new Notification("🎯 Sarkari Job Alert", {
      body: "Browser notifications enabled! You will now receive instant alerts.",
      icon: "/icons/icon-192.png"
    });
    playAlertChime();
  } else {
    alert("Notification permission denied in browser settings.");
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

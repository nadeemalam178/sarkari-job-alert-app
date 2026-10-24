// Application State
let currentUser = null;
let currentToken = localStorage.getItem("sarkari_auth_token") || null;
let activeSourceFilter = "all";
let cachedMatchedJobs = [];
let cachedAllJobs = [];
let filteredMatchedList = [];
let filteredAllList = [];
let pageMatched = 1;
let pageAll = 1;
const PAGE_SIZE = 6;
let masterQualifications = [];
let selectedDegrees = []; // Codes of degrees user selected, e.g. ['B.ED', 'CTET', 'GRADUATE']

// Web Audio API Chime
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

// DOM Ready
document.addEventListener("DOMContentLoaded", async () => {
  initTabs();
  initLoginModal();
  initSourceFilters();
  await loadQualificationsMaster();

  // Try authenticating existing session
  await checkAuthStatus();

  // Load jobs and stats
  await loadStats();
  await loadJobs();

  // Event Listeners
  document.getElementById("btn-check-now").addEventListener("click", triggerScrapeNow);
  document.getElementById("btn-save-education").addEventListener("click", saveEducationProfile);
  document.getElementById("btn-test-notification").addEventListener("click", testNotification);
  document.getElementById("btn-request-perm").addEventListener("click", requestNotificationPermission);
  document.getElementById("btn-logout").addEventListener("click", handleLogout);
  document.getElementById("btn-open-login").addEventListener("click", () => openLoginModal('login'));
  document.getElementById("btn-edit-edu-header").addEventListener("click", () => switchTab("tab-education"));
  document.getElementById("btn-edit-quals-banner").addEventListener("click", () => switchTab("tab-education"));

  // Drawer & Mobile Dock Initialization
  initDrawerAndDock();

  // Degree Search & Autosuggest
  initDegreeSearch();

  // Search Inputs
  document.getElementById("matched-search-input").addEventListener("input", filterMatchedJobs);
  document.getElementById("all-search-input").addEventListener("input", filterAllJobs);
});

// --- Tab Switching with Bottom Dock Synchronization ---
function initTabs() {
  const tabs = document.querySelectorAll(".tab-btn");
  tabs.forEach(tab => {
    tab.addEventListener("click", () => {
      switchTab(tab.getAttribute("data-tab"));
    });
  });
}

function switchTab(targetId) {
  // Desktop tabs
  document.querySelectorAll(".tab-btn").forEach(t => {
    t.classList.toggle("active", t.getAttribute("data-tab") === targetId);
  });
  // Tab panels
  document.querySelectorAll(".tab-panel").forEach(p => {
    p.classList.toggle("active", p.id === targetId);
  });
  // Bottom Dock items
  document.querySelectorAll(".dock-item[data-tab]").forEach(d => {
    d.classList.toggle("active", d.getAttribute("data-tab") === targetId);
  });
  // Drawer items
  document.querySelectorAll(".drawer-nav-item[data-tab]").forEach(item => {
    item.classList.toggle("active", item.getAttribute("data-tab") === targetId);
  });

  window.scrollTo({ top: 0, behavior: 'smooth' });
}

// --- Side Panel Drawer & Mobile Dock ---
function initDrawerAndDock() {
  const drawer = document.getElementById("side-panel-drawer");
  const backdrop = document.getElementById("drawer-backdrop");
  const btnToggle = document.getElementById("btn-toggle-drawer");
  const btnClose = document.getElementById("btn-close-drawer");
  const btnDockMenu = document.getElementById("btn-dock-menu");

  const openDrawer = () => {
    drawer.classList.add("open");
    backdrop.classList.add("active");
  };

  const closeDrawer = () => {
    drawer.classList.remove("open");
    backdrop.classList.remove("active");
  };

  if (btnToggle) btnToggle.addEventListener("click", openDrawer);
  if (btnDockMenu) btnDockMenu.addEventListener("click", openDrawer);
  if (btnClose) btnClose.addEventListener("click", closeDrawer);
  if (backdrop) backdrop.addEventListener("click", closeDrawer);

  // Drawer Nav Items
  document.querySelectorAll(".drawer-nav-item[data-tab]").forEach(item => {
    item.addEventListener("click", () => {
      const tabId = item.getAttribute("data-tab");
      switchTab(tabId);
      closeDrawer();
    });
  });

  // Dock Items
  document.querySelectorAll(".dock-item[data-tab]").forEach(item => {
    item.addEventListener("click", () => {
      const tabId = item.getAttribute("data-tab");
      switchTab(tabId);
    });
  });

  // Drawer Portal Filter Chips
  document.querySelectorAll(".drawer-portal-chip").forEach(chip => {
    chip.addEventListener("click", () => {
      document.querySelectorAll(".drawer-portal-chip").forEach(c => c.classList.remove("active"));
      chip.classList.add("active");
      activeSourceFilter = chip.getAttribute("data-source");

      // Sync with top desktop chips
      document.querySelectorAll(".source-chip").forEach(sc => {
        sc.classList.toggle("active", sc.getAttribute("data-source") === activeSourceFilter);
      });

      loadJobs();
      closeDrawer();
    });
  });

  // Drawer Copy Wi-Fi IP
  const copyBtn = document.getElementById("btn-drawer-copy-ip");
  if (copyBtn) {
    copyBtn.addEventListener("click", () => {
      const ipText = document.getElementById("drawer-wifi-ip").textContent;
      navigator.clipboard.writeText(ipText).then(() => {
        copyBtn.textContent = "Copied!";
        setTimeout(() => { copyBtn.textContent = "Copy URL"; }, 2000);
      });
    });
  }

  // Header Phone Link Button
  const phoneBtn = document.getElementById("btn-phone-connect");
  if (phoneBtn) {
    phoneBtn.addEventListener("click", () => {
      alert("📱 Mobile Phone Link:\n\nConnect your phone to same Wi-Fi and open:\nhttp://192.168.1.11:5000\n\nor check the Expo app setup to debug via Expo Go!");
    });
  }

  // Drawer Login & Logout
  const drawerLogin = document.getElementById("drawer-btn-login");
  const drawerLogout = document.getElementById("drawer-btn-logout");
  if (drawerLogin) {
    drawerLogin.addEventListener("click", () => {
      closeDrawer();
      openLoginModal('login');
    });
  }
  if (drawerLogout) {
    drawerLogout.addEventListener("click", () => {
      closeDrawer();
      handleLogout();
    });
  }
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

// --- Load Master Qualifications Catalog ---
async function loadQualificationsMaster() {
  try {
    const res = await fetch("/api/qualifications-master");
    const data = await res.json();
    if (data.success && data.qualifications) {
      masterQualifications = data.qualifications;
      renderQualificationsCategories();
    }
  } catch (err) {
    console.error("Failed loading master qualifications:", err);
  }
}

// Render Browse Categories Accordion
function renderQualificationsCategories() {
  const container = document.getElementById("deg-categories-list");
  if (!container) return;
  container.innerHTML = "";

  const groups = {};
  masterQualifications.forEach(q => {
    if (!groups[q.category]) groups[q.category] = [];
    groups[q.category].push(q);
  });

  for (const [catName, list] of Object.entries(groups)) {
    const catBox = document.createElement("div");
    catBox.className = "deg-cat-box";

    const header = document.createElement("div");
    header.className = "deg-cat-header";
    header.textContent = catName;
    catBox.appendChild(header);

    const chipsContainer = document.createElement("div");
    chipsContainer.className = "deg-cat-chips";

    list.forEach(item => {
      const btn = document.createElement("button");
      btn.type = "button";
      btn.className = `quick-add-chip ${selectedDegrees.includes(item.code) ? 'added' : ''}`;
      btn.textContent = `+ ${item.code}`;
      btn.title = item.name;
      btn.addEventListener("click", () => {
        toggleDegreeSelection(item.code);
      });
      chipsContainer.appendChild(btn);
    });

    catBox.appendChild(chipsContainer);
    container.appendChild(catBox);
  }
}

// --- Degree Search & Autosuggest ---
function initDegreeSearch() {
  const searchInput = document.getElementById("deg-search-input");
  const dropdown = document.getElementById("deg-search-dropdown");

  searchInput.addEventListener("input", (e) => {
    const query = e.target.value.toLowerCase().trim();
    if (!query) {
      dropdown.style.display = "none";
      return;
    }

    const matches = masterQualifications.filter(item => 
      item.code.toLowerCase().includes(query) ||
      item.name.toLowerCase().includes(query) ||
      item.category.toLowerCase().includes(query)
    );

    if (matches.length === 0) {
      dropdown.innerHTML = `<div class="deg-dropdown-item" style="color:var(--text-dim); cursor:default;">No matching Indian qualification found. Press Enter to add custom keyword.</div>`;
      dropdown.style.display = "block";
      return;
    }

    dropdown.innerHTML = matches.slice(0, 8).map(m => `
      <div class="deg-dropdown-item" data-code="${m.code}">
        <div>
          <strong>${escapeHtml(m.code)}</strong> - <span style="color:#cbd5e1;">${escapeHtml(m.name)}</span>
        </div>
        <span class="deg-item-cat">${escapeHtml(m.category)}</span>
      </div>
    `).join("");
    dropdown.style.display = "block";

    dropdown.querySelectorAll(".deg-dropdown-item[data-code]").forEach(el => {
      el.addEventListener("click", () => {
        const code = el.getAttribute("data-code");
        addDegreeSelection(code);
        searchInput.value = "";
        dropdown.style.display = "none";
      });
    });
  });

  // Handle custom keyword on Enter
  searchInput.addEventListener("keypress", (e) => {
    if (e.key === "Enter") {
      const val = searchInput.value.trim().toUpperCase();
      if (val) {
        addDegreeSelection(val);
        searchInput.value = "";
        dropdown.style.display = "none";
      }
    }
  });

  // Close dropdown on outside click
  document.addEventListener("click", (e) => {
    if (!searchInput.contains(e.target) && !dropdown.contains(e.target)) {
      dropdown.style.display = "none";
    }
  });
}

function addDegreeSelection(code) {
  if (!selectedDegrees.includes(code)) {
    selectedDegrees.push(code);
    renderSelectedDegreesChips();
    renderQualificationsCategories();
  }
}

function removeDegreeSelection(code) {
  selectedDegrees = selectedDegrees.filter(c => c !== code);
  renderSelectedDegreesChips();
  renderQualificationsCategories();
}

function toggleDegreeSelection(code) {
  if (selectedDegrees.includes(code)) {
    removeDegreeSelection(code);
  } else {
    addDegreeSelection(code);
  }
}

function renderSelectedDegreesChips() {
  const container = document.getElementById("selected-deg-chips");
  if (!container) return;

  if (selectedDegrees.length === 0) {
    container.innerHTML = `<span class="hint-text">No specific degrees added yet. Use search or quick chips above.</span>`;
    return;
  }

  container.innerHTML = selectedDegrees.map(code => `
    <span class="deg-chip">
      ${escapeHtml(code)}
      <span class="deg-chip-remove" data-code="${escapeHtml(code)}">&times;</span>
    </span>
  `).join("");

  container.querySelectorAll(".deg-chip-remove").forEach(btn => {
    btn.addEventListener("click", (e) => {
      e.stopPropagation();
      const code = btn.getAttribute("data-code");
      removeDegreeSelection(code);
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

  // Not authenticated: Prompt simple login modal on first visit
  const guestDismissed = sessionStorage.getItem("sarkari_guest_dismissed");
  if (!guestDismissed) {
    openLoginModal('login');
  }
}

function setLoggedInUser(user) {
  currentUser = user;
  document.getElementById("user-header-profile").style.display = "flex";
  document.getElementById("btn-open-login").style.display = "none";
  document.getElementById("header-user-name").textContent = user.name;
  document.getElementById("header-user-level").textContent = user.highest_qualification || "Graduate";
  document.getElementById("header-user-avatar").textContent = (user.name || "U")[0].toUpperCase();

  // Populate Banner
  const banner = document.getElementById("user-quals-banner");
  const chipsContainer = document.getElementById("banner-chips");
  chipsContainer.innerHTML = "";
  
  const displayChips = [user.highest_qualification || "Graduate", ...(user.qualifications || [])];
  const uniqueChips = listUnique(displayChips);

  uniqueChips.forEach(q => {
    const chip = document.createElement("span");
    chip.className = "banner-chip";
    chip.textContent = q;
    chipsContainer.appendChild(chip);
  });
  banner.style.display = "block";

  // Populate Education Form
  document.getElementById("profile-name-input").value = user.name || "";
  document.getElementById("profile-state-select").value = user.state || "All India";
  
  // Set highest level radio
  const levelVal = user.highest_qualification || "Graduate";
  const radio = document.querySelector(`input[name="highest-level"][value="${levelVal}"]`);
  if (radio) radio.checked = true;

  // Set selected degrees
  selectedDegrees = user.qualifications || ["GRADUATE"];
  renderSelectedDegreesChips();
  renderQualificationsCategories();

  // Update Drawer User Info
  const drawerName = document.getElementById("drawer-user-name");
  const drawerLevel = document.getElementById("drawer-user-level");
  const drawerState = document.getElementById("drawer-user-state");
  const drawerAvatar = document.getElementById("drawer-avatar");
  const drawerLogin = document.getElementById("drawer-btn-login");
  const drawerLogout = document.getElementById("drawer-btn-logout");

  if (drawerName) drawerName.textContent = user.name;
  if (drawerLevel) drawerLevel.textContent = user.highest_qualification || "Graduate";
  if (drawerState) drawerState.textContent = user.state || "All India";
  if (drawerAvatar) drawerAvatar.textContent = (user.name || "U")[0].toUpperCase();
  if (drawerLogin) drawerLogin.style.display = "none";
  if (drawerLogout) drawerLogout.style.display = "block";

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
  document.getElementById("btn-open-login").style.display = "inline-flex";
  document.getElementById("user-quals-banner").style.display = "none";

  // Reset Drawer User Info
  const drawerName = document.getElementById("drawer-user-name");
  const drawerLevel = document.getElementById("drawer-user-level");
  const drawerAvatar = document.getElementById("drawer-avatar");
  const drawerLogin = document.getElementById("drawer-btn-login");
  const drawerLogout = document.getElementById("drawer-btn-logout");
  if (drawerName) drawerName.textContent = "Guest Candidate";
  if (drawerLevel) drawerLevel.textContent = "Select Qualifications";
  if (drawerAvatar) drawerAvatar.textContent = "U";
  if (drawerLogin) drawerLogin.style.display = "block";
  if (drawerLogout) drawerLogout.style.display = "none";

  selectedDegrees = ["GRADUATE"];
  renderSelectedDegreesChips();
  openLoginModal('login');
  loadJobs();
  loadStats();
}

// --- Login & Registration Modal ---
function initLoginModal() {
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

  const btnTabLogin = document.getElementById("btn-tab-login");
  const btnTabReg = document.getElementById("btn-tab-register");
  const formLogin = document.getElementById("form-login");
  const formReg = document.getElementById("form-register");
  const heading = document.getElementById("auth-modal-heading");

  btnTabLogin.addEventListener("click", () => {
    btnTabLogin.classList.add("active");
    btnTabReg.classList.remove("active");
    formLogin.style.display = "block";
    formReg.style.display = "none";
    heading.textContent = "Log In to Your Account";
  });

  btnTabReg.addEventListener("click", () => {
    btnTabReg.classList.add("active");
    btnTabLogin.classList.remove("active");
    formReg.style.display = "block";
    formLogin.style.display = "none";
    heading.textContent = "Create Candidate Account";
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

  // Handle Register Submit
  formReg.addEventListener("submit", async (e) => {
    e.preventDefault();
    const name = document.getElementById("reg-name").value.trim();
    const email = document.getElementById("reg-email").value.trim();
    const password = document.getElementById("reg-password").value;
    const errEl = document.getElementById("reg-error-msg");
    errEl.textContent = "";

    try {
      const res = await fetch("/api/auth/register", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          name, email, password,
          highest_qualification: "Graduate",
          qualifications: ["GRADUATE"]
        })
      });
      const data = await res.json();
      if (data.success) {
        currentToken = data.token;
        localStorage.setItem("sarkari_auth_token", data.token);
        setLoggedInUser(data.user);
        modal.style.display = "none";
        playAlertChime();
        
        // Immediate Step 2: Switch straight to "My Education" tab so they set their degrees!
        switchTab("tab-education");
        alert(`Welcome, ${name}! Please set your Highest Qualification and Specific Degrees below.`);
        await loadJobs();
        await loadStats();
      } else {
        errEl.textContent = data.error || "Registration failed";
      }
    } catch (err) {
      errEl.textContent = err.message;
    }
  });
}

function openLoginModal(tab = 'login') {
  const modal = document.getElementById("auth-modal");
  modal.style.display = "flex";
  if (tab === 'login') {
    document.getElementById("btn-tab-login").click();
  } else {
    document.getElementById("btn-tab-register").click();
  }
}

// --- Save Education Profile ---
async function saveEducationProfile() {
  const name = document.getElementById("profile-name-input").value.trim();
  const state = document.getElementById("profile-state-select").value;
  const levelEl = document.querySelector('input[name="highest-level"]:checked');
  const highestLevel = levelEl ? levelEl.value : "Graduate";

  const statusEl = document.getElementById("save-edu-status");
  statusEl.textContent = "Updating education profile & matching jobs...";
  statusEl.className = "status-msg";

  if (!currentToken) {
    openLoginModal('login');
    return;
  }

  try {
    const res = await authFetch("/api/auth/profile", {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        name,
        state,
        highest_qualification: highestLevel,
        qualifications: selectedDegrees.length > 0 ? selectedDegrees : ["GRADUATE"]
      })
    });
    const data = await res.json();
    if (data.success) {
      setLoggedInUser(data.user);
      statusEl.textContent = "Education profile saved! Showing matching jobs.";
      statusEl.classList.add("status-success");
      playAlertChime();
      await loadJobs();
      await loadStats();
      setTimeout(() => {
        switchTab("tab-matched");
      }, 700);
    }
  } catch (err) {
    statusEl.textContent = "Error: " + err.message;
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
    filteredMatchedList = [...cachedMatchedJobs];
    pageMatched = 1;
    renderPaginatedJobs(filteredMatchedList, "matched-jobs-list", "matched-pagination", pageMatched, (newPage) => {
      pageMatched = newPage;
      renderPaginatedJobs(filteredMatchedList, "matched-jobs-list", "matched-pagination", pageMatched, arguments.callee);
    }, true);

    // 2. All Jobs
    const resAll = await authFetch(`/api/jobs?matched_only=false&limit=100${srcParam}`);
    const dataAll = await resAll.json();
    cachedAllJobs = dataAll.jobs || [];
    filteredAllList = [...cachedAllJobs];
    pageAll = 1;
    renderPaginatedJobs(filteredAllList, "all-jobs-list", "all-pagination", pageAll, (newPage) => {
      pageAll = newPage;
      renderPaginatedJobs(filteredAllList, "all-jobs-list", "all-pagination", pageAll, arguments.callee);
    }, false);

    document.getElementById("badge-matched").textContent = cachedMatchedJobs.length;
    document.getElementById("stat-matched-count").textContent = cachedMatchedJobs.length;
    document.getElementById("stat-total-count").textContent = cachedAllJobs.length;

    const dockBadge = document.getElementById("dock-badge-matched");
    if (dockBadge) dockBadge.textContent = cachedMatchedJobs.length;
    const drawerBadge = document.getElementById("drawer-badge-matched");
    if (drawerBadge) drawerBadge.textContent = cachedMatchedJobs.length;
  } catch (err) {
    console.error("Failed to load jobs:", err);
  }
}

// Render Job Cards with Pagination & Sarkari Result Priority Badges
function renderPaginatedJobs(jobs, containerId, paginationId, currentPage, onPageChange, isMatchedTab) {
  const container = document.getElementById(containerId);
  const paginationContainer = document.getElementById(paginationId);
  if (!container) return;

  if (jobs.length === 0) {
    container.innerHTML = `
      <div class="empty-state">
        <p>No active vacancies matching your criteria.</p>
        ${isMatchedTab ? '<p style="margin-top:6px; font-size:0.85rem;">Tip: Open <strong>My Education & Qualifications</strong> tab to add degrees or change level!</p>' : ''}
      </div>
    `;
    if (paginationContainer) paginationContainer.innerHTML = "";
    return;
  }

  // Slice jobs for current page
  const totalPages = Math.ceil(jobs.length / PAGE_SIZE);
  const validPage = Math.max(1, Math.min(currentPage, totalPages));
  const startIndex = (validPage - 1) * PAGE_SIZE;
  const pageSlice = jobs.slice(startIndex, startIndex + PAGE_SIZE);

  container.innerHTML = pageSlice.map(job => {
    let sourceBadge = `<span class="source-badge source-sr">SarkariResult ★</span>`;
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
          ${escapeHtml(job.eligibility_snippet || "Check official advertisement on source for eligibility details.")}
        </div>

        <div class="job-card-bottom">
          <div class="job-date-info">
            📅 Last Date: <span class="date-val">${escapeHtml(job.last_date || "Refer notification")}</span>
          </div>
          <span style="font-size:0.75rem; color:var(--text-dim);">Source: ${escapeHtml(job.source || "SarkariResult")}</span>
        </div>
      </article>
    `;
  }).join("");

  // Render pagination bar
  if (paginationContainer) {
    if (totalPages <= 1) {
      paginationContainer.innerHTML = "";
    } else {
      let pagesHtml = `<button class="page-btn" ${validPage === 1 ? 'disabled' : ''} data-p="${validPage - 1}">&larr; Prev</button>`;
      for (let p = 1; p <= totalPages; p++) {
        pagesHtml += `<button class="page-btn ${p === validPage ? 'active' : ''}" data-p="${p}">${p}</button>`;
      }
      pagesHtml += `<button class="page-btn" ${validPage === totalPages ? 'disabled' : ''} data-p="${validPage + 1}">Next &rarr;</button>`;
      pagesHtml += `<span class="page-info">Page ${validPage} of ${totalPages} (${jobs.length} jobs)</span>`;

      paginationContainer.innerHTML = pagesHtml;

      paginationContainer.querySelectorAll(".page-btn[data-p]").forEach(btn => {
        btn.addEventListener("click", () => {
          const targetP = parseInt(btn.getAttribute("data-p"));
          if (!isNaN(targetP) && targetP >= 1 && targetP <= totalPages) {
            renderPaginatedJobs(jobs, containerId, paginationId, targetP, onPageChange, isMatchedTab);
            container.scrollIntoView({ behavior: 'smooth', block: 'start' });
          }
        });
      });
    }
  }
}

// Live Search Filters with Pagination Reset
function filterMatchedJobs(e) {
  const query = e.target.value.toLowerCase().trim();
  filteredMatchedList = cachedMatchedJobs.filter(j => 
    j.title.toLowerCase().includes(query) ||
    (j.org && j.org.toLowerCase().includes(query)) ||
    (j.source && j.source.toLowerCase().includes(query)) ||
    (j.matched_keywords && j.matched_keywords.some(k => k.toLowerCase().includes(query))) ||
    (j.eligibility_snippet && j.eligibility_snippet.toLowerCase().includes(query))
  );
  pageMatched = 1;
  renderPaginatedJobs(filteredMatchedList, "matched-jobs-list", "matched-pagination", pageMatched, null, true);
}

function filterAllJobs(e) {
  const query = e.target.value.toLowerCase().trim();
  filteredAllList = cachedAllJobs.filter(j => 
    j.title.toLowerCase().includes(query) ||
    (j.org && j.org.toLowerCase().includes(query)) ||
    (j.source && j.source.toLowerCase().includes(query)) ||
    (j.qualifications_found && j.qualifications_found.some(k => k.toLowerCase().includes(query))) ||
    (j.eligibility_snippet && j.eligibility_snippet.toLowerCase().includes(query))
  );
  pageAll = 1;
  renderPaginatedJobs(filteredAllList, "all-jobs-list", "all-pagination", pageAll, null, false);
}

// Trigger Manual Scrape
async function triggerScrapeNow() {
  const btn = document.getElementById("btn-check-now");
  const icon = btn.querySelector(".spin-icon");
  const text = btn.querySelector(".btn-text");

  btn.disabled = true;
  icon.classList.add("active");
  text.textContent = "Scanning...";

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
    alert(`🎯 Test alert dispatched to topic '${data.topic}'!\nCheck your phone lock screen via the ntfy app.`);
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

function listUnique(arr) {
  return listUniqueFilter(arr);
}

function listUniqueFilter(arr) {
  const seen = new Set();
  const out = [];
  for (const x of arr) {
    if (x && !seen.has(x.toUpperCase())) {
      seen.add(x.toUpperCase());
      out.push(x);
    }
  }
  return out;
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

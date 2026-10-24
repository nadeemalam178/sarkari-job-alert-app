// ========================================================
// SARKARI JOB ALERT - MODERN FRONTEND APPLICATION
// Clean, Uncluttered, Responsive & Multi-Theme Controller
// ========================================================

// Application State
let currentUser = null;
let currentToken = localStorage.getItem("sarkari_auth_token") || null;
let currentTheme = localStorage.getItem("sarkari_theme") || "auto"; // "auto" | "light" | "dark"
let activeJobSubtab = "matched"; // "matched" | "all"
let activeSourceFilter = "all"; // "all" | "SarkariResult" | "FreeJobAlert" | "RojgarResult"
let cachedMatchedJobs = [];
let cachedAllJobs = [];
let filteredJobsList = [];
let currentPage = 1;
const PAGE_SIZE = 6;
let masterQualifications = [];
let selectedDegrees = []; // e.g. ['B.ED', 'CTET', 'GRADUATE']

// --- DOM Ready ---
document.addEventListener("DOMContentLoaded", async () => {
  initTheme();
  initNavigation();
  initDrawer();
  initJobControls();
  initLoginModal();
  await loadQualificationsMaster();
  await checkAuthStatus();
  await loadJobs();

  // Global Header Actions
  document.getElementById("btn-check-now")?.addEventListener("click", triggerScrapeNow);
  document.getElementById("btn-save-education")?.addEventListener("click", saveEducationProfile);
  document.getElementById("btn-test-notification")?.addEventListener("click", testNotification);
  document.getElementById("btn-request-perm")?.addEventListener("click", requestNotificationPermission);
  document.getElementById("btn-open-login")?.addEventListener("click", () => openLoginModal('login'));
  document.getElementById("user-header-profile")?.addEventListener("click", () => {
    if (currentUser) {
      openDrawer();
    } else {
      openLoginModal('login');
    }
  });

  document.getElementById("btn-strip-edit-edu")?.addEventListener("click", () => switchMainTab("tab-education"));
});

// ========================================================
// 1. THEME CONTROLLER (DEVICE ADAPTIVE + MANUAL TOGGLE)
// ========================================================
function initTheme() {
  applyTheme(currentTheme);

  // Header quick theme toggle
  document.getElementById("btn-theme-toggle")?.addEventListener("click", () => {
    if (currentTheme === "auto") {
      setTheme("light");
    } else if (currentTheme === "light") {
      setTheme("dark");
    } else {
      setTheme("auto");
    }
  });

  // Drawer theme choice buttons
  document.querySelectorAll(".theme-choice-btn").forEach(btn => {
    btn.addEventListener("click", () => {
      const val = btn.getAttribute("data-theme-val");
      setTheme(val);
    });
  });

  // Listen to OS system theme changes when in "auto" mode
  window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", (e) => {
    if (currentTheme === "auto") {
      applyTheme("auto");
    }
  });
}

function setTheme(theme) {
  currentTheme = theme;
  localStorage.setItem("sarkari_theme", theme);
  applyTheme(theme);
}

function applyTheme(theme) {
  const html = document.documentElement;
  const icon = document.getElementById("theme-toggle-icon");

  if (theme === "light") {
    html.setAttribute("data-theme", "light");
    if (icon) icon.textContent = "☀️";
  } else if (theme === "dark") {
    html.setAttribute("data-theme", "dark");
    if (icon) icon.textContent = "🌙";
  } else {
    html.setAttribute("data-theme", "auto");
    if (icon) icon.textContent = "🌗";
  }

  // Sync drawer buttons active state
  document.querySelectorAll(".theme-choice-btn").forEach(btn => {
    btn.classList.toggle("active", btn.getAttribute("data-theme-val") === theme);
  });
}

// ========================================================
// 2. NAVIGATION (DOCK, DESKTOP TABS & DRAWER SYNC)
// ========================================================
function initNavigation() {
  // Mobile bottom dock items
  document.querySelectorAll(".dock-item[data-tab]").forEach(item => {
    item.addEventListener("click", () => {
      const tabId = item.getAttribute("data-tab");
      switchMainTab(tabId);
    });
  });

  // Desktop top tabs
  document.querySelectorAll(".desktop-tab-btn[data-tab]").forEach(btn => {
    btn.addEventListener("click", () => {
      const tabId = btn.getAttribute("data-tab");
      switchMainTab(tabId);
    });
  });

  // Drawer navigation items
  document.querySelectorAll(".drawer-nav-item[data-tab]").forEach(item => {
    item.addEventListener("click", () => {
      const tabId = item.getAttribute("data-tab");
      switchMainTab(tabId);
      closeDrawer();
    });
  });
}

function switchMainTab(targetTabId) {
  // Update Tab panels
  document.querySelectorAll(".tab-panel").forEach(p => {
    p.classList.toggle("active", p.id === targetTabId);
  });

  // Update Bottom Dock
  document.querySelectorAll(".dock-item[data-tab]").forEach(d => {
    d.classList.toggle("active", d.getAttribute("data-tab") === targetTabId);
  });

  // Update Desktop Tabs
  document.querySelectorAll(".desktop-tab-btn[data-tab]").forEach(t => {
    t.classList.toggle("active", t.getAttribute("data-tab") === targetTabId);
  });

  // Update Drawer Items
  document.querySelectorAll(".drawer-nav-item[data-tab]").forEach(di => {
    di.classList.toggle("active", di.getAttribute("data-tab") === targetTabId);
  });

  window.scrollTo({ top: 0, behavior: 'smooth' });
}

// ========================================================
// 3. SETTINGS & PREFERENCES DRAWER
// ========================================================
function initDrawer() {
  const drawer = document.getElementById("side-panel-drawer");
  const backdrop = document.getElementById("drawer-backdrop");
  const btnToggle = document.getElementById("btn-toggle-drawer");
  const btnDockMenu = document.getElementById("btn-dock-menu");
  const btnClose = document.getElementById("btn-close-drawer");

  if (btnToggle) btnToggle.addEventListener("click", openDrawer);
  if (btnDockMenu) btnDockMenu.addEventListener("click", openDrawer);
  if (btnClose) btnClose.addEventListener("click", closeDrawer);
  if (backdrop) backdrop.addEventListener("click", closeDrawer);

  // Drawer Portal Filter Chips
  document.querySelectorAll(".drawer-portal-chip").forEach(chip => {
    chip.addEventListener("click", () => {
      const source = chip.getAttribute("data-source");
      setPortalFilter(source);
      closeDrawer();
    });
  });

  // Drawer Login & Logout
  document.getElementById("drawer-btn-login")?.addEventListener("click", () => {
    closeDrawer();
    openLoginModal('login');
  });

  document.getElementById("drawer-btn-logout")?.addEventListener("click", () => {
    closeDrawer();
    handleLogout();
  });
}

function openDrawer() {
  document.getElementById("side-panel-drawer")?.classList.add("open");
  document.getElementById("drawer-backdrop")?.classList.add("active");
}

function closeDrawer() {
  document.getElementById("side-panel-drawer")?.classList.remove("open");
  document.getElementById("drawer-backdrop")?.classList.remove("active");
}

// ========================================================
// 4. UNIFIED JOBS FEED CONTROLLER
// ========================================================
function initJobControls() {
  // Subtabs: For You vs All Vacancies
  const btnMatched = document.getElementById("subtab-btn-matched");
  const btnAll = document.getElementById("subtab-btn-all");

  btnMatched?.addEventListener("click", () => {
    activeJobSubtab = "matched";
    btnMatched.classList.add("active");
    btnAll.classList.remove("active");
    applyFilterAndRender();
  });

  btnAll?.addEventListener("click", () => {
    activeJobSubtab = "all";
    btnAll.classList.add("active");
    btnMatched.classList.remove("active");
    applyFilterAndRender();
  });

  // Search input with clear button
  const searchInput = document.getElementById("jobs-search-input");
  const clearBtn = document.getElementById("btn-clear-search");

  searchInput?.addEventListener("input", (e) => {
    const val = e.target.value.trim();
    if (clearBtn) clearBtn.style.display = val ? "block" : "none";
    applyFilterAndRender();
  });

  clearBtn?.addEventListener("click", () => {
    if (searchInput) searchInput.value = "";
    clearBtn.style.display = "none";
    applyFilterAndRender();
  });

  // Portal filter chips (horizontal strip)
  document.querySelectorAll(".portal-chips-scroll .source-chip").forEach(chip => {
    chip.addEventListener("click", () => {
      const source = chip.getAttribute("data-source");
      setPortalFilter(source);
    });
  });
}

function setPortalFilter(source) {
  activeSourceFilter = source;

  // Sync horizontal chips
  document.querySelectorAll(".portal-chips-scroll .source-chip").forEach(sc => {
    sc.classList.toggle("active", sc.getAttribute("data-source") === source);
  });

  // Sync drawer chips
  document.querySelectorAll(".drawer-portal-chip").forEach(dc => {
    dc.classList.toggle("active", dc.getAttribute("data-source") === source);
  });

  loadJobs();
}

// Fetch Jobs from Backend
async function loadJobs() {
  const container = document.getElementById("jobs-list-container");
  if (!container) return;

  container.innerHTML = `
    <div class="loading-state">
      <div class="spinner"></div>
      <p>Fetching active vacancies from Sarkari Result...</p>
    </div>
  `;

  try {
    const srcParam = activeSourceFilter !== "all" ? `&source=${encodeURIComponent(activeSourceFilter)}` : "";

    // Parallel fetch for Matched and All jobs
    const [resMatched, resAll] = await Promise.all([
      authFetch(`/api/jobs?matched_only=true&limit=100${srcParam}`),
      authFetch(`/api/jobs?matched_only=false&limit=100${srcParam}`)
    ]);

    const dataMatched = await resMatched.json();
    const dataAll = await resAll.json();

    cachedMatchedJobs = dataMatched.jobs || [];
    cachedAllJobs = dataAll.jobs || [];

    // Update Counter Badges
    const matchedCount = cachedMatchedJobs.length;
    const allCount = cachedAllJobs.length;

    const badgeMatched = document.getElementById("badge-matched");
    const badgeAll = document.getElementById("badge-all");
    const dockBadge = document.getElementById("dock-badge-matched");
    const desktopBadge = document.getElementById("desktop-badge-matched");
    const drawerBadge = document.getElementById("drawer-badge-matched");

    if (badgeMatched) badgeMatched.textContent = matchedCount;
    if (badgeAll) badgeAll.textContent = allCount;
    if (dockBadge) dockBadge.textContent = matchedCount;
    if (desktopBadge) desktopBadge.textContent = matchedCount;
    if (drawerBadge) drawerBadge.textContent = matchedCount;

    applyFilterAndRender();
  } catch (err) {
    console.error("Failed loading jobs:", err);
    container.innerHTML = `
      <div class="empty-state">
        <p>⚠️ Unable to connect to server.</p>
        <button class="btn btn-primary btn-sm" onclick="loadJobs()" style="margin-top:10px;">Retry</button>
      </div>
    `;
  }
}

// Apply Search & Tab Filtering and Render Page
function applyFilterAndRender() {
  const searchVal = (document.getElementById("jobs-search-input")?.value || "").toLowerCase().trim();
  const sourceList = activeJobSubtab === "matched" ? cachedMatchedJobs : cachedAllJobs;

  if (!searchVal) {
    filteredJobsList = [...sourceList];
  } else {
    filteredJobsList = sourceList.filter(j => 
      j.title.toLowerCase().includes(searchVal) ||
      (j.org && j.org.toLowerCase().includes(searchVal)) ||
      (j.source && j.source.toLowerCase().includes(searchVal)) ||
      (j.matched_keywords && j.matched_keywords.some(k => k.toLowerCase().includes(searchVal))) ||
      (j.qualifications_found && j.qualifications_found.some(k => k.toLowerCase().includes(searchVal))) ||
      (j.eligibility_snippet && j.eligibility_snippet.toLowerCase().includes(searchVal))
    );
  }

  // Update Status Text
  const statusEl = document.getElementById("feed-status-text");
  const countEl = document.getElementById("feed-count-pill");

  if (activeJobSubtab === "matched") {
    if (statusEl) statusEl.textContent = "Jobs matching your qualification & degrees";
  } else {
    if (statusEl) statusEl.textContent = "All active government recruitment openings";
  }
  if (countEl) countEl.textContent = `${filteredJobsList.length} jobs`;

  currentPage = 1;
  renderPaginatedPage(currentPage);
}

// Render Job Cards for Current Page
function renderPaginatedPage(page) {
  const container = document.getElementById("jobs-list-container");
  const paginationContainer = document.getElementById("jobs-pagination");
  if (!container) return;

  if (filteredJobsList.length === 0) {
    container.innerHTML = `
      <div class="empty-state">
        <p>No job openings found matching your criteria.</p>
        ${activeJobSubtab === 'matched' ? `
          <p style="margin-top:8px; font-size:0.82rem;">
            Tip: Go to the <strong>Education</strong> tab to add degrees, or switch to <strong>All Vacancies</strong> above.
          </p>
          <button class="btn btn-outline btn-sm" onclick="switchMainTab('tab-education')" style="margin-top:10px;">
            🎓 Update My Qualifications
          </button>
        ` : ''}
      </div>
    `;
    if (paginationContainer) paginationContainer.innerHTML = "";
    return;
  }

  const totalPages = Math.ceil(filteredJobsList.length / PAGE_SIZE);
  currentPage = Math.max(1, Math.min(page, totalPages));
  const startIndex = (currentPage - 1) * PAGE_SIZE;
  const pageSlice = filteredJobsList.slice(startIndex, startIndex + PAGE_SIZE);

  container.innerHTML = pageSlice.map(job => {
    let sourceBadge = `<span class="source-badge source-sr">SarkariResult ★</span>`;
    if (job.source === "FreeJobAlert") {
      sourceBadge = `<span class="source-badge source-fja">FreeJobAlert</span>`;
    } else if (job.source === "RojgarResult") {
      sourceBadge = `<span class="source-badge source-rr">RojgarResult</span>`;
    }

    const matchedTags = (job.matched_keywords || []).map(k => `<span class="tag-badge tag-matched">✓ ${k}</span>`).join(" ");
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
            ${job.org ? `<span class="job-org">🏢 ${escapeHtml(job.org)}</span>` : ''}
          </div>
          <a href="${escapeHtml(job.url)}" target="_blank" rel="noopener" class="btn btn-sm btn-primary">
            Apply / Details &rarr;
          </a>
        </div>

        <div class="job-tags-row">
          ${matchedTags}
          ${otherTags}
        </div>

        <div class="job-snippet">
          ${escapeHtml(job.eligibility_snippet || "Check official source notification for full details.")}
        </div>

        <div class="job-card-bottom">
          <div class="job-date-info">
            📅 Last Date: <span class="date-val">${escapeHtml(job.last_date || "Refer notification")}</span>
          </div>
          <span style="color:var(--text-dim); font-size:0.72rem;">${escapeHtml(job.source || "SarkariResult")}</span>
        </div>
      </article>
    `;
  }).join("");

  // Render Clean Pagination Controls
  if (paginationContainer) {
    if (totalPages <= 1) {
      paginationContainer.innerHTML = "";
    } else {
      let pagesHtml = `<button class="page-btn" ${currentPage === 1 ? 'disabled' : ''} data-p="${currentPage - 1}">&larr; Prev</button>`;
      for (let p = 1; p <= totalPages; p++) {
        pagesHtml += `<button class="page-btn ${p === currentPage ? 'active' : ''}" data-p="${p}">${p}</button>`;
      }
      pagesHtml += `<button class="page-btn ${currentPage === totalPages ? 'disabled' : ''} data-p="${currentPage + 1}">Next &rarr;</button>`;
      pagesHtml += `<span class="page-info">Page ${currentPage} of ${totalPages}</span>`;

      paginationContainer.innerHTML = pagesHtml;

      paginationContainer.querySelectorAll(".page-btn[data-p]").forEach(btn => {
        btn.addEventListener("click", () => {
          const targetP = parseInt(btn.getAttribute("data-p"));
          if (!isNaN(targetP) && targetP >= 1 && targetP <= totalPages) {
            renderPaginatedPage(targetP);
            window.scrollTo({ top: 0, behavior: 'smooth' });
          }
        });
      });
    }
  }
}

// ========================================================
// 5. EDUCATION PROFILE & DEGREE PICKER
// ========================================================
async function loadQualificationsMaster() {
  try {
    const res = await fetch("/api/qualifications-master");
    const data = await res.json();
    if (data.success && data.qualifications) {
      masterQualifications = data.qualifications;
      renderQualificationsCategories();
      initDegreeSearch();
    }
  } catch (err) {
    console.error("Failed loading master qualifications:", err);
  }
}

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

function initDegreeSearch() {
  const searchInput = document.getElementById("deg-search-input");
  const dropdown = document.getElementById("deg-search-dropdown");
  if (!searchInput || !dropdown) return;

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
      dropdown.innerHTML = `<div class="deg-dropdown-item" style="color:var(--text-muted); cursor:default;">Press Enter to add custom keyword "${escapeHtml(query)}"</div>`;
      dropdown.style.display = "block";
      return;
    }

    dropdown.innerHTML = matches.slice(0, 8).map(m => `
      <div class="deg-dropdown-item" data-code="${m.code}">
        <div>
          <strong>${escapeHtml(m.code)}</strong> - <span>${escapeHtml(m.name)}</span>
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
    container.innerHTML = `<span class="hint-text" style="color:var(--text-muted); font-size:0.8rem;">No specific degrees added yet. Select from the categories below or search above.</span>`;
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

// Save Education Profile
async function saveEducationProfile() {
  const statusEl = document.getElementById("save-edu-status");
  const saveBtn = document.getElementById("btn-save-education");

  const highestLevelRadio = document.querySelector('input[name="highest-level"]:checked');
  const highestLevel = highestLevelRadio ? highestLevelRadio.value : "Graduate";
  const name = document.getElementById("profile-name-input")?.value.trim() || (currentUser ? currentUser.name : "Candidate");
  const state = document.getElementById("profile-state-select")?.value || "All India";

  if (statusEl) {
    statusEl.textContent = "Saving...";
    statusEl.className = "status-msg";
  }
  if (saveBtn) saveBtn.disabled = true;

  try {
    if (currentToken) {
      const res = await authFetch("/api/auth/profile", {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          name,
          highest_qualification: highestLevel,
          qualifications: selectedDegrees,
          state
        })
      });
      const data = await res.json();
      if (data.success && data.user) {
        setLoggedInUser(data.user);
      }
    } else {
      // Guest local storage update
      const guestProfile = {
        name,
        highest_qualification: highestLevel,
        qualifications: selectedDegrees,
        state
      };
      localStorage.setItem("sarkari_guest_profile", JSON.stringify(guestProfile));
      updateUIForProfile(guestProfile);
    }

    if (statusEl) {
      statusEl.textContent = "✓ Qualifications Saved! Updating jobs...";
      statusEl.className = "status-msg status-success";
    }

    await loadJobs();

    // Immediately switch to the Jobs feed so user sees the result!
    setTimeout(() => {
      if (statusEl) statusEl.textContent = "";
      switchMainTab("tab-jobs");
    }, 800);
  } catch (err) {
    if (statusEl) {
      statusEl.textContent = "Error saving profile: " + err.message;
      statusEl.className = "status-msg";
    }
  } finally {
    if (saveBtn) saveBtn.disabled = false;
  }
}

// ========================================================
// 6. AUTHENTICATION & LOGIN / REGISTER MODAL
// ========================================================
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

  // Fallback to Guest Saved Profile
  const savedGuest = localStorage.getItem("sarkari_guest_profile");
  if (savedGuest) {
    try {
      const profile = JSON.parse(savedGuest);
      updateUIForProfile(profile);
    } catch (e) {}
  }
}

function setLoggedInUser(user) {
  currentUser = user;
  updateUIForProfile(user);

  // Show profile avatar, hide Login button in header
  document.getElementById("user-header-profile").style.display = "flex";
  document.getElementById("btn-open-login").style.display = "none";

  // Drawer Auth state
  const drawerLogin = document.getElementById("drawer-btn-login");
  const drawerLogout = document.getElementById("drawer-btn-logout");
  if (drawerLogin) drawerLogin.style.display = "none";
  if (drawerLogout) drawerLogout.style.display = "block";

  // Populate Alert Topic
  const topic = user.ntfy_topic || "sarkari_job_alert_user";
  const topicInput = document.getElementById("ntfy-topic-input");
  const topicDisplay = document.getElementById("ntfy-topic-display");
  const ntfyLink = document.getElementById("ntfy-link");

  if (topicInput) topicInput.value = topic;
  if (topicDisplay) topicDisplay.textContent = topic;
  if (ntfyLink) {
    ntfyLink.href = `https://ntfy.sh/${topic}`;
    ntfyLink.textContent = `ntfy.sh/${topic}`;
  }
}

function updateUIForProfile(profile) {
  const highest = profile.highest_qualification || "Graduate";
  const name = profile.name || "Candidate";
  const state = profile.state || "All India";
  const quals = profile.qualifications || ["GRADUATE"];

  // Header
  const headerName = document.getElementById("header-user-name");
  const headerLevel = document.getElementById("header-user-level");
  const headerAvatar = document.getElementById("header-user-avatar");
  if (headerName) headerName.textContent = name;
  if (headerLevel) headerLevel.textContent = highest;
  if (headerAvatar) headerAvatar.textContent = (name || "U")[0].toUpperCase();

  // Drawer
  const drawerName = document.getElementById("drawer-user-name");
  const drawerLevel = document.getElementById("drawer-user-level");
  const drawerState = document.getElementById("drawer-user-state");
  const drawerAvatar = document.getElementById("drawer-avatar");
  if (drawerName) drawerName.textContent = name;
  if (drawerLevel) drawerLevel.textContent = highest;
  if (drawerState) drawerState.textContent = state;
  if (drawerAvatar) drawerAvatar.textContent = (name || "U")[0].toUpperCase();

  // Job Strip
  const strip = document.getElementById("user-quals-strip");
  const stripChips = document.getElementById("strip-chips");
  if (strip && stripChips) {
    const combined = [highest, ...quals];
    const unique = [...new Set(combined)];
    stripChips.innerHTML = unique.map(q => `<span class="strip-chip">${escapeHtml(q)}</span>`).join("");
    strip.style.display = "flex";
  }

  // Populate Form Fields
  const nameInput = document.getElementById("profile-name-input");
  const stateSelect = document.getElementById("profile-state-select");
  if (nameInput) nameInput.value = name;
  if (stateSelect) stateSelect.value = state;

  const radio = document.querySelector(`input[name="highest-level"][value="${highest}"]`);
  if (radio) radio.checked = true;

  selectedDegrees = quals;
  renderSelectedDegreesChips();
  renderQualificationsCategories();
}

function initLoginModal() {
  const modal = document.getElementById("auth-modal");
  const btnClose = document.getElementById("btn-close-modal");
  const btnGuest = document.getElementById("link-guest-browse");

  if (btnClose) btnClose.addEventListener("click", () => modal.style.display = "none");
  if (btnGuest) btnGuest.addEventListener("click", () => modal.style.display = "none");

  // Tab switching inside modal
  const btnTabLogin = document.getElementById("btn-tab-login");
  const btnTabReg = document.getElementById("btn-tab-register");
  const formLogin = document.getElementById("form-login");
  const formReg = document.getElementById("form-register");
  const heading = document.getElementById("auth-modal-heading");

  btnTabLogin?.addEventListener("click", () => {
    btnTabLogin.classList.add("active");
    btnTabReg.classList.remove("active");
    formLogin.style.display = "flex";
    formReg.style.display = "none";
    if (heading) heading.textContent = "Log In to Your Account";
  });

  btnTabReg?.addEventListener("click", () => {
    btnTabReg.classList.add("active");
    btnTabLogin.classList.remove("active");
    formReg.style.display = "flex";
    formLogin.style.display = "none";
    if (heading) heading.textContent = "Create Candidate Account";
  });

  // Login Form Submit
  formLogin?.addEventListener("submit", async (e) => {
    e.preventDefault();
    const email = document.getElementById("login-email").value.trim();
    const password = document.getElementById("login-password").value;
    const errEl = document.getElementById("login-error-msg");
    if (errEl) errEl.textContent = "";

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
        await loadJobs();
      } else {
        if (errEl) errEl.textContent = data.error || "Invalid login credentials";
      }
    } catch (err) {
      if (errEl) errEl.textContent = err.message;
    }
  });

  // Register Form Submit
  formReg?.addEventListener("submit", async (e) => {
    e.preventDefault();
    const name = document.getElementById("reg-name").value.trim();
    const email = document.getElementById("reg-email").value.trim();
    const password = document.getElementById("reg-password").value;
    const errEl = document.getElementById("reg-error-msg");
    if (errEl) errEl.textContent = "";

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

        // Direct user to Education tab to configure their specific degrees
        switchMainTab("tab-education");
        await loadJobs();
      } else {
        if (errEl) errEl.textContent = data.error || "Registration failed";
      }
    } catch (err) {
      if (errEl) errEl.textContent = err.message;
    }
  });
}

function openLoginModal(tab = 'login') {
  const modal = document.getElementById("auth-modal");
  if (!modal) return;
  modal.style.display = "flex";
  if (tab === 'login') {
    document.getElementById("btn-tab-login")?.click();
  } else {
    document.getElementById("btn-tab-register")?.click();
  }
}

async function handleLogout() {
  await authFetch("/api/auth/logout", { method: "POST" });
  localStorage.removeItem("sarkari_auth_token");
  currentToken = null;
  currentUser = null;

  document.getElementById("user-header-profile").style.display = "none";
  document.getElementById("btn-open-login").style.display = "inline-flex";

  const drawerLogin = document.getElementById("drawer-btn-login");
  const drawerLogout = document.getElementById("drawer-btn-logout");
  if (drawerLogin) drawerLogin.style.display = "block";
  if (drawerLogout) drawerLogout.style.display = "none";

  const drawerName = document.getElementById("drawer-user-name");
  const drawerLevel = document.getElementById("drawer-user-level");
  const drawerAvatar = document.getElementById("drawer-avatar");
  if (drawerName) drawerName.textContent = "Guest Candidate";
  if (drawerLevel) drawerLevel.textContent = "Select Qualifications";
  if (drawerAvatar) drawerAvatar.textContent = "U";

  loadJobs();
}

// ========================================================
// 7. UTILITIES & ACTIONS
// ========================================================
async function triggerScrapeNow() {
  const header = document.querySelector(".app-header");
  header?.classList.add("is-refreshing");

  try {
    const res = await fetch("/api/scrape", { method: "POST" });
    const data = await res.json();
    await loadJobs();
  } catch (err) {
    console.error("Scrape error:", err);
  } finally {
    header?.classList.remove("is-refreshing");
  }
}

async function testNotification() {
  const topic = document.getElementById("ntfy-topic-input")?.value || "sarkari_job_alert_user";
  try {
    const res = await fetch("/api/notify/test", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ topic })
    });
    const data = await res.json();
    alert(data.success ? "✓ Test alert sent to phone via ntfy!" : "Error: " + data.error);
  } catch (e) {
    alert("Error sending test notification: " + e.message);
  }
}

function requestNotificationPermission() {
  if (!("Notification" in window)) {
    alert("This browser does not support desktop notifications.");
    return;
  }
  Notification.requestPermission().then(permission => {
    if (permission === "granted") {
      new Notification("Sarkari Job Alert", {
        body: "✓ Notifications enabled! You will be alerted when matching vacancies are found."
      });
    }
  });
}

function authFetch(url, options = {}) {
  const headers = options.headers || {};
  if (currentToken) {
    headers["Authorization"] = `Bearer ${currentToken}`;
  }
  options.headers = headers;
  return fetch(url, options);
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

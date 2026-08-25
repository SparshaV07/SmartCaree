// ============================================
// NAV — builds the sidebar once, used on every page except index.html
// ============================================
// Each page's <body data-page="..."> tells this script which link to
// mark active, so the nav markup only lives in ONE file.

function renderSidebar() {
  const page = document.body.dataset.page || "";
  const sidebarEl = document.getElementById("sidebar");
  if (!sidebarEl) return;

  const links = [
    { page: "dashboard",    href: "dashboard.html",    label: "Overview" },
    { page: "residents",    href: "residents.html",    label: "Residents" },
    { page: "medications",  href: "medications.html",  label: "Medications" },
    { page: "appointments", href: "appointments.html", label: "Appointments" },
    { page: "alerts",       href: "alerts.html",       label: "Alerts" }
  ];

  sidebarEl.innerHTML = `
    <div class="brand-mark small">SC</div>
    <nav class="nav-list">
      ${links.map(l => `
        <a href="${l.href}" class="nav-btn ${page === l.page ? "active" : ""}">${l.label}</a>
      `).join("")}
    </nav>
    <div class="sidebar-footer">
      <p id="caregiver-name" class="caregiver-name">—</p>
      <button id="logout-btn" class="btn-ghost">Log out</button>
    </div>
  `;

  document.getElementById("logout-btn").addEventListener("click", () => {
    auth.signOut().then(() => window.location.href = "index.html");
  });
}

renderSidebar();
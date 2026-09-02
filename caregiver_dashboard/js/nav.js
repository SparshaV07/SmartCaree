// ============================================================
// nav.js — renders the sidebar, guards pages behind auth,
// and wires up logout. Import on every page except login.html.
// ============================================================

import { auth, db } from "./firebase.js";
import { onAuthStateChanged, signOut } from "https://www.gstatic.com/firebasejs/12.0.0/firebase-auth.js";
import { doc, getDoc } from "https://www.gstatic.com/firebasejs/12.0.0/firebase-firestore.js";
import { initials, showToast } from "./utils.js";

const NAV_ITEMS = [
  { page: "dashboard", href: "index.html", label: "Dashboard", icon: iconHome() },
  { page: "residents", href: "residents.html", label: "Residents", icon: iconUsers() },
  { page: "medications", href: "medications.html", label: "Medications", icon: iconPill() },
  { page: "appointments", href: "appointments.html", label: "Appointments", icon: iconCalendar() },
  { page: "prescriptions", href: "prescriptions.html", label: "Prescriptions", icon: iconFile() },
  { page: "alerts", href: "alerts.html", label: "Alerts", icon: iconBell() },
  { page: "reports", href: "reports.html", label: "Reports", icon: iconChart() },
  { page: "settings", href: "settings.html", label: "Settings", icon: iconGear() },
];

function icon(svgInner) {
  return `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">${svgInner}</svg>`;
}
function iconHome() { return icon('<path d="M3 9.5 12 3l9 6.5"/><path d="M5 10v10h14V10"/>'); }
function iconUsers() { return icon('<circle cx="9" cy="8" r="3.2"/><path d="M2.5 19c0-3.5 2.9-6 6.5-6s6.5 2.5 6.5 6"/><circle cx="17" cy="8.5" r="2.4"/><path d="M15.8 13.2c2.6.4 4.2 2.3 4.2 5.3"/>'); }
function iconPill() { return icon('<rect x="3" y="9.5" width="18" height="7" rx="3.5" transform="rotate(-30 12 12)"/><line x1="12" y1="7.5" x2="12" y2="16.5" transform="rotate(-30 12 12)"/>'); }
function iconCalendar() { return icon('<rect x="3" y="5" width="18" height="16" rx="2"/><line x1="3" y1="10" x2="21" y2="10"/><line x1="8" y1="3" x2="8" y2="7"/><line x1="16" y1="3" x2="16" y2="7"/>'); }
function iconFile() { return icon('<path d="M6 3h9l4 4v14H6z"/><path d="M15 3v4h4"/><line x1="9" y1="13" x2="15" y2="13"/><line x1="9" y1="17" x2="15" y2="17"/>'); }
function iconBell() { return icon('<path d="M6 10a6 6 0 0 1 12 0c0 5 2 6 2 6H4s2-1 2-6"/><path d="M10 20a2 2 0 0 0 4 0"/>'); }
function iconChart() { return icon('<line x1="4" y1="20" x2="20" y2="20"/><rect x="6" y="12" width="3" height="6"/><rect x="11" y="7" width="3" height="11"/><rect x="16" y="3" width="3" height="15"/>'); }
function iconGear() { return icon('<circle cx="12" cy="12" r="3.2"/><path d="M19.4 13.5a1.7 1.7 0 0 0 .3 1.9l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.9-.3 1.7 1.7 0 0 0-1 1.6V20a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1-1.6 1.7 1.7 0 0 0-1.9.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.9 1.7 1.7 0 0 0-1.6-1H4a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.6-1 1.7 1.7 0 0 0-.3-1.9l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.9.3H10a1.7 1.7 0 0 0 1-1.6V4a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.6 1.7 1.7 0 0 0 1.9-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.9V10a1.7 1.7 0 0 0 1.6 1H20a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.6 1z"/>'); }

function renderSidebar(activePage, user, profileName) {
  const container = document.getElementById("sidebar-container");
  if (!container) return;

  const links = NAV_ITEMS.map(
    (item) => `<a href="${item.href}" class="${item.page === activePage ? "active" : ""}">${item.icon}<span>${item.label}</span></a>`
  ).join("");

  const displayName = profileName || user?.email?.split("@")[0] || "Caregiver";

  container.innerHTML = `
    <aside class="sidebar" id="sidebar">
      <div class="sidebar-brand"><span class="dot"></span> SmartCare</div>
      <nav class="sidebar-nav">${links}</nav>
      <div class="sidebar-foot">
        <div class="sidebar-user">
          <div class="avatar">${initials(displayName)}</div>
          <div class="who">
            <div class="name">${displayName}</div>
            <div class="role">${user?.email || ""}</div>
          </div>
        </div>
        <button class="logout-btn" id="logout-btn">Log out</button>
      </div>
    </aside>`;

  document.getElementById("logout-btn")?.addEventListener("click", async () => {
    try {
      await signOut(auth);
      window.location.href = "login.html";
    } catch (err) {
      showToast("Couldn't log out. Try again.", "error");
    }
  });
}

/**
 * Call on every protected page:
 *   initNav('dashboard').then(user => { ...load page data... });
 * Redirects to login.html if no user is signed in.
 * Resolves with the Firebase user once confirmed.
 */
export function initNav(activePage) {
  return new Promise((resolve) => {
    onAuthStateChanged(auth, async (user) => {
      
      let profileName = null;
      try {
        const snap = await getDoc(doc(db, "users", user.uid));
        if (snap.exists()) profileName = snap.data().name;
      } catch (e) {
        /* profile doc may not exist yet — non-fatal */
      }
      renderSidebar(activePage, user, profileName);
      resolve(user);
    });
  });
}

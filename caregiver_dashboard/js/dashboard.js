// ============================================================
// dashboard.js — home page: stat cards, recent activity, quick lists
// ============================================================

import { db } from "./firebase.js";
import { initNav } from "./nav.js";
import { initSOSListener } from "./sos.js";
import {
  collection, getDocs, query, orderBy, limit,
} from "https://www.gstatic.com/firebasejs/12.0.0/firebase-firestore.js";
import { escapeHtml, formatDate, timeAgo, initials } from "./utils.js";

const user = await initNav("dashboard");
initSOSListener();
document.getElementById("welcome-name").textContent =
  (user.email || "there").split("@")[0];

const els = {
  residents: document.getElementById("stat-residents"),
  medsToday: document.getElementById("stat-meds-today"),
  appts: document.getElementById("stat-appointments"),
  alerts: document.getElementById("stat-alerts"),
  feed: document.getElementById("activity-feed"),
  medsList: document.getElementById("quick-meds"),
  apptList: document.getElementById("quick-appointments"),
};

function isToday(dateVal) {
  if (!dateVal) return false;
  const d = dateVal?.toDate ? dateVal.toDate() : new Date(dateVal);
  const now = new Date();
  return d.toDateString() === now.toDateString();
}

function isUpcoming(dateVal, days = 7) {
  if (!dateVal) return false;
  const d = dateVal?.toDate ? dateVal.toDate() : new Date(dateVal);
  const now = new Date();
  const future = new Date();
  future.setDate(now.getDate() + days);
  return d >= now && d <= future;
}

async function loadAll() {
  try {
    const [residentsSnap, medsSnap, apptsSnap, alertsSnap] = await Promise.all([
      getDocs(collection(db, "residents")),
      getDocs(collection(db, "medications")),
      getDocs(collection(db, "appointments")),
      getDocs(collection(db, "alerts")),
    ]);

    const residents = residentsSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
    const meds = medsSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
    const appts = apptsSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
    const alerts = alertsSnap.docs.map((d) => ({ id: d.id, ...d.data() }));

    // Stats
    els.residents.textContent = residents.length;

    const medsToday = meds.filter((m) => isToday(m.time || m.startDate));
    els.medsToday.textContent = medsToday.length;

    const upcomingAppts = appts
      .filter((a) => isUpcoming(a.date))
      .sort((a, b) => (a.date?.toDate ? a.date.toDate() : new Date(a.date)) - (b.date?.toDate ? b.date.toDate() : new Date(b.date)));
    els.appts.textContent = upcomingAppts.length;

    const unreadAlerts = alerts.filter((a) => !a.read);
    els.alerts.textContent = unreadAlerts.length;

    // Quick list: medications due today
    els.medsList.innerHTML = medsToday.length
      ? medsToday
          .slice(0, 6)
          .map(
            (m) => `
        <div class="quick-list-item">
          <span class="dot ${m.status === "given" ? "dot-stable" : "dot-due"}"></span>
          <span class="name">${escapeHtml(m.name || "Medication")}</span>
          <span class="detail">${escapeHtml(m.residentName || "")} · ${escapeHtml(m.dosage || "")}</span>
        </div>`
          )
          .join("")
      : `<p class="text-muted" style="font-size:0.87rem;">No medications scheduled for today.</p>`;

    // Quick list: upcoming appointments
    els.apptList.innerHTML = upcomingAppts.length
      ? upcomingAppts
          .slice(0, 6)
          .map(
            (a) => `
        <div class="quick-list-item">
          <span class="dot dot-stable"></span>
          <span class="name">${escapeHtml(a.title || "Appointment")}</span>
          <span class="detail">${escapeHtml(a.residentName || "")} · ${formatDate(a.date)}</span>
        </div>`
          )
          .join("")
      : `<p class="text-muted" style="font-size:0.87rem;">No appointments in the next 7 days.</p>`;

    // Activity feed: merge recent records across collections by createdAt
    const activity = [
      ...residents.map((r) => ({ type: "resident", label: `${r.name || "A resident"} was added`, at: r.createdAt })),
      ...meds.map((m) => ({ type: "medication", label: `${m.name || "A medication"} added for ${m.residentName || "a resident"}`, at: m.createdAt })),
      ...appts.map((a) => ({ type: "appointment", label: `${a.title || "Appointment"} scheduled for ${a.residentName || "a resident"}`, at: a.createdAt })),
      ...alerts.map((al) => ({ type: "alert", label: al.message || "New alert raised", at: al.createdAt })),
    ]
      .filter((x) => x.at)
      .sort((a, b) => (b.at?.toMillis ? b.at.toMillis() : 0) - (a.at?.toMillis ? a.at.toMillis() : 0))
      .slice(0, 8);

    const iconBg = { resident: "var(--jade-light)", medication: "var(--amber-light)", appointment: "var(--moss-light)", alert: "var(--brick-light)" };
    const iconColor = { resident: "var(--jade)", medication: "var(--amber)", appointment: "var(--moss)", alert: "var(--brick)" };

    els.feed.innerHTML = activity.length
      ? activity
          .map(
            (a) => `
        <div class="feed-item">
          <div class="feed-icon" style="background:${iconBg[a.type]};color:${iconColor[a.type]};">${initials(a.type)}</div>
          <div class="feed-text">
            <div class="title">${escapeHtml(a.label)}</div>
            <div class="meta">${timeAgo(a.at)}</div>
          </div>
        </div>`
          )
          .join("")
      : `<div class="empty-state"><h3>No activity yet</h3><p>Actions across the dashboard will show up here.</p></div>`;
  } catch (err) {
    console.error(err);
  }
}

loadAll();

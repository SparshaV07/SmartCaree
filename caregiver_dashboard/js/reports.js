// ============================================================
// reports.js — summary metrics, status breakdowns, CSV export
// ============================================================

import { db } from "./firebase.js";
import { initNav } from "./nav.js";
import { initSOSListener } from "./sos.js";
import { collection, getDocs } from "https://www.gstatic.com/firebasejs/12.0.0/firebase-firestore.js";
import { escapeHtml, showToast, formatDate } from "./utils.js";

await initNav("reports");
initSOSListener();

const els = {
  totalResidents: document.getElementById("rep-total-residents"),
  totalMeds: document.getElementById("rep-total-meds"),
  totalAppts: document.getElementById("rep-total-appts"),
  totalAlerts: document.getElementById("rep-total-alerts"),
  medBreakdown: document.getElementById("med-breakdown"),
  apptBreakdown: document.getElementById("appt-breakdown"),
  residentStatusBreakdown: document.getElementById("resident-breakdown"),
  exportButtons: document.querySelectorAll("[data-export]"),
};

let dataCache = { residents: [], medications: [], appointments: [], prescriptions: [], alerts: [] };

function bar(label, count, total, color) {
  const pct = total ? Math.round((count / total) * 100) : 0;
  return `
    <div style="margin-bottom:14px;">
      <div class="flex-between" style="font-size:0.85rem;margin-bottom:5px;">
        <span>${escapeHtml(label)}</span>
        <span class="text-muted">${count} (${pct}%)</span>
      </div>
      <div style="background:var(--sand);border-radius:6px;height:8px;overflow:hidden;">
        <div style="width:${pct}%;height:100%;background:${color};"></div>
      </div>
    </div>`;
}

function countBy(arr, key) {
  const out = {};
  arr.forEach((item) => {
    const k = item[key] || "unspecified";
    out[k] = (out[k] || 0) + 1;
  });
  return out;
}

async function load() {
  try {
    const [residentsSnap, medsSnap, apptsSnap, rxSnap, alertsSnap] = await Promise.all([
      getDocs(collection(db, "residents")),
      getDocs(collection(db, "medications")),
      getDocs(collection(db, "appointments")),
      getDocs(collection(db, "prescriptions")),
      getDocs(collection(db, "alerts")),
    ]);

    dataCache.residents = residentsSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
    dataCache.medications = medsSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
    dataCache.appointments = apptsSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
    dataCache.prescriptions = rxSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
    dataCache.alerts = alertsSnap.docs.map((d) => ({ id: d.id, ...d.data() }));

    els.totalResidents.textContent = dataCache.residents.length;
    els.totalMeds.textContent = dataCache.medications.length;
    els.totalAppts.textContent = dataCache.appointments.length;
    els.totalAlerts.textContent = dataCache.alerts.length;

    const medCounts = countBy(dataCache.medications, "status");
    els.medBreakdown.innerHTML =
      bar("Given", medCounts.given || 0, dataCache.medications.length, "var(--moss)") +
      bar("Pending", medCounts.pending || 0, dataCache.medications.length, "var(--amber)") +
      bar("Missed", medCounts.missed || 0, dataCache.medications.length, "var(--brick)");

    const apptCounts = countBy(dataCache.appointments, "status");
    els.apptBreakdown.innerHTML =
      bar("Upcoming", apptCounts.upcoming || 0, dataCache.appointments.length, "var(--amber)") +
      bar("Completed", apptCounts.completed || 0, dataCache.appointments.length, "var(--moss)") +
      bar("Cancelled", apptCounts.cancelled || 0, dataCache.appointments.length, "var(--brick)");

    const statusCounts = countBy(dataCache.residents, "status");
    els.residentStatusBreakdown.innerHTML =
      bar("Stable", statusCounts.stable || 0, dataCache.residents.length, "var(--moss)") +
      bar("Needs attention", statusCounts.attention || 0, dataCache.residents.length, "var(--amber)") +
      bar("Urgent", statusCounts.urgent || 0, dataCache.residents.length, "var(--brick)");
  } catch (err) {
    console.error(err);
    showToast("Couldn't load report data.", "error");
  }
}

function toCSV(rows) {
  if (!rows.length) return "";
  const keys = Array.from(new Set(rows.flatMap((r) => Object.keys(r)))).filter((k) => k !== "createdAt");
  const escapeCell = (v) => `"${String(v ?? "").replace(/"/g, '""')}"`;
  const header = keys.join(",");
  const lines = rows.map((r) => keys.map((k) => escapeCell(r[k])).join(","));
  return [header, ...lines].join("\n");
}

function downloadCSV(filename, csv) {
  const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = filename;
  link.click();
  URL.revokeObjectURL(url);
}

els.exportButtons.forEach((btn) => {
  btn.addEventListener("click", () => {
    const key = btn.dataset.export;
    const rows = dataCache[key] || [];
    if (!rows.length) {
      showToast("Nothing to export yet.", "info");
      return;
    }
    downloadCSV(`${key}-${new Date().toISOString().slice(0, 10)}.csv`, toCSV(rows));
    showToast("Export ready — check your downloads.", "success");
  });
});

load();

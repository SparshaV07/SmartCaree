// ============================================================
// alerts.js — view, create, and resolve resident alerts
// ============================================================

import { db } from "./firebase.js";
import { initNav } from "./nav.js";
import {
  collection, addDoc, updateDoc, deleteDoc, doc,
  onSnapshot, query, orderBy, serverTimestamp,
} from "https://www.gstatic.com/firebasejs/12.0.0/firebase-firestore.js";
import {
  showToast, confirmAction, openModal, closeModal, wireModalDismiss,
  escapeHtml, timeAgo,
} from "./utils.js";

await initNav("alerts");

const list = document.getElementById("alerts-list");
const emptyState = document.getElementById("alerts-empty");
const filterSelect = document.getElementById("severity-filter");
const addBtn = document.getElementById("add-alert-btn");
const form = document.getElementById("alert-form");
const residentSelect = document.getElementById("alert-resident");

wireModalDismiss("alert-modal");

let alerts = [];
let residents = [];

function populateResidentSelect() {
  residentSelect.innerHTML =
    `<option value="">General (not resident-specific)</option>` +
    residents.map((r) => `<option value="${r.id}">${escapeHtml(r.name)}</option>`).join("");
}

const severityStyle = {
  urgent: { dot: "dot-urgent", badge: "badge-urgent", label: "Urgent" },
  attention: { dot: "dot-due", badge: "badge-due", label: "Needs attention" },
  info: { dot: "dot-stable", badge: "badge-neutral", label: "Info" },
};

function render() {
  const filter = filterSelect.value;
  const filtered = alerts.filter((a) => filter === "all" || a.severity === filter);

  if (!filtered.length) {
    list.innerHTML = "";
    emptyState.style.display = "block";
    return;
  }
  emptyState.style.display = "none";

  list.innerHTML = filtered
    .map((a) => {
      const sev = severityStyle[a.severity] || severityStyle.info;
      return `
      <div class="card" style="display:flex;gap:14px;align-items:flex-start;margin-bottom:12px;${a.read ? "opacity:0.6;" : ""}">
        <span class="dot ${sev.dot}" style="margin-top:6px;"></span>
        <div style="flex:1;">
          <div class="flex-between">
            <div style="font-weight:600;">${escapeHtml(a.message || "Alert")}</div>
            <span class="badge ${sev.badge}">${sev.label}</span>
          </div>
          <div class="text-muted" style="font-size:0.82rem;margin-top:4px;">
            ${a.residentName ? escapeHtml(a.residentName) + " · " : ""}${timeAgo(a.createdAt)}
          </div>
        </div>
        <div class="row-actions">
          ${!a.read ? `<button class="btn btn-outline btn-sm" data-read="${a.id}">Mark read</button>` : ""}
          <button class="btn btn-ghost btn-sm" data-delete="${a.id}" style="color:var(--brick);">Delete</button>
        </div>
      </div>`;
    })
    .join("");

  list.querySelectorAll("[data-read]").forEach((btn) =>
    btn.addEventListener("click", async () => {
      try {
        await updateDoc(doc(db, "alerts", btn.dataset.read), { read: true });
      } catch (err) {
        showToast("Couldn't update alert.", "error");
      }
    })
  );
  list.querySelectorAll("[data-delete]").forEach((btn) =>
    btn.addEventListener("click", async () => {
      const ok = await confirmAction("Delete this alert?");
      if (!ok) return;
      try {
        await deleteDoc(doc(db, "alerts", btn.dataset.delete));
        showToast("Alert deleted.", "success");
      } catch (err) {
        showToast("Couldn't delete alert.", "error");
      }
    })
  );
}

addBtn.addEventListener("click", () => {
  form.reset();
  populateResidentSelect();
  openModal("alert-modal");
});

filterSelect.addEventListener("change", render);

form.addEventListener("submit", async (e) => {
  e.preventDefault();
  if (!form.message.value.trim()) {
    showToast("Please describe the alert.", "error");
    return;
  }
  const resident = residents.find((r) => r.id === form.residentId.value);
  try {
    await addDoc(collection(db, "alerts"), {
      message: form.message.value.trim(),
      severity: form.severity.value,
      residentId: resident?.id || null,
      residentName: resident?.name || null,
      read: false,
      createdAt: serverTimestamp(),
    });
    showToast("Alert created.", "success");
    closeModal("alert-modal");
  } catch (err) {
    console.error(err);
    showToast("Couldn't create alert.", "error");
  }
});

onSnapshot(query(collection(db, "residents"), orderBy("name")), (snap) => {
  residents = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
});

onSnapshot(query(collection(db, "alerts"), orderBy("createdAt", "desc")), (snap) => {
  alerts = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
  render();
}, (err) => {
  console.error(err);
  showToast("Couldn't load alerts.", "error");
});

// ============================================
// UTILS — shared by dashboard/residents/medications/appointments/alerts
// ============================================

// Prevent HTML injection from any user-entered text before rendering it.
function escapeHtml(str) {
  if (!str) return "";
  return String(str).replace(/[&<>"']/g, m => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;"
  }[m]));
}

// Renders a colored status pill (pending / taken / missed).
function statusPillHtml(status) {
  const s = status || "pending";
  return `<span class="status-pill status-${s}">${s}</span>`;
}

// Formats an ISO date string (YYYY-MM-DD) as "12 Sep 2026".
function formatDate(dateStr) {
  if (!dateStr) return "—";
  const d = new Date(dateStr + "T00:00:00");
  if (isNaN(d)) return dateStr;
  return d.toLocaleDateString("en-GB", { day: "numeric", month: "short", year: "numeric" });
}

// Live-watches the residents belonging to a caregiver.
// Every page that needs resident names/IDs calls this instead of
// re-writing the same Firestore query.
// Returns the unsubscribe function in case a page wants to stop listening.
function watchResidents(caregiverUid, callback) {
  return db.collection("users")
    .where("caregiverID", "==", caregiverUid)
    .where("role", "==", "elderly")
    .onSnapshot(snapshot => {
      const residents = snapshot.docs.map(d => ({ id: d.id, ...d.data() }));
      callback(residents);
    }, err => {
      console.error("watchResidents error:", err);
      callback([]);
    });
}

// Fills a <select> with resident options. Keeps previously selected value if still valid.
function fillResidentSelect(selectEl, residents) {
  const prevValue = selectEl.value;
  selectEl.innerHTML = residents
    .map(r => `<option value="${r.id}">${escapeHtml(r.name)}</option>`)
    .join("");
  if (residents.some(r => r.id === prevValue)) {
    selectEl.value = prevValue;
  }
}

// Simple modal open/close helpers, used on residents/medications/appointments pages.
function openModal(id) { document.getElementById(id).classList.remove("hidden"); }
function closeModal(id) { document.getElementById(id).classList.add("hidden"); }
document.addEventListener("click", (e) => {
  if (e.target.matches("[data-close]")) closeModal(e.target.dataset.close);
});
// ============================================
// ALERTS page logic — full list of missed doses
// ============================================

let al_residents = [];

window.initPage = function (user) {
  watchResidents(user.uid, residents => {
    al_residents = residents;
    renderAlerts();
  });

  db.collection("medications").onSnapshot(snapshot => {
    const residentIds = al_residents.map(r => r.id);
    window.al_medications = snapshot.docs
      .map(d => ({ id: d.id, ...d.data() }))
      .filter(m => residentIds.includes(m.userID) && m.status === "missed");
    renderAlerts();
  });
};

function renderAlerts() {
  const el = document.getElementById("alerts-full-list");
  const missed = window.al_medications || [];

  if (missed.length === 0) {
    el.innerHTML = `<p class="empty-row">No missed doses. Everything's on track.</p>`;
    return;
  }

  el.innerHTML = missed.map(m => {
    const resident = al_residents.find(r => r.id === m.userID);
    return `
      <div class="alert-card">
        <span class="alert-dot"></span>
        <div>
          <p class="alert-title">${escapeHtml(resident ? resident.name : "Unknown")} missed ${escapeHtml(m.medicineName)}</p>
          <p class="alert-meta">Scheduled for ${escapeHtml(m.time)} · ${escapeHtml(m.dosage)}</p>
        </div>
      </div>
    `;
  }).join("");
}
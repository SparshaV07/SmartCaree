// ============================================
// DASHBOARD (Overview page) logic
// ============================================

let od_residents = [];
let od_medications = [];
let od_appointments = [];

window.initPage = function (user) {
  watchResidents(user.uid, residents => {
    od_residents = residents;
    document.getElementById("stat-residents").textContent = residents.length;
    watchMedicationsForResidents();
    watchAppointmentsForResidents();
  });
};

function watchMedicationsForResidents() {
  db.collection("medications").onSnapshot(snapshot => {
    const residentIds = od_residents.map(r => r.id);
    od_medications = snapshot.docs
      .map(d => ({ id: d.id, ...d.data() }))
      .filter(m => residentIds.includes(m.userID));

    document.getElementById("stat-doses").textContent = od_medications.length;
    const missed = od_medications.filter(m => m.status === "missed");
    document.getElementById("stat-missed").textContent = missed.length;
    renderRecentAlerts(missed);
  });
}

function watchAppointmentsForResidents() {
  db.collection("appointments").onSnapshot(snapshot => {
    const residentIds = od_residents.map(r => r.id);
    od_appointments = snapshot.docs
      .map(d => ({ id: d.id, ...d.data() }))
      .filter(a => residentIds.includes(a.userID));
    document.getElementById("stat-appointments").textContent = od_appointments.length;
  });
}

function renderRecentAlerts(missed) {
  const el = document.getElementById("overview-alerts");
  if (missed.length === 0) {
    el.innerHTML = `<p class="empty-row">No missed doses. Everything's on track.</p>`;
    return;
  }
  el.innerHTML = missed.slice(0, 5).map(m => {
    const resident = od_residents.find(r => r.id === m.userID);
    return `
      <div class="alert-card">
        <span class="alert-dot"></span>
        <div>
          <p class="alert-title">${escapeHtml(resident ? resident.name : "Unknown")} missed ${escapeHtml(m.medicineName)}</p>
          <p class="alert-meta">Scheduled for ${escapeHtml(m.time)}</p>
        </div>
      </div>
    `;
  }).join("");
}
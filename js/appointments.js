// ============================================
// APPOINTMENTS page logic
// ============================================

let a_residents = [];

window.initPage = function (user) {
  watchResidents(user.uid, residents => {
    a_residents = residents;
    fillResidentSelect(document.getElementById("appointment-resident"), residents);
    renderAppointmentsTable();
  });

  db.collection("appointments").onSnapshot(snapshot => {
    const residentIds = a_residents.map(r => r.id);
    window.a_appointments = snapshot.docs
      .map(d => ({ id: d.id, ...d.data() }))
      .filter(a => residentIds.includes(a.userID))
      .sort((x, y) => (x.date || "").localeCompare(y.date || ""));
    renderAppointmentsTable();
  });
};

function renderAppointmentsTable() {
  const body = document.getElementById("appointments-table-body");
  const appts = window.a_appointments || [];

  if (appts.length === 0) {
    body.innerHTML = `<tr><td colspan="3" class="empty-row">No appointments scheduled.</td></tr>`;
    return;
  }

  body.innerHTML = appts.map(a => {
    const resident = a_residents.find(r => r.id === a.userID);
    return `
      <tr>
        <td>${escapeHtml(resident ? resident.name : "Unknown")}</td>
        <td class="mono">${formatDate(a.date)}</td>
        <td>${escapeHtml(a.description)}</td>
      </tr>
    `;
  }).join("");
}

document.getElementById("add-appointment-btn").addEventListener("click", () => {
  if (a_residents.length === 0) {
    alert("Add a resident first, then schedule an appointment for them.");
    return;
  }
  openModal("appointment-modal");
});

document.getElementById("appointment-form").addEventListener("submit", async (e) => {
  e.preventDefault();
  const userID = document.getElementById("appointment-resident").value;
  const date = document.getElementById("appointment-date").value;
  const description = document.getElementById("appointment-description").value.trim();

  await db.collection("appointments").add({
    userID,
    date,
    description,
    createdAt: firebase.firestore.FieldValue.serverTimestamp()
  });

  e.target.reset();
  closeModal("appointment-modal");
});
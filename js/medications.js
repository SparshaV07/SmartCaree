// ============================================
// MEDICATIONS page logic
// ============================================

let m_residents = [];

window.initPage = function (user) {
  watchResidents(user.uid, residents => {
    m_residents = residents;
    fillResidentSelect(document.getElementById("medication-resident"), residents);
    renderMedicationsTable(); // resident names may have changed
  });

  db.collection("medications").onSnapshot(snapshot => {
    const residentIds = m_residents.map(r => r.id);
    window.m_medications = snapshot.docs
      .map(d => ({ id: d.id, ...d.data() }))
      .filter(m => residentIds.includes(m.userID));
    renderMedicationsTable();
  });
};

function renderMedicationsTable() {
  const body = document.getElementById("medications-table-body");
  const meds = window.m_medications || [];

  if (meds.length === 0) {
    body.innerHTML = `<tr><td colspan="5" class="empty-row">No medications assigned yet.</td></tr>`;
    return;
  }

  body.innerHTML = meds.map(m => {
    const resident = m_residents.find(r => r.id === m.userID);
    return `
      <tr>
        <td>${escapeHtml(resident ? resident.name : "Unknown")}</td>
        <td>${escapeHtml(m.medicineName)}</td>
        <td>${escapeHtml(m.dosage)}</td>
        <td class="mono">${escapeHtml(m.time)}</td>
        <td>${statusPillHtml(m.status)}</td>
      </tr>
    `;
  }).join("");
}

document.getElementById("add-medication-btn").addEventListener("click", () => {
  if (m_residents.length === 0) {
    alert("Add a resident first, then assign medicine to them.");
    return;
  }
  openModal("medication-modal");
});

document.getElementById("medication-form").addEventListener("submit", async (e) => {
  e.preventDefault();
  const userID = document.getElementById("medication-resident").value;
  const medicineName = document.getElementById("medication-name").value.trim();
  const dosage = document.getElementById("medication-dosage").value.trim();
  const time = document.getElementById("medication-time").value;

  await db.collection("medications").add({
    userID,
    medicineName,
    dosage,
    time,
    status: "pending", // flipped to "taken" / "missed" by the resident's app or reminder logic
    createdAt: firebase.firestore.FieldValue.serverTimestamp()
  });

  e.target.reset();
  closeModal("medication-modal");
});
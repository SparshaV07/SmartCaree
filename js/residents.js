// ============================================
// RESIDENTS page logic
// ============================================

let currentCaregiverUid = null;

window.initPage = function (user) {
  currentCaregiverUid = user.uid;
  watchResidents(user.uid, renderResidentsTable);
};

function renderResidentsTable(residents) {
  const body = document.getElementById("residents-table-body");
  if (residents.length === 0) {
    body.innerHTML = `<tr><td colspan="3" class="empty-row">No residents yet. Add one to get started.</td></tr>`;
    return;
  }
  body.innerHTML = residents.map(r => `
    <tr>
      <td>${escapeHtml(r.name)}</td>
      <td>${escapeHtml(r.email)}</td>
      <td class="mono">${r.id.slice(0, 8)}</td>
    </tr>
  `).join("");
}

document.getElementById("add-resident-btn").addEventListener("click", () => openModal("resident-modal"));

// NOTE: This creates a resident *record* only. In the real app, a resident's
// own login is created when THEY register in the Flutter app — this form is
// a manual add / invite, useful for demos and testing.
document.getElementById("resident-form").addEventListener("submit", async (e) => {
  e.preventDefault();
  const name = document.getElementById("resident-name").value.trim();
  const email = document.getElementById("resident-email").value.trim();

  await db.collection("users").add({
    name,
    email,
    role: "elderly",
    caregiverID: currentCaregiverUid,
    createdAt: firebase.firestore.FieldValue.serverTimestamp()
  });

  e.target.reset();
  closeModal("resident-modal");
});
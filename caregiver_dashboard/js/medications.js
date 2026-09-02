// ============================================================
// medications.js — CRUD for medications, linked to residents
// ============================================================

import { db } from "./firebase.js";
import { initNav } from "./nav.js";
import { initSOSListener } from "./sos.js";
import {
  collection, addDoc, updateDoc, deleteDoc, doc,
  onSnapshot, query, orderBy, serverTimestamp,
} from "https://www.gstatic.com/firebasejs/12.0.0/firebase-firestore.js";
import {
  showToast, confirmAction, openModal, closeModal, wireModalDismiss,
  escapeHtml, debounce, formatDate,
} from "./utils.js";

await initNav("medications");
initSOSListener();

const tableBody = document.getElementById("meds-body");
const emptyState = document.getElementById("meds-empty");
const searchInput = document.getElementById("search-input");
const filterSelect = document.getElementById("status-filter");
const addBtn = document.getElementById("add-med-btn");
const modalOverlay = document.getElementById("med-modal");
const form = document.getElementById("med-form");
const modalTitle = document.getElementById("med-modal-title");
const deleteBtn = document.getElementById("med-delete-btn");
const residentSelect = document.getElementById("m-resident");

wireModalDismiss("med-modal");

let meds = [];
let residents = [];
let editingId = null;

const statusBadge = (s) => ({
  given: `<span class="badge badge-stable">Given</span>`,
  pending: `<span class="badge badge-due">Pending</span>`,
  missed: `<span class="badge badge-urgent">Missed</span>`,
}[s] || `<span class="badge badge-neutral">Pending</span>`);

function populateResidentSelect() {
  residentSelect.innerHTML = residents
    .map((r) => `<option value="${r.id}">${escapeHtml(r.name)}</option>`)
    .join("") || `<option value="">Add a resident first</option>`;
}

function render() {
  const term = searchInput.value.trim().toLowerCase();
  const statusFilter = filterSelect.value;
  const filtered = meds.filter((m) => {
    const matchesTerm = !term || m.name?.toLowerCase().includes(term) || m.residentName?.toLowerCase().includes(term);
    const matchesStatus = statusFilter === "all" || m.status === statusFilter;
    return matchesTerm && matchesStatus;
  });

  if (!filtered.length) {
    tableBody.innerHTML = "";
    emptyState.style.display = "block";
    return;
  }
  emptyState.style.display = "none";

  tableBody.innerHTML = filtered
    .map(
      (m) => `
    <tr>
      <td style="font-weight:600;">${escapeHtml(m.name || "—")}</td>
      <td>${escapeHtml(m.residentName || "—")}</td>
      <td>${escapeHtml(m.dosage || "—")}</td>
      <td>${escapeHtml(m.frequency || "—")}</td>
      <td class="text-muted" style="font-family:var(--font-mono);font-size:0.82rem;">${escapeHtml(m.time || "—")}</td>
      <td>${statusBadge(m.status)}</td>
      <td>
        <div class="row-actions">
          <button class="btn btn-ghost btn-sm" data-edit="${m.id}">Edit</button>
          <button class="btn btn-ghost btn-sm" data-delete="${m.id}" style="color:var(--brick);">Delete</button>
        </div>
      </td>
    </tr>`
    )
    .join("");

  tableBody.querySelectorAll("[data-edit]").forEach((btn) =>
    btn.addEventListener("click", () => openEdit(btn.dataset.edit))
  );
  tableBody.querySelectorAll("[data-delete]").forEach((btn) =>
    btn.addEventListener("click", () => handleDelete(btn.dataset.delete))
  );
}

function openAdd() {
  editingId = null;
  form.reset();
  populateResidentSelect();
  modalTitle.textContent = "Add medication";
  deleteBtn.style.display = "none";
  openModal("med-modal");
}

function openEdit(id) {
  const m = meds.find((x) => x.id === id);
  if (!m) return;
  editingId = id;
  populateResidentSelect();
  modalTitle.textContent = "Edit medication";
  form.name.value = m.name || "";
  form.residentId.value = m.residentId || "";
  form.dosage.value = m.dosage || "";
  form.frequency.value = m.frequency || "";
  form.time.value = m.time || "";
  form.status.value = m.status || "pending";
  form.notes.value = m.notes || "";
  deleteBtn.style.display = "inline-flex";
  openModal("med-modal");
}

async function handleDelete(id) {
  const ok = await confirmAction("Delete this medication record?");
  if (!ok) return;
  try {
    await deleteDoc(doc(db, "medications", id));
    showToast("Medication deleted.", "success");
  } catch (err) {
    console.error(err);
    showToast("Couldn't delete medication.", "error");
  }
}

addBtn.addEventListener("click", openAdd);
deleteBtn.addEventListener("click", () => editingId && handleDelete(editingId));
searchInput.addEventListener("input", debounce(render, 150));
filterSelect.addEventListener("change", render);

form.addEventListener("submit", async (e) => {
  e.preventDefault();
  const resident = residents.find((r) => r.id === form.residentId.value);
  if (!form.name.value.trim() || !resident) {
    showToast("Please enter a medication name and select a resident.", "error");
    return;
  }
  const payload = {
    name: form.name.value.trim(),
    residentId: resident.id,
    residentName: resident.name,
    dosage: form.dosage.value.trim(),
    frequency: form.frequency.value.trim(),
    time: form.time.value,
    status: form.status.value,
    notes: form.notes.value.trim(),
  };
  try {
    if (editingId) {
      await updateDoc(doc(db, "medications", editingId), payload);
      showToast("Medication updated.", "success");
    } else {
      await addDoc(collection(db, "medications"), { ...payload, createdAt: serverTimestamp() });
      showToast("Medication added.", "success");
    }
    closeModal("med-modal");
  } catch (err) {
    console.error(err);
    showToast("Couldn't save medication.", "error");
  }
});

onSnapshot(query(collection(db, "residents"), orderBy("name")), (snap) => {
  residents = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
});

onSnapshot(query(collection(db, "medications"), orderBy("name")), (snap) => {
  meds = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
  render();
}, (err) => {
  console.error(err);
  showToast("Couldn't load medications.", "error");
});

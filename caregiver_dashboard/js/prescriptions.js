// ============================================================
// prescriptions.js — CRUD for prescriptions, linked to residents
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

await initNav("prescriptions");
initSOSListener();

const tableBody = document.getElementById("rx-body");
const emptyState = document.getElementById("rx-empty");
const searchInput = document.getElementById("search-input");
const addBtn = document.getElementById("add-rx-btn");
const form = document.getElementById("rx-form");
const modalTitle = document.getElementById("rx-modal-title");
const deleteBtn = document.getElementById("rx-delete-btn");
const residentSelect = document.getElementById("rx-resident");

wireModalDismiss("rx-modal");

let items = [];
let residents = [];
let editingId = null;

function isExpired(dateVal) {
  if (!dateVal) return false;
  const d = dateVal?.toDate ? dateVal.toDate() : new Date(dateVal);
  return d < new Date();
}

function populateResidentSelect() {
  residentSelect.innerHTML = residents
    .map((r) => `<option value="${r.id}">${escapeHtml(r.name)}</option>`)
    .join("") || `<option value="">Add a resident first</option>`;
}

function render() {
  const term = searchInput.value.trim().toLowerCase();
  const filtered = items.filter(
    (p) => !term || p.medicationName?.toLowerCase().includes(term) || p.residentName?.toLowerCase().includes(term) || p.prescribedBy?.toLowerCase().includes(term)
  );

  if (!filtered.length) {
    tableBody.innerHTML = "";
    emptyState.style.display = "block";
    return;
  }
  emptyState.style.display = "none";

  tableBody.innerHTML = filtered
    .map(
      (p) => `
    <tr>
      <td style="font-weight:600;">${escapeHtml(p.medicationName || "—")}</td>
      <td>${escapeHtml(p.residentName || "—")}</td>
      <td>${escapeHtml(p.prescribedBy || "—")}</td>
      <td>${formatDate(p.dateIssued)}</td>
      <td>${formatDate(p.expiryDate)}</td>
      <td>${isExpired(p.expiryDate)
          ? `<span class="badge badge-urgent">Expired</span>`
          : `<span class="badge badge-stable">Active</span>`}</td>
      <td>
        <div class="row-actions">
          <button class="btn btn-ghost btn-sm" data-edit="${p.id}">Edit</button>
          <button class="btn btn-ghost btn-sm" data-delete="${p.id}" style="color:var(--brick);">Delete</button>
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
  modalTitle.textContent = "Add prescription";
  deleteBtn.style.display = "none";
  openModal("rx-modal");
}

function openEdit(id) {
  const p = items.find((x) => x.id === id);
  if (!p) return;
  editingId = id;
  populateResidentSelect();
  modalTitle.textContent = "Edit prescription";
  form.medicationName.value = p.medicationName || "";
  form.residentId.value = p.residentId || "";
  form.prescribedBy.value = p.prescribedBy || "";
  form.dateIssued.value = p.dateIssued?.toDate ? p.dateIssued.toDate().toISOString().slice(0, 10) : (p.dateIssued || "");
  form.expiryDate.value = p.expiryDate?.toDate ? p.expiryDate.toDate().toISOString().slice(0, 10) : (p.expiryDate || "");
  form.notes.value = p.notes || "";
  deleteBtn.style.display = "inline-flex";
  openModal("rx-modal");
}

async function handleDelete(id) {
  const ok = await confirmAction("Delete this prescription record?");
  if (!ok) return;
  try {
    await deleteDoc(doc(db, "prescriptions", id));
    showToast("Prescription deleted.", "success");
  } catch (err) {
    console.error(err);
    showToast("Couldn't delete prescription.", "error");
  }
}

addBtn.addEventListener("click", openAdd);
deleteBtn.addEventListener("click", () => editingId && handleDelete(editingId));
searchInput.addEventListener("input", debounce(render, 150));

form.addEventListener("submit", async (e) => {
  e.preventDefault();
  const resident = residents.find((r) => r.id === form.residentId.value);
  if (!form.medicationName.value.trim() || !resident) {
    showToast("Please enter a medication name and select a resident.", "error");
    return;
  }
  const payload = {
    medicationName: form.medicationName.value.trim(),
    residentId: resident.id,
    residentName: resident.name,
    prescribedBy: form.prescribedBy.value.trim(),
    dateIssued: form.dateIssued.value ? new Date(form.dateIssued.value).toISOString() : null,
    expiryDate: form.expiryDate.value ? new Date(form.expiryDate.value).toISOString() : null,
    notes: form.notes.value.trim(),
  };
  try {
    if (editingId) {
      await updateDoc(doc(db, "prescriptions", editingId), payload);
      showToast("Prescription updated.", "success");
    } else {
      await addDoc(collection(db, "prescriptions"), { ...payload, createdAt: serverTimestamp() });
      showToast("Prescription added.", "success");
    }
    closeModal("rx-modal");
  } catch (err) {
    console.error(err);
    showToast("Couldn't save prescription.", "error");
  }
});

onSnapshot(query(collection(db, "residents"), orderBy("name")), (snap) => {
  residents = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
});

onSnapshot(query(collection(db, "prescriptions"), orderBy("dateIssued", "desc")), (snap) => {
  items = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
  render();
}, (err) => {
  console.error(err);
  showToast("Couldn't load prescriptions.", "error");
});

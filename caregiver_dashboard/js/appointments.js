// ============================================================
// appointments.js — CRUD for appointments, linked to residents
// ============================================================

import { db } from "./firebase.js";
import { initNav } from "./nav.js";
import {
  collection, addDoc, updateDoc, deleteDoc, doc,
  onSnapshot, query, orderBy, serverTimestamp,
} from "https://www.gstatic.com/firebasejs/12.0.0/firebase-firestore.js";
import {
  showToast, confirmAction, openModal, closeModal, wireModalDismiss,
  escapeHtml, debounce, formatDate,
} from "./utils.js";

await initNav("appointments");

const tableBody = document.getElementById("appts-body");
const emptyState = document.getElementById("appts-empty");
const searchInput = document.getElementById("search-input");
const addBtn = document.getElementById("add-appt-btn");
const form = document.getElementById("appt-form");
const modalTitle = document.getElementById("appt-modal-title");
const deleteBtn = document.getElementById("appt-delete-btn");
const residentSelect = document.getElementById("appt-resident");

wireModalDismiss("appt-modal");

let appts = [];
let residents = [];
let editingId = null;

const statusBadge = (s) => ({
  upcoming: `<span class="badge badge-due">Upcoming</span>`,
  completed: `<span class="badge badge-stable">Completed</span>`,
  cancelled: `<span class="badge badge-urgent">Cancelled</span>`,
}[s] || `<span class="badge badge-due">Upcoming</span>`);

function populateResidentSelect() {
  residentSelect.innerHTML = residents
    .map((r) => `<option value="${r.id}">${escapeHtml(r.name)}</option>`)
    .join("") || `<option value="">Add a resident first</option>`;
}

function render() {
  const term = searchInput.value.trim().toLowerCase();
  const filtered = appts.filter(
    (a) => !term || a.title?.toLowerCase().includes(term) || a.residentName?.toLowerCase().includes(term) || a.doctor?.toLowerCase().includes(term)
  );

  if (!filtered.length) {
    tableBody.innerHTML = "";
    emptyState.style.display = "block";
    return;
  }
  emptyState.style.display = "none";

  tableBody.innerHTML = filtered
    .map(
      (a) => `
    <tr>
      <td style="font-weight:600;">${escapeHtml(a.title || "—")}</td>
      <td>${escapeHtml(a.residentName || "—")}</td>
      <td>${escapeHtml(a.doctor || "—")}</td>
      <td>${formatDate(a.date)}${a.time ? " · " + escapeHtml(a.time) : ""}</td>
      <td>${escapeHtml(a.location || "—")}</td>
      <td>${statusBadge(a.status)}</td>
      <td>
        <div class="row-actions">
          <button class="btn btn-ghost btn-sm" data-edit="${a.id}">Edit</button>
          <button class="btn btn-ghost btn-sm" data-delete="${a.id}" style="color:var(--brick);">Delete</button>
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
  modalTitle.textContent = "Add appointment";
  deleteBtn.style.display = "none";
  openModal("appt-modal");
}

function openEdit(id) {
  const a = appts.find((x) => x.id === id);
  if (!a) return;
  editingId = id;
  populateResidentSelect();
  modalTitle.textContent = "Edit appointment";
  form.title.value = a.title || "";
  form.residentId.value = a.residentId || "";
  form.doctor.value = a.doctor || "";
  form.date.value = a.date?.toDate ? a.date.toDate().toISOString().slice(0, 10) : (a.date || "");
  form.time.value = a.time || "";
  form.location.value = a.location || "";
  form.status.value = a.status || "upcoming";
  form.notes.value = a.notes || "";
  deleteBtn.style.display = "inline-flex";
  openModal("appt-modal");
}

async function handleDelete(id) {
  const ok = await confirmAction("Delete this appointment?");
  if (!ok) return;
  try {
    await deleteDoc(doc(db, "appointments", id));
    showToast("Appointment deleted.", "success");
  } catch (err) {
    console.error(err);
    showToast("Couldn't delete appointment.", "error");
  }
}

addBtn.addEventListener("click", openAdd);
deleteBtn.addEventListener("click", () => editingId && handleDelete(editingId));
searchInput.addEventListener("input", debounce(render, 150));

form.addEventListener("submit", async (e) => {
  e.preventDefault();
  const resident = residents.find((r) => r.id === form.residentId.value);
  if (!form.title.value.trim() || !resident || !form.date.value) {
    showToast("Please fill in title, resident, and date.", "error");
    return;
  }
  const payload = {
    title: form.title.value.trim(),
    residentId: resident.id,
    residentName: resident.name,
    doctor: form.doctor.value.trim(),
    date: new Date(form.date.value).toISOString(),
    time: form.time.value,
    location: form.location.value.trim(),
    status: form.status.value,
    notes: form.notes.value.trim(),
  };
  try {
    if (editingId) {
      await updateDoc(doc(db, "appointments", editingId), payload);
      showToast("Appointment updated.", "success");
    } else {
      await addDoc(collection(db, "appointments"), { ...payload, createdAt: serverTimestamp() });
      showToast("Appointment added.", "success");
    }
    closeModal("appt-modal");
  } catch (err) {
    console.error(err);
    showToast("Couldn't save appointment.", "error");
  }
});

onSnapshot(query(collection(db, "residents"), orderBy("name")), (snap) => {
  residents = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
});

onSnapshot(query(collection(db, "appointments"), orderBy("date")), (snap) => {
  appts = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
  render();
}, (err) => {
  console.error(err);
  showToast("Couldn't load appointments.", "error");
});

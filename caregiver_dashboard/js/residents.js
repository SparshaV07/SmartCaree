// ============================================================
// residents.js — CRUD for residents, with live search
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
  escapeHtml, initials, debounce, qs,
} from "./utils.js";

await initNav("residents");
initSOSListener();

const tableBody = document.getElementById("residents-body");
const emptyState = document.getElementById("residents-empty");
const searchInput = document.getElementById("search-input");
const addBtn = document.getElementById("add-resident-btn");
const modalOverlay = document.getElementById("resident-modal");
const form = document.getElementById("resident-form");
const modalTitle = document.getElementById("resident-modal-title");
const deleteBtn = document.getElementById("resident-delete-btn");

wireModalDismiss("resident-modal");

let residents = [];
let editingId = null;

function statusBadge(status) {
  const map = {
    stable: `<span class="badge badge-stable"><span class="dot dot-stable"></span>Stable</span>`,
    attention: `<span class="badge badge-due"><span class="dot dot-due"></span>Needs attention</span>`,
    urgent: `<span class="badge badge-urgent"><span class="dot dot-urgent"></span>Urgent</span>`,
  };
  return map[status] || map.stable;
}

function render() {
  const term = searchInput.value.trim().toLowerCase();
  const filtered = residents.filter((r) =>
    !term ||
    r.name?.toLowerCase().includes(term) ||
    r.room?.toLowerCase?.().includes(term) ||
    r.primaryCondition?.toLowerCase().includes(term)
  );

  if (!filtered.length) {
    tableBody.innerHTML = "";
    emptyState.style.display = "block";
    return;
  }
  emptyState.style.display = "none";

  tableBody.innerHTML = filtered
    .map(
      (r) => `
    <tr>
      <td>
        <div class="flex gap-12" style="align-items:center;">
          <div class="avatar" style="width:32px;height:32px;border-radius:50%;background:var(--jade-light);color:var(--jade);display:flex;align-items:center;justify-content:center;font-weight:700;font-size:0.78rem;">${initials(r.name)}</div>
          <div>
            <div style="font-weight:600;">${escapeHtml(r.name || "—")}</div>
            <div class="text-muted" style="font-size:0.78rem;">Age ${escapeHtml(String(r.age || "—"))}</div>
          </div>
        </div>
      </td>
      <td>${escapeHtml(r.room || "—")}</td>
      <td>${escapeHtml(r.primaryCondition || "—")}</td>
      <td>${escapeHtml(r.emergencyContact || "—")}</td>
      <td>${statusBadge(r.status)}</td>
      <td>
        <div class="row-actions">
          <button class="btn btn-ghost btn-sm" data-edit="${r.id}">Edit</button>
          <button class="btn btn-ghost btn-sm" data-delete="${r.id}" style="color:var(--brick);">Delete</button>
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
  modalTitle.textContent = "Add resident";
  deleteBtn.style.display = "none";
  openModal("resident-modal");
}

function openEdit(id) {
  const r = residents.find((x) => x.id === id);
  if (!r) return;
  editingId = id;
  modalTitle.textContent = "Edit resident";
  form.name.value = r.name || "";
  form.age.value = r.age || "";
  form.room.value = r.room || "";
  form.primaryCondition.value = r.primaryCondition || "";
  form.emergencyContact.value = r.emergencyContact || "";
  form.status.value = r.status || "stable";
  form.notes.value = r.notes || "";
  deleteBtn.style.display = "inline-flex";
  openModal("resident-modal");
}

async function handleDelete(id) {
  const ok = await confirmAction("Delete this resident? This can't be undone.");
  if (!ok) return;
  try {
    await deleteDoc(doc(db, "residents", id));
    showToast("Resident deleted.", "success");
  } catch (err) {
    console.error(err);
    showToast("Couldn't delete resident.", "error");
  }
}

addBtn.addEventListener("click", openAdd);
deleteBtn.addEventListener("click", () => editingId && handleDelete(editingId));
searchInput.addEventListener("input", debounce(render, 150));

form.addEventListener("submit", async (e) => {
  e.preventDefault();
  const payload = {
    name: form.name.value.trim(),
    age: Number(form.age.value) || null,
    room: form.room.value.trim(),
    primaryCondition: form.primaryCondition.value.trim(),
    emergencyContact: form.emergencyContact.value.trim(),
    status: form.status.value,
    notes: form.notes.value.trim(),
  };
  if (!payload.name) {
    showToast("Please enter a name.", "error");
    return;
  }
  try {
    if (editingId) {
      await updateDoc(doc(db, "residents", editingId), payload);
      showToast("Resident updated.", "success");
    } else {
      const count = residents.length + 1;

await addDoc(collection(db, "residents"), {
  ...payload,
  residentId: `R-${String(count).padStart(3, "0")}`,
  createdAt: serverTimestamp()
});
      showToast("Resident added.", "success");
    }
    closeModal("resident-modal");
  } catch (err) {
    console.error(err);
    showToast("Couldn't save resident.", "error");
  }
});

// Live updates
onSnapshot(query(collection(db, "residents"), orderBy("name")), (snap) => {
  residents = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
  render();
}, (err) => {
  console.error(err);
  showToast("Couldn't load residents.", "error");
});

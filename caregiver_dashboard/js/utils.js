// ============================================================
// utils.js — shared helpers used across every page
// ============================================================

/* ---------- Toasts ---------- */
export function showToast(message, type = "info") {
  let stack = document.getElementById("toast-stack");
  if (!stack) {
    stack = document.createElement("div");
    stack.id = "toast-stack";
    document.body.appendChild(stack);
  }
  const toast = document.createElement("div");
  toast.className = `toast ${type}`;
  toast.textContent = message;
  stack.appendChild(toast);
  setTimeout(() => {
    toast.style.opacity = "0";
    toast.style.transition = "opacity 0.25s ease";
    setTimeout(() => toast.remove(), 250);
  }, 3200);
}

/* ---------- Modal helpers ---------- */
export function openModal(overlayId) {
  document.getElementById(overlayId)?.classList.add("open");
}
export function closeModal(overlayId) {
  document.getElementById(overlayId)?.classList.remove("open");
}
export function wireModalDismiss(overlayId) {
  const overlay = document.getElementById(overlayId);
  if (!overlay) return;
  overlay.addEventListener("click", (e) => {
    if (e.target === overlay) closeModal(overlayId);
  });
  overlay.querySelectorAll("[data-close-modal]").forEach((btn) =>
    btn.addEventListener("click", () => closeModal(overlayId))
  );
}

/* ---------- Confirm dialog (lightweight, promise-based) ---------- */
export function confirmAction(message) {
  return new Promise((resolve) => {
    const overlay = document.createElement("div");
    overlay.className = "modal-overlay open";
    overlay.innerHTML = `
      <div class="modal" style="max-width:380px;">
        <div class="modal-header"><h3>Please confirm</h3></div>
        <div class="modal-body"><p style="margin:0;color:var(--text);">${message}</p></div>
        <div class="modal-footer">
          <button class="btn btn-outline" data-action="cancel">Cancel</button>
          <button class="btn btn-danger" data-action="ok">Confirm</button>
        </div>
      </div>`;
    document.body.appendChild(overlay);
    overlay.querySelector('[data-action="cancel"]').onclick = () => {
      overlay.remove();
      resolve(false);
    };
    overlay.querySelector('[data-action="ok"]').onclick = () => {
      overlay.remove();
      resolve(true);
    };
    overlay.addEventListener("click", (e) => {
      if (e.target === overlay) {
        overlay.remove();
        resolve(false);
      }
    });
  });
}

/* ---------- Formatting ---------- */
export function formatDate(value) {
  if (!value) return "—";
  const date = value?.toDate ? value.toDate() : new Date(value);
  if (isNaN(date)) return "—";
  return date.toLocaleDateString(undefined, { year: "numeric", month: "short", day: "numeric" });
}

export function formatDateTime(value) {
  if (!value) return "—";
  const date = value?.toDate ? value.toDate() : new Date(value);
  if (isNaN(date)) return "—";
  return date.toLocaleString(undefined, {
    year: "numeric", month: "short", day: "numeric", hour: "2-digit", minute: "2-digit",
  });
}

export function timeAgo(value) {
  if (!value) return "—";
  const date = value?.toDate ? value.toDate() : new Date(value);
  const seconds = Math.floor((Date.now() - date.getTime()) / 1000);
  if (seconds < 60) return "just now";
  const mins = Math.floor(seconds / 60);
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  const days = Math.floor(hrs / 24);
  return `${days}d ago`;
}

export function escapeHtml(str = "") {
  return String(str)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

export function initials(name = "") {
  return name.trim().split(/\s+/).slice(0, 2).map((w) => w[0]?.toUpperCase() || "").join("") || "?";
}

/* ---------- Small DOM helper ---------- */
export function qs(sel, root = document) {
  return root.querySelector(sel);
}
export function qsa(sel, root = document) {
  return Array.from(root.querySelectorAll(sel));
}

/* ---------- Simple debounce for search inputs ---------- */
export function debounce(fn, wait = 250) {
  let t;
  return (...args) => {
    clearTimeout(t);
    t = setTimeout(() => fn(...args), wait);
  };
}

/* ---------- Friendly Firebase error messages ---------- */
export function friendlyAuthError(code) {
  const map = {
    "auth/invalid-email": "That email address doesn't look right.",
    "auth/user-disabled": "This account has been disabled.",
    "auth/user-not-found": "No account found with that email.",
    "auth/wrong-password": "Incorrect password. Try again.",
    "auth/invalid-credential": "Email or password is incorrect.",
    "auth/too-many-requests": "Too many attempts. Please wait a moment and try again.",
    "auth/email-already-in-use": "An account already exists with that email.",
    "auth/weak-password": "Password should be at least 6 characters.",
    "auth/network-request-failed": "Network error. Check your connection.",
  };
  return map[code] || "Something went wrong. Please try again.";
}

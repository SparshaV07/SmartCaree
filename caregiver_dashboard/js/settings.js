// ============================================================
// settings.js — profile info, password change, notification prefs
// ============================================================

import { auth, db } from "./firebase.js";
import { initNav } from "./nav.js";
import { initSOSListener } from "./sos.js";
import {
  updatePassword, updateProfile, signOut,
} from "https://www.gstatic.com/firebasejs/12.0.0/firebase-auth.js";
import { doc, getDoc, setDoc } from "https://www.gstatic.com/firebasejs/12.0.0/firebase-firestore.js";
import { showToast, friendlyAuthError, confirmAction } from "./utils.js";

const user = await initNav("settings");
initSOSListener();

const profileForm = document.getElementById("profile-form");
const passwordForm = document.getElementById("password-form");
const notifyToggle = document.getElementById("notify-toggle");
const emailDisplay = document.getElementById("settings-email");
const logoutBtn = document.getElementById("settings-logout");

emailDisplay.textContent = user.email;

async function loadProfile() {
  try {
    const ref = doc(db, "users", user.uid);
    const snap = await getDoc(ref);
    const data = snap.exists() ? snap.data() : {};
    profileForm.name.value = data.name || "";
    profileForm.role.value = data.role || "Caregiver";
    notifyToggle.checked = data.notifyByEmail !== false;
  } catch (err) {
    console.error(err);
    showToast("Couldn't load your profile.", "error");
  }
}

profileForm.addEventListener("submit", async (e) => {
  e.preventDefault();
  const name = profileForm.name.value.trim();
  const role = profileForm.role.value.trim();
  if (!name) {
    showToast("Please enter your name.", "error");
    return;
  }
  try {
    await setDoc(doc(db, "users", user.uid), {
      name, role,
      email: user.email,
      notifyByEmail: notifyToggle.checked,
    }, { merge: true });
    await updateProfile(auth.currentUser, { displayName: name });
    showToast("Profile updated.", "success");
  } catch (err) {
    console.error(err);
    showToast("Couldn't update profile.", "error");
  }
});

notifyToggle.addEventListener("change", async () => {
  try {
    await setDoc(doc(db, "users", user.uid), { notifyByEmail: notifyToggle.checked }, { merge: true });
    showToast(notifyToggle.checked ? "Email notifications on." : "Email notifications off.", "success");
  } catch (err) {
    showToast("Couldn't update notification setting.", "error");
  }
});

passwordForm.addEventListener("submit", async (e) => {
  e.preventDefault();
  const newPassword = passwordForm.newPassword.value;
  const confirmPassword = passwordForm.confirmPassword.value;
  if (newPassword.length < 6) {
    showToast("Password must be at least 6 characters.", "error");
    return;
  }
  if (newPassword !== confirmPassword) {
    showToast("Passwords don't match.", "error");
    return;
  }
  try {
    await updatePassword(auth.currentUser, newPassword);
    showToast("Password updated.", "success");
    passwordForm.reset();
  } catch (err) {
    console.error(err);
    showToast(friendlyAuthError(err.code) + " You may need to log out and back in first.", "error");
  }
});

logoutBtn.addEventListener("click", async () => {
  const ok = await confirmAction("Log out of CareTrack?");
  if (!ok) return;
  await signOut(auth);
  window.location.href = "login.html";
});

loadProfile();

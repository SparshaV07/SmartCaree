// ============================================
// AUTH — login, register, tab switching (index.html only)
// ============================================

const tabBtns = document.querySelectorAll(".tab-btn");
const loginForm = document.getElementById("login-form");
const registerForm = document.getElementById("register-form");

tabBtns.forEach(btn => {
  btn.addEventListener("click", () => {
    tabBtns.forEach(b => b.classList.remove("active"));
    btn.classList.add("active");
    if (btn.dataset.tab === "login") {
      loginForm.classList.remove("hidden");
      registerForm.classList.add("hidden");
    } else {
      registerForm.classList.remove("hidden");
      loginForm.classList.add("hidden");
    }
  });
});

// Already logged in? Skip straight to the dashboard.
auth.onAuthStateChanged(user => {
  if (user) window.location.href = "dashboard.html";
});

loginForm.addEventListener("submit", async (e) => {
  e.preventDefault();
  const email = document.getElementById("login-email").value.trim();
  const password = document.getElementById("login-password").value;
  const errorEl = document.getElementById("login-error");
  errorEl.textContent = "";

  try {
    await auth.signInWithEmailAndPassword(email, password);
    window.location.href = "dashboard.html";
  } catch (err) {
    errorEl.textContent = friendlyAuthError(err.code);
  }
});

registerForm.addEventListener("submit", async (e) => {
  e.preventDefault();
  const name = document.getElementById("register-name").value.trim();
  const email = document.getElementById("register-email").value.trim();
  const password = document.getElementById("register-password").value;
  const errorEl = document.getElementById("register-error");
  errorEl.textContent = "";

  try {
    const cred = await auth.createUserWithEmailAndPassword(email, password);

    // Matches the shared "users" collection structure the team agreed on.
    await db.collection("users").doc(cred.user.uid).set({
      name: name,
      email: email,
      role: "family_caregiver",
      createdAt: firebase.firestore.FieldValue.serverTimestamp()
    });

    window.location.href = "dashboard.html";
  } catch (err) {
    errorEl.textContent = friendlyAuthError(err.code);
  }
});

function friendlyAuthError(code) {
  const messages = {
    "auth/email-already-in-use": "That email is already registered. Try logging in instead.",
    "auth/invalid-email": "That email address doesn't look right.",
    "auth/weak-password": "Password should be at least 6 characters.",
    "auth/user-not-found": "No account found with that email.",
    "auth/wrong-password": "Incorrect password.",
    "auth/invalid-credential": "Email or password is incorrect."
  };
  return messages[code] || "Something went wrong. Please try again.";
}
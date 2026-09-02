// ============================================================
// login.js
// Email/password sign in, caregiver sign up, password reset
// Firebase v12 Modular SDK
// ============================================================

import { auth, db } from "./firebase.js";

import {
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  sendPasswordResetEmail,
  onAuthStateChanged,
  setPersistence,
  browserLocalPersistence
} from "https://www.gstatic.com/firebasejs/12.0.0/firebase-auth.js";

import {
  doc,
  setDoc,
  serverTimestamp
} from "https://www.gstatic.com/firebasejs/12.0.0/firebase-firestore.js";

import {
  friendlyAuthError,
  showToast
} from "./utils.js";


// ============================================================
// DOM ELEMENTS
// ============================================================

const form = document.getElementById("login-form");
const errorBox = document.getElementById("login-error");
const submitBtn = document.getElementById("login-submit");
const toggleModeLink = document.getElementById("toggle-mode");
const nameGroup = document.getElementById("name-group");
const forgotLink = document.getElementById("forgot-link");
const formTitle = document.getElementById("form-title");
const formSub = document.getElementById("form-sub");


// ============================================================
// MODE
// ============================================================

let mode = "signin";
// signin = Login
// signup  = Create caregiver account


// ============================================================
// CHECK EXISTING LOGIN
// ============================================================

onAuthStateChanged(auth, (user) => {

  if (user) {

    console.log("Already logged in:", user.email);

    // User is already authenticated
    window.location.href = "index.html";
  }

});


// ============================================================
// ERROR MESSAGE
// ============================================================

function setError(msg) {

  if (!msg) {

    errorBox.classList.remove("show");
    errorBox.textContent = "";

    return;
  }

  errorBox.textContent = msg;
  errorBox.classList.add("show");
}


// ============================================================
// LOADING BUTTON
// ============================================================

function setLoading(loading) {

  submitBtn.disabled = loading;

  if (loading) {

    submitBtn.textContent = "Please wait…";

  } else {

    submitBtn.textContent =
      mode === "signin"
        ? "Log in"
        : "Create account";

  }

}


// ============================================================
// SWITCH LOGIN / SIGNUP
// ============================================================

toggleModeLink?.addEventListener("click", (e) => {

  e.preventDefault();

  mode = mode === "signin"
    ? "signup"
    : "signin";

  setError(null);


  if (mode === "signup") {

    nameGroup.style.display = "block";

    formTitle.textContent = "Create your account";

    formSub.textContent =
      "Set up caregiver access to CareTrack.";

    submitBtn.textContent = "Create account";

    toggleModeLink.textContent =
      "Already have an account? Log in";

  } else {

    nameGroup.style.display = "none";

    formTitle.textContent = "Welcome back";

    formSub.textContent =
      "Log in to continue caring for your residents.";

    submitBtn.textContent = "Log in";

    toggleModeLink.textContent =
      "New here? Create an account";

  }

});


// ============================================================
// FORGOT PASSWORD
// ============================================================

forgotLink?.addEventListener("click", async (e) => {

  e.preventDefault();

  const email =
    document.getElementById("email").value.trim();


  if (!email) {

    setError(
      "Enter your email above first, then click 'Forgot password'."
    );

    return;
  }


  try {

    await sendPasswordResetEmail(auth, email);

    showToast(
      "Password reset email sent.",
      "success"
    );

  } catch (err) {

    console.error("Password reset error:", err);

    setError(
      friendlyAuthError(err.code)
    );

  }

});


// ============================================================
// LOGIN / SIGNUP FORM
// ============================================================

form?.addEventListener("submit", async (e) => {

  e.preventDefault();

  setError(null);


  // ----------------------------------------------------------
  // Get form values
  // ----------------------------------------------------------

  const email =
    document.getElementById("email").value.trim();

  const password =
    document.getElementById("password").value;

  const name =
    document.getElementById("name")?.value.trim();


  // ----------------------------------------------------------
  // Validate
  // ----------------------------------------------------------

  if (!email || !password) {

    setError(
      "Please fill in both email and password."
    );

    return;
  }


  if (mode === "signup" && !name) {

    setError(
      "Please enter your name."
    );

    return;
  }


  setLoading(true);


  try {

    // --------------------------------------------------------
    // Keep Firebase authentication persistent
    // --------------------------------------------------------

    await setPersistence(
      auth,
      browserLocalPersistence
    );


    // ========================================================
    // LOGIN
    // ========================================================

    if (mode === "signin") {

      const credential =
        await signInWithEmailAndPassword(
          auth,
          email,
          password
        );


      console.log(
        "Login successful:",
        credential.user.email
      );

      console.log(
        "UID:",
        credential.user.uid
      );


      // Redirect to dashboard
      window.location.href = "index.html";

    }


    // ========================================================
    // CREATE CAREGIVER ACCOUNT
    // ========================================================

    else {

      const credential =
        await createUserWithEmailAndPassword(
          auth,
          email,
          password
        );


      const user = credential.user;


      console.log(
        "Account created:",
        user.email
      );

      console.log(
        "UID:",
        user.uid
      );


      // ------------------------------------------------------
      // Create Firestore caregiver profile
      // ------------------------------------------------------

      await setDoc(
        doc(db, "users", user.uid),
        {
          name: name || email.split("@")[0],

          email: email,

          // IMPORTANT:
          // This must match auth.js
          role: "family_caregiver",

          notifyByEmail: true,

          createdAt: serverTimestamp()
        }
      );


      console.log(
        "Caregiver profile created successfully."
      );


      // Redirect to dashboard
      window.location.href = "index.html";

    }


  } catch (err) {

    console.error(
      "Authentication error:",
      err
    );

    console.error(
      "Error code:",
      err.code
    );

    setError(
      friendlyAuthError(err.code)
    );

  } finally {

    setLoading(false);

  }

});
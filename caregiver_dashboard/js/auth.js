// js/auth.js

import { auth, db } from "./firebase.js";

import {
  signInWithEmailAndPassword,
  onAuthStateChanged,
  signOut
} from "https://www.gstatic.com/firebasejs/12.0.0/firebase-auth.js";

import {
  doc,
  getDoc
} from "https://www.gstatic.com/firebasejs/12.0.0/firebase-firestore.js";


// ============================================================
// LOGIN
// ============================================================

export function loginCaregiver(email, password) {
  return signInWithEmailAndPassword(auth, email, password);
}


// ============================================================
// LOGOUT
// ============================================================

export function logout() {
  return signOut(auth);
}


// ============================================================
// AUTHENTICATION WATCHER
// ============================================================
// Checks whether a Firebase user is logged in.
// Then checks the user's role in Firestore /users/{uid}.
//
// Valid caregiver roles:
//   - family_caregiver
//   - institution_caregiver
// ============================================================

export function watchAuth(onLoggedIn, onLoggedOut) {

  return onAuthStateChanged(auth, async (user) => {

    // ----------------------------------------------------------
    // No Firebase user
    // ----------------------------------------------------------

    if (!user) {
      console.log("No Firebase user is currently logged in.");

      onLoggedOut("Please log in to continue.");

      return;
    }


    // ----------------------------------------------------------
    // Firebase user exists
    // ----------------------------------------------------------

    console.log("Firebase user detected:", user.email);
    console.log("Firebase UID:", user.uid);


    try {

      // Get caregiver profile from Firestore
      const userRef = doc(db, "users", user.uid);
      const snap = await getDoc(userRef);


      // --------------------------------------------------------
      // User document doesn't exist
      // --------------------------------------------------------

      if (!snap.exists()) {

        console.error(
          "No user profile found in Firestore for UID:",
          user.uid
        );

        onLoggedOut(
          "Your account profile was not found. Please contact an administrator."
        );

        return;
      }


      // --------------------------------------------------------
      // Get profile
      // --------------------------------------------------------

      const profile = snap.data();

      console.log("Firestore user profile:", profile);
      console.log("User role:", profile.role);


      // --------------------------------------------------------
      // Check caregiver role
      // --------------------------------------------------------

      const isCaregiver =
        profile.role === "family_caregiver" ||
        profile.role === "institution_caregiver";


      if (!isCaregiver) {

        console.error(
          "User is not registered as a caregiver.",
          "Current role:",
          profile.role
        );

        onLoggedOut(
          "This account isn't set up as a caregiver."
        );

        return;
      }


      // --------------------------------------------------------
      // Valid caregiver
      // --------------------------------------------------------

      console.log("Caregiver authentication successful.");

      onLoggedIn(user, profile);

    } catch (error) {

      console.error(
        "Error checking caregiver profile:",
        error
      );

      onLoggedOut(
        "Unable to verify your caregiver account."
      );
    }

  });
}
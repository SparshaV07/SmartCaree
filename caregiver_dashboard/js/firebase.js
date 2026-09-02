import { initializeApp } from "https://www.gstatic.com/firebasejs/12.0.0/firebase-app.js";
import {
  getAuth,
  setPersistence,
  browserLocalPersistence,
} from "https://www.gstatic.com/firebasejs/12.0.0/firebase-auth.js";
import { getFirestore } from "https://www.gstatic.com/firebasejs/12.0.0/firebase-firestore.js";

// TODO: Replace with your project's Firebase config
// (Firebase Console → Project Settings → General → Your apps → SDK setup and configuration)
const firebaseConfig = {
    apiKey: "AIzaSyCUhM9uPPvzLHl93wYHgsZrDx2pTkRZBdw",
    authDomain: "smartcare-9740d.firebaseapp.com",
    projectId: "smartcare-9740d",
    storageBucket: "smartcare-9740d.firebasestorage.app",
    messagingSenderId: "966691643739",
    appId: "1:966691643739:web:d69b4e8f7962ecc8c67a7e",
    measurementId: "G-ZZRDL2FY3P"
};


export const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);

// Keep users logged in across tab/browser restarts
setPersistence(auth, browserLocalPersistence).catch((err) =>
  console.error("Auth persistence error:", err)
);

// ---- Firestore collection name constants (single source of truth) ----
export const COLLECTIONS = {
  RESIDENTS: "residents",
  MEDICATIONS: "medications",
  APPOINTMENTS: "appointments",
  PRESCRIPTIONS: "prescriptions",
  ALERTS: "alerts",
  USERS: "users",
};

// Firebase SDK imports
import { initializeApp } from
    "https://www.gstatic.com/firebasejs/12.1.0/firebase-app.js";

import { getAuth } from
    "https://www.gstatic.com/firebasejs/12.1.0/firebase-auth.js";

import { getFirestore } from
    "https://www.gstatic.com/firebasejs/12.1.0/firebase-firestore.js";


// Firebase configuration
const firebaseConfig = {
    apiKey: "AIzaSyCUhM9uPPvzLHl93wYHgsZrDx2pTkRZBdw",
    authDomain: "smartcare-9740d.firebaseapp.com",
    projectId: "smartcare-9740d",
    storageBucket: "smartcare-9740d.firebasestorage.app",
    messagingSenderId: "966691643739",
    appId: "1:966691643739:web:d69b4e8f7962ecc8c67a7e",
    measurementId: "G-ZZRDL2FY3P"
};


// Initialize Firebase
const app = initializeApp(firebaseConfig);


// Firebase Authentication
const auth = getAuth(app);


// Firestore Database
const db = getFirestore(app);


// Export so other JS files can use them
export {
    app,
    auth,
    db
};
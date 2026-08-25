// ============================================
// AUTH GUARD — included on every page except index.html
// ============================================
// Bounces to index.html if no one is logged in, fills in the caregiver's
// name in the sidebar, then calls the page's own initPage(user) function
// (each page-specific JS file defines window.initPage).

function requireAuth() {
  auth.onAuthStateChanged(user => {
    if (!user) {
      window.location.href = "index.html";
      return;
    }

    // Fill in sidebar name
    db.collection("users").doc(user.uid).get().then(doc => {
      const nameEl = document.getElementById("caregiver-name");
      if (nameEl && doc.exists) {
        nameEl.textContent = doc.data().name || "Caregiver";
      }
    });

    // Hand off to the page's own logic, if it defined one
    if (typeof window.initPage === "function") {
      window.initPage(user);
    }
  });
}

requireAuth();
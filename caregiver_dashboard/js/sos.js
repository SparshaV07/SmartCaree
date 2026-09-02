// ============================================================
// sos.js — Real-time SOS popup for caregivers
// ============================================================

import { db } from "./firebase.js";
import {
  collection,
  query,
  orderBy,
  onSnapshot,
  limit,
  where,
} from "https://www.gstatic.com/firebasejs/12.0.0/firebase-firestore.js";

function showSOSPopup(name) {
  const old = document.getElementById("sos-popup");
  if (old) old.remove();

  const popup = document.createElement("div");
  popup.id = "sos-popup";

  popup.innerHTML = `
    <div class="sos-card">
     <div class="sos-header">
  <div>
    <h3>Emergency SOS</h3>
    <p><strong>${name}</strong> needs immediate assistance.</p>
  </div>
</div>

      <div class="sos-actions">
        <button id="view-alert-btn">View Alert</button>
        <button id="dismiss-sos-btn">Dismiss</button>
      </div>
    </div>
  `;

  document.body.appendChild(popup);

document.getElementById("dismiss-sos-btn").onclick = () => popup.remove();

  document.getElementById("view-alert-btn").onclick = () => {
    window.location.href = "alerts.html";
  };
}

// Inject styles once
if (!document.getElementById("sos-style")) {
  const style = document.createElement("style");
  style.id = "sos-style";
  style.textContent = `
    #sos-popup{
      position:fixed;
      top:22px;
      right:22px;
      z-index:9999;
      animation:sosSlide .35s ease;
    }

    .sos-card{
      width:390px;
      background:#fffdfb;
      border:2px solid #d32f2f;
      border-radius:20px;
      box-shadow:0 0 18px rgba(211,47,47,.35),0 18px 40px rgba(0,0,0,.18);
      overflow:hidden;
      font-family:inherit;
    }

.sos-header{
  padding:22px;
  border-bottom:1px solid #f2d3d3;
}

.sos-header h3{
  margin:0;
  color:#8E1C1C;
  font-size:20px;
  font-weight:700;
  letter-spacing:.3px;
}

    .sos-header p{
      margin:6px 0 0;
      color:#333;
      font-size:15px;
    }

    .sos-card::after{
      content:"⚠ EMERGENCY - IMMEDIATE RESPONSE REQUIRED ⚠";
      display:block;
      background:linear-gradient(90deg,#8b0000,#d32f2f,#8b0000);
      color:white;
      text-align:center;
      padding:9px;
      font-size:12px;
      font-weight:700;
      letter-spacing:.8px;
    }

    .sos-actions{
      display:flex;
      justify-content:flex-end;
      gap:12px;
      padding:18px;
      background:white;
    }

    .sos-actions button{
      padding:10px 16px;
      border-radius:10px;
      font-weight:700;
      cursor:pointer;
    }

    #view-alert-btn{
      background:white;
      border:2px solid #d32f2f;
      color:#b71c1c;
    }

    #dismiss-sos-btn{
      background:#d32f2f;
      border:none;
      color:white;
    }

    @keyframes pulse{
      0%{transform:scale(1);}
      50%{transform:scale(1.12);}
      100%{transform:scale(1);}
    }

    @keyframes sosSlide{
      from{opacity:0;transform:translateY(-20px);}
      to{opacity:1;transform:translateY(0);}
    }
  `;
  document.head.appendChild(style);
}

let activeSOS = null;
let reminderTimer = null;

export function initSOSListener() {
  onSnapshot(
    query(
  collection(db, "sos"),
  where("status", "==", "active"),
  orderBy("timestamp", "desc"),
  limit(1)
),
    (snap) => {
      // No active SOS → stop reminders
     if (snap.empty) {
        activeSOS = null;

        if (reminderTimer) {
          clearInterval(reminderTimer);
          reminderTimer = null;
        }

        return;
      }

      const latest = snap.docs[0];

      // New emergency
      if (activeSOS !== latest.id) {
        activeSOS = latest.id;

        showSOSPopup(latest.data().name || "Resident");

        if (reminderTimer) clearInterval(reminderTimer);

        reminderTimer = setInterval(() => {
          showSOSPopup(latest.data().name || "Resident");
        }, 20000); // every 20 seconds
      }
    }
  );
}
document.addEventListener("turbolinks:load",()=>{console.log("chat_room.js loaded");const e=document.getElementById("chatRoom"),o=document.getElementById("chatRoomToggle"),t=document.getElementById("chatRoomClose");if(!e||!o||!t)return void console.warn("Chat room elements not found. Skipping toggle functionality.");o.replaceWith(o.cloneNode(!0)),t.replaceWith(t.cloneNode(!0));const l=document.getElementById("chatRoomToggle"),n=document.getElementById("chatRoomClose");l.addEventListener("click",()=>{e.style.display="block",l.style.display="none"}),n.addEventListener("click",()=>{e.style.display="none",l.style.display="block"}),document.addEventListener("click",o=>{e.contains(o.target)||l.contains(o.target)||"block"!==e.style.display||(e.style.display="none",l.style.display="block",console.log("Chat room closed by clicking outside."))})});
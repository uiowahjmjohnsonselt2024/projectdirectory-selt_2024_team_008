console.log(">>> server.js loaded <<<"),document.addEventListener("turbolinks:load",()=>{console.log(">>> turbolinks:load event fired in server.js <<<");const e=document.getElementById("message_content"),n=document.getElementById("send_button");e&&n?(console.log(">>> Enabling dynamic send button behavior <<<"),e.addEventListener("input",()=>{n.disabled=""===e.value.trim()}),n.disabled=""===e.value.trim()):console.warn(">>> messageInput or sendButton not found <<<")});
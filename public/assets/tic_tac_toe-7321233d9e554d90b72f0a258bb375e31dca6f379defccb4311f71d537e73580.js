document.addEventListener("DOMContentLoaded",()=>{const e=document.querySelector(".board"),t={X:"O",O:"X"};let r="X",n=Array(9).fill(null);const o=document.querySelector(".game-message"),a=document.querySelector(".shard-balance-display p");e.addEventListener("click",c=>{const s=c.target;if(!s.classList.contains("cell")||s.textContent)return;const d=parseInt(s.dataset.index,10);fetch("/games/$(gameId}/tic_tac_toe/play",{method:"POST",headers:{"Content-Type":"application/json","X-CSRF-Token":document.querySelector('meta[name="csrf-token"]').getAttribute("content")},body:JSON.stringify({move:d,board:n,current_turn:r})}).then(e=>e.json()).then(c=>{if(c.error)return console.error("Server error: ",c.error),void(o.textContent="A server error occurred. Please Try again");c.board.forEach((e,t)=>{const r=document.querySelector(`.cell[data-index="${t}"]`);e&&(r.textContent=e,r.classList.add(e.toLowerCase())),n[t]=e}),"continue"!==c.status?(o.textContent=c.message,a.textContent=`Shard Balance: ${c.new_shard_balance} Shards`,e.classList.add("disabled")):r=t[r]})["catch"](e=>{console.error("Error:",e),o.textContent="An error occurred. Please try again."})})});
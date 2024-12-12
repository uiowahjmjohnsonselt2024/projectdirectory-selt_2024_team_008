!function(e,t){"object"==typeof exports&&"undefined"!=typeof module?t(exports):"function"==typeof define&&define.amd?define(["exports"],t):t((e="undefined"!=typeof globalThis?globalThis:e||self).ActionCable={})}(this,function(e){"use strict";function t(e){if("function"==typeof e&&(e=e()),e&&!/^wss?:/i.test(e)){const t=document.createElement("a");return t.href=e,t.href=t.href,t.protocol=t.protocol.replace("http","ws"),t.href}return e}function n(e=i("url")||l.default_mount_path){return new S(e)}function i(e){const t=document.head.querySelector(`meta[name='action-cable-${e}']`);if(t)return t.getAttribute("content")}var s={logger:self.console,WebSocket:self.WebSocket},o={log(...e){this.enabled&&(e.push(Date.now()),s.logger.log("[ActionCable]",...e))}};const r=()=>(new Date).getTime(),c=e=>(r()-e)/1e3;class a{constructor(e){this.visibilityDidChange=this.visibilityDidChange.bind(this),this.connection=e,this.reconnectAttempts=0}start(){this.isRunning()||(this.startedAt=r(),delete this.stoppedAt,this.startPolling(),addEventListener("visibilitychange",this.visibilityDidChange),o.log(`ConnectionMonitor started. stale threshold = ${this.constructor.staleThreshold} s`))}stop(){this.isRunning()&&(this.stoppedAt=r(),this.stopPolling(),removeEventListener("visibilitychange",this.visibilityDidChange),o.log("ConnectionMonitor stopped"))}isRunning(){return this.startedAt&&!this.stoppedAt}recordPing(){this.pingedAt=r()}recordConnect(){this.reconnectAttempts=0,this.recordPing(),delete this.disconnectedAt,o.log("ConnectionMonitor recorded connect")}recordDisconnect(){this.disconnectedAt=r(),o.log("ConnectionMonitor recorded disconnect")}startPolling(){this.stopPolling(),this.poll()}stopPolling(){clearTimeout(this.pollTimeout)}poll(){this.pollTimeout=setTimeout(()=>{this.reconnectIfStale(),this.poll()},this.getPollInterval())}getPollInterval(){const{staleThreshold:e,reconnectionBackoffRate:t}=this.constructor;return 1e3*e*Math.pow(1+t,Math.min(this.reconnectAttempts,10))*(1+(0===this.reconnectAttempts?1:t)*Math.random())}reconnectIfStale(){this.connectionIsStale()&&(o.log(`ConnectionMonitor detected stale connection. reconnectAttempts = ${this.reconnectAttempts}, time stale = ${c(this.refreshedAt)} s, stale threshold = ${this.constructor.staleThreshold} s`),this.reconnectAttempts++,this.disconnectedRecently()?o.log(`ConnectionMonitor skipping reopening recent disconnect. time disconnected = ${c(this.disconnectedAt)} s`):(o.log("ConnectionMonitor reopening"),this.connection.reopen()))}get refreshedAt(){return this.pingedAt?this.pingedAt:this.startedAt}connectionIsStale(){return c(this.refreshedAt)>this.constructor.staleThreshold}disconnectedRecently(){return this.disconnectedAt&&c(this.disconnectedAt)<this.constructor.staleThreshold}visibilityDidChange(){"visible"===document.visibilityState&&setTimeout(()=>{!this.connectionIsStale()&&this.connection.isOpen()||(o.log(`ConnectionMonitor reopening stale connection on visibilitychange. visibilityState = ${document.visibilityState}`),this.connection.reopen())},200)}}a.staleThreshold=6,a.reconnectionBackoffRate=.15;var l={message_types:{welcome:"welcome",disconnect:"disconnect",ping:"ping",confirmation:"confirm_subscription",rejection:"reject_subscription"},disconnect_reasons:{unauthorized:"unauthorized",invalid_request:"invalid_request",server_restart:"server_restart"},default_mount_path:"/cable",protocols:["actioncable-v1-json","actioncable-unsupported"]};const{message_types:u,protocols:h}=l,d=h.slice(0,h.length-1),p=[].indexOf;class g{constructor(e){this.open=this.open.bind(this),this.consumer=e,this.subscriptions=this.consumer.subscriptions,this.monitor=new a(this),this.disconnected=!0}send(e){return!!this.isOpen()&&(this.webSocket.send(JSON.stringify(e)),!0)}open(){return this.isActive()?(o.log(`Attempted to open WebSocket, but existing socket is ${this.getState()}`),!1):(o.log(`Opening WebSocket, current state is ${this.getState()}, subprotocols: ${h}`),this.webSocket&&this.uninstallEventHandlers(),this.webSocket=new s.WebSocket(this.consumer.url,h),this.installEventHandlers(),this.monitor.start(),!0)}close({allowReconnect:e}={allowReconnect:!0}){if(e||this.monitor.stop(),this.isOpen())return this.webSocket.close()}reopen(){if(o.log(`Reopening WebSocket, current state is ${this.getState()}`),!this.isActive())return this.open();try{return this.close()}catch(e){o.log("Failed to reopen WebSocket",e)}finally{o.log(`Reopening WebSocket in ${this.constructor.reopenDelay}ms`),setTimeout(this.open,this.constructor.reopenDelay)}}getProtocol(){if(this.webSocket)return this.webSocket.protocol}isOpen(){return this.isState("open")}isActive(){return this.isState("open","connecting")}isProtocolSupported(){return p.call(d,this.getProtocol())>=0}isState(...e){return p.call(e,this.getState())>=0}getState(){if(this.webSocket)for(let e in s.WebSocket)if(s.WebSocket[e]===this.webSocket.readyState)return e.toLowerCase();return null}installEventHandlers(){for(let e in this.events){const t=this.events[e].bind(this);this.webSocket[`on${e}`]=t}}uninstallEventHandlers(){for(let e in this.events)this.webSocket[`on${e}`]=function(){}}}g.reopenDelay=500,g.prototype.events={message(e){if(!this.isProtocolSupported())return;const{identifier:t,message:n,reason:i,reconnect:s,type:r}=JSON.parse(e.data);switch(r){case u.welcome:return this.monitor.recordConnect(),this.subscriptions.reload();case u.disconnect:return o.log(`Disconnecting. Reason: ${i}`),this.close({allowReconnect:s});case u.ping:return this.monitor.recordPing();case u.confirmation:return this.subscriptions.confirmSubscription(t),this.subscriptions.notify(t,"connected");case u.rejection:return this.subscriptions.reject(t);default:return this.subscriptions.notify(t,"received",n)}},open(){if(o.log(`WebSocket onopen event, using '${this.getProtocol()}' subprotocol`),this.disconnected=!1,!this.isProtocolSupported())return o.log("Protocol is unsupported. Stopping monitor and disconnecting."),this.close({allowReconnect:!1})},close(e){if(o.log("WebSocket onclose event"),!this.disconnected)return this.disconnected=!0,this.monitor.recordDisconnect(),this.subscriptions.notifyAll("disconnected",{willAttemptReconnect:this.monitor.isRunning()})},error(){o.log("WebSocket onerror event")}};const m=function(e,t){if(null!=t)for(let n in t){const i=t[n];e[n]=i}return e};class b{constructor(e,t={},n){this.consumer=e,this.identifier=JSON.stringify(t),m(this,n)}perform(e,t={}){return t.action=e,this.send(t)}send(e){return this.consumer.send({command:"message",identifier:this.identifier,data:JSON.stringify(e)})}unsubscribe(){return this.consumer.subscriptions.remove(this)}}class f{constructor(e){this.subscriptions=e,this.pendingSubscriptions=[]}guarantee(e){-1==this.pendingSubscriptions.indexOf(e)?(o.log(`SubscriptionGuarantor guaranteeing ${e.identifier}`),this.pendingSubscriptions.push(e)):o.log(`SubscriptionGuarantor already guaranteeing ${e.identifier}`),this.startGuaranteeing()}forget(e){o.log(`SubscriptionGuarantor forgetting ${e.identifier}`),this.pendingSubscriptions=this.pendingSubscriptions.filter(t=>t!==e)}startGuaranteeing(){this.stopGuaranteeing(),this.retrySubscribing()}stopGuaranteeing(){clearTimeout(this.retryTimeout)}retrySubscribing(){this.retryTimeout=setTimeout(()=>{this.subscriptions&&"function"==typeof this.subscriptions.subscribe&&this.pendingSubscriptions.map(e=>{o.log(`SubscriptionGuarantor resubscribing ${e.identifier}`),this.subscriptions.subscribe(e)})},500)}}class y{constructor(e){this.consumer=e,this.guarantor=new f(this),this.subscriptions=[]}create(e,t){const n="object"==typeof e?e:{channel:e},i=new b(this.consumer,n,t);return this.add(i)}add(e){return this.subscriptions.push(e),this.consumer.ensureActiveConnection(),this.notify(e,"initialized"),this.subscribe(e),e}remove(e){return this.forget(e),this.findAll(e.identifier).length||this.sendCommand(e,"unsubscribe"),e}reject(e){return this.findAll(e).map(e=>(this.forget(e),this.notify(e,"rejected"),e))}forget(e){return this.guarantor.forget(e),this.subscriptions=this.subscriptions.filter(t=>t!==e),e}findAll(e){return this.subscriptions.filter(t=>t.identifier===e)}reload(){return this.subscriptions.map(e=>this.subscribe(e))}notifyAll(e,...t){return this.subscriptions.map(n=>this.notify(n,e,...t))}notify(e,t,...n){let i;return(i="string"==typeof e?this.findAll(e):[e]).map(e=>"function"==typeof e[t]?e[t](...n):undefined)}subscribe(e){this.sendCommand(e,"subscribe")&&this.guarantor.guarantee(e)}confirmSubscription(e){o.log(`Subscription confirmed ${e}`),this.findAll(e).map(e=>this.guarantor.forget(e))}sendCommand(e,t){const{identifier:n}=e;return this.consumer.send({command:t,identifier:n})}}class S{constructor(e){this._url=e,this.subscriptions=new y(this),this.connection=new g(this)}get url(){return t(this._url)}send(e){return this.connection.send(e)}connect(){return this.connection.open()}disconnect(){return this.connection.close({allowReconnect:!1})}ensureActiveConnection(){if(!this.connection.isActive())return this.connection.open()}}e.Connection=g,e.ConnectionMonitor=a,e.Consumer=S,e.INTERNAL=l,e.Subscription=b,e.SubscriptionGuarantor=f,e.Subscriptions=y,e.adapters=s,e.createConsumer=n,e.createWebSocketURL=t,e.getConfig=i,e.logger=o,Object.defineProperty(e,"__esModule",{value:!0})});const createConsumer=ActionCable.createConsumer;window.App||(window.App={}),App.cable=createConsumer(),console.log("App.cable initialized:",App.cable);let gameLogicSubscription=null,lastPosition={x:null,y:null};const SHARD_COST_PER_TILE=2,userColors={},getUserColor=e=>{if(!userColors[e]){const t=Math.floor(360*Math.random());userColors[e]=`hsl(${t}, 70%, 80%)`}return userColors[e]},ensureGameMembership=async e=>{if(document.getElementById("server-id"))try{const n=document.querySelector("meta[name='csrf-token']").getAttribute("content"),i=await fetch(`/games/${e}/ensure_membership.json`,{method:"POST",headers:{"Content-Type":"application/json","X-CSRF-Token":n}});if(!i.ok)throw new Error(`Failed to ensure game membership: ${i.statusText}`);const s=await i.json();console.log("Game membership ensured:",s.message||s)}catch(t){throw console.error("Error ensuring game membership:",t),alert("Unable to join the game. Please try again."),t}else console.error("Server element not found. Cannot ensure membership.")},initializeGameLogicChannel=async()=>{console.log(">>> Initializing GameLogicChannel <<<");const e=document.getElementById("game-element");if(!e)return void console.warn("Game element not found. Skipping GameLogicChannel initialization.");const t=e.dataset.gameId,n=parseInt(e.dataset.userId,10);try{await ensureGameMembership(t),await fetchGameState(t),console.log("After ensure membership"),gameLogicSubscription=App.cable.subscriptions.create({channel:"GameLogicChannel",game_id:t},{connected(){console.log(`Connected to GameLogicChannel for game ${t}`)},disconnected(){console.log("Disconnected from GameLogicChannel")},received(e){handleGameChannelEvent(e,n,lastPosition)},makeMove(e,t){handleMove(e,t,lastPosition,n,this)}}),attachGridCellListeners(lastPosition)}catch(i){console.error("Failed to initialize GameLogicChannel:",i)}},handleGameChannelEvent=(e,t)=>{switch(console.log(`data.type: ${e.type}`),e.type){case"game_state":e.positions&&updateGrid(e.positions);break;case"tile_updates":e.updates&&requestAnimationFrame(()=>{e.updates.forEach(e=>updateTile(e.x,e.y,e.username,e.color))});break;case"balance_update":e.user_id===t&&updateShardBalance(e.balance);break;case"balance_error":showFlashMessage(e.message,"alert"),triggerShardBalanceShake();break;case"error":showFlashMessage(e.message||"An error occurred.","alert");break;default:console.warn(`Unhandled data type: ${e.type}`)}},handleMove=(e,t,n,i,s)=>{const o=calculateDistance(n,{x:e,y:t});if(o===Infinity)return void showFlashMessage("Invalid move! You can only move vertically or horizontally.","alert");const r=calculateShardCost(o),c=parseInt(document.querySelector(".shard-balance-display p").textContent.match(/\d+/)[0],10);if(o>1&&r>c)return triggerShardBalanceShake(),void showFlashMessage("Insufficient shards to make this move!","alert");if(o>1){if(!confirm(`Moving ${o} tiles will cost ${r} shards. Proceed?`))return}const a=document.querySelector(`.grid-cell[data-x='${e}'][data-y='${t}']`);a&&a.classList.contains("occupied")?showFlashMessage("Invalid move! The target cell is already occupied.","alert"):(null!==n.x&&null!==n.y&&updateTile(n.x,n.y,null),s.perform("make_move",{x:e,y:t,user_id:i}),n.x=e,n.y=t)},attachGridCellListeners=e=>{document.querySelectorAll(".grid-cell").forEach(t=>{t.addEventListener("click",()=>{const n=parseInt(t.dataset.x,10),i=parseInt(t.dataset.y,10);null!==e.x&&null!==e.y||(e.x=n,e.y=i),gameLogicSubscription.makeMove(n,i)})})},calculateDistance=(e,t)=>{if(null===e.x||null===e.y)return 0;const n=Math.abs(t.x-e.x),i=Math.abs(t.y-e.y);return n>0&&i>0?Infinity:Math.max(n,i)},calculateShardCost=e=>(e-1)*SHARD_COST_PER_TILE,updateShardBalance=e=>{const t=document.querySelector(".shard-balance-display p");t&&(t.textContent=`Shard Balance: ${e} Shards`)},updateGrid=e=>{e.forEach(e=>{updateTile(e.x,e.y,e.username,e.color)})},updateTile=(e,t,n,i)=>{console.log(`updateTile data: x:${e}, y:${t}, username:${n}, color:${i} `);const s=document.querySelector(`.grid-cell[data-x='${e}'][data-y='${t}']`);if(s){if(!n)return s.innerHTML="",void(s.className="grid-cell");s.innerHTML=`<span>${n}</span>`,s.className=`grid-cell ${i} occupied`,console.log(`Updated tile at (${e}, ${t}) with username=${n}, color=${i}`)}else console.warn(`Tile at (${e}, ${t}) not found.`)},triggerShardBalanceShake=()=>{const e=document.querySelector(".shard-balance-display");e&&(e.classList.add("shake"),setTimeout(()=>{e.classList.remove("shake")},500))},showFlashMessage=(e,t="alert")=>{const n=document.getElementById("flash-messages");if(!n)return void console.error("Flash container not found. Unable to display flash message.");n.style.zIndex="1001";const i=document.createElement("div");i.className="alert"===t?"alert":"notice",i.innerHTML=`\n        ${e}\n        <button onclick="this.parentElement.style.display='none';" aria-label="Close flash message">\xd7</button>\n    `,n.appendChild(i),setTimeout(()=>{i.style.display="none",n.removeChild(i),n.style.zIndex="-1"},3e3)},fetchGameState=async e=>{try{const n=await fetch(`/games/${e}/game_state`);if(!n.ok)throw new Error(`Failed to fetch game state: ${n.statusText}`);const i=await n.json();i.positions?(console.log("Fetched game state:",i.positions),i.positions.forEach(e=>updateTile(e.x,e.y,e.username,e.color))):console.error("Unexpected response from game_state:",i)}catch(t){console.error("Error fetching game state:",t)}};document.addEventListener("turbolinks:load",async()=>{const e=document.getElementById("game-element");if(e){const t=e.dataset.gameId;await fetchGameState(t),await initializeGameLogicChannel()}}),document.addEventListener("turbolinks:before-visit",()=>{gameLogicSubscription&&(gameLogicSubscription.unsubscribe(),gameLogicSubscription=null)});
(function(global, factory) {
  typeof exports === "object" && typeof module !== "undefined" ? factory(exports) : typeof define === "function" && define.amd ? define([ "exports" ], factory) : (global = typeof globalThis !== "undefined" ? globalThis : global || self, 
  factory(global.ActionCable = {}));
})(this, (function(exports) {
  "use strict";
  var adapters = {
    logger: self.console,
    WebSocket: self.WebSocket
  };
  var logger = {
    log(...messages) {
      if (this.enabled) {
        messages.push(Date.now());
        adapters.logger.log("[ActionCable]", ...messages);
      }
    }
  };
  const now = () => (new Date).getTime();
  const secondsSince = time => (now() - time) / 1e3;
  class ConnectionMonitor {
    constructor(connection) {
      this.visibilityDidChange = this.visibilityDidChange.bind(this);
      this.connection = connection;
      this.reconnectAttempts = 0;
    }
    start() {
      if (!this.isRunning()) {
        this.startedAt = now();
        delete this.stoppedAt;
        this.startPolling();
        addEventListener("visibilitychange", this.visibilityDidChange);
        logger.log(`ConnectionMonitor started. stale threshold = ${this.constructor.staleThreshold} s`);
      }
    }
    stop() {
      if (this.isRunning()) {
        this.stoppedAt = now();
        this.stopPolling();
        removeEventListener("visibilitychange", this.visibilityDidChange);
        logger.log("ConnectionMonitor stopped");
      }
    }
    isRunning() {
      return this.startedAt && !this.stoppedAt;
    }
    recordPing() {
      this.pingedAt = now();
    }
    recordConnect() {
      this.reconnectAttempts = 0;
      this.recordPing();
      delete this.disconnectedAt;
      logger.log("ConnectionMonitor recorded connect");
    }
    recordDisconnect() {
      this.disconnectedAt = now();
      logger.log("ConnectionMonitor recorded disconnect");
    }
    startPolling() {
      this.stopPolling();
      this.poll();
    }
    stopPolling() {
      clearTimeout(this.pollTimeout);
    }
    poll() {
      this.pollTimeout = setTimeout((() => {
        this.reconnectIfStale();
        this.poll();
      }), this.getPollInterval());
    }
    getPollInterval() {
      const {staleThreshold: staleThreshold, reconnectionBackoffRate: reconnectionBackoffRate} = this.constructor;
      const backoff = Math.pow(1 + reconnectionBackoffRate, Math.min(this.reconnectAttempts, 10));
      const jitterMax = this.reconnectAttempts === 0 ? 1 : reconnectionBackoffRate;
      const jitter = jitterMax * Math.random();
      return staleThreshold * 1e3 * backoff * (1 + jitter);
    }
    reconnectIfStale() {
      if (this.connectionIsStale()) {
        logger.log(`ConnectionMonitor detected stale connection. reconnectAttempts = ${this.reconnectAttempts}, time stale = ${secondsSince(this.refreshedAt)} s, stale threshold = ${this.constructor.staleThreshold} s`);
        this.reconnectAttempts++;
        if (this.disconnectedRecently()) {
          logger.log(`ConnectionMonitor skipping reopening recent disconnect. time disconnected = ${secondsSince(this.disconnectedAt)} s`);
        } else {
          logger.log("ConnectionMonitor reopening");
          this.connection.reopen();
        }
      }
    }
    get refreshedAt() {
      return this.pingedAt ? this.pingedAt : this.startedAt;
    }
    connectionIsStale() {
      return secondsSince(this.refreshedAt) > this.constructor.staleThreshold;
    }
    disconnectedRecently() {
      return this.disconnectedAt && secondsSince(this.disconnectedAt) < this.constructor.staleThreshold;
    }
    visibilityDidChange() {
      if (document.visibilityState === "visible") {
        setTimeout((() => {
          if (this.connectionIsStale() || !this.connection.isOpen()) {
            logger.log(`ConnectionMonitor reopening stale connection on visibilitychange. visibilityState = ${document.visibilityState}`);
            this.connection.reopen();
          }
        }), 200);
      }
    }
  }
  ConnectionMonitor.staleThreshold = 6;
  ConnectionMonitor.reconnectionBackoffRate = .15;
  var INTERNAL = {
    message_types: {
      welcome: "welcome",
      disconnect: "disconnect",
      ping: "ping",
      confirmation: "confirm_subscription",
      rejection: "reject_subscription"
    },
    disconnect_reasons: {
      unauthorized: "unauthorized",
      invalid_request: "invalid_request",
      server_restart: "server_restart"
    },
    default_mount_path: "/cable",
    protocols: [ "actioncable-v1-json", "actioncable-unsupported" ]
  };
  const {message_types: message_types, protocols: protocols} = INTERNAL;
  const supportedProtocols = protocols.slice(0, protocols.length - 1);
  const indexOf = [].indexOf;
  class Connection {
    constructor(consumer) {
      this.open = this.open.bind(this);
      this.consumer = consumer;
      this.subscriptions = this.consumer.subscriptions;
      this.monitor = new ConnectionMonitor(this);
      this.disconnected = true;
    }
    send(data) {
      if (this.isOpen()) {
        this.webSocket.send(JSON.stringify(data));
        return true;
      } else {
        return false;
      }
    }
    open() {
      if (this.isActive()) {
        logger.log(`Attempted to open WebSocket, but existing socket is ${this.getState()}`);
        return false;
      } else {
        logger.log(`Opening WebSocket, current state is ${this.getState()}, subprotocols: ${protocols}`);
        if (this.webSocket) {
          this.uninstallEventHandlers();
        }
        this.webSocket = new adapters.WebSocket(this.consumer.url, protocols);
        this.installEventHandlers();
        this.monitor.start();
        return true;
      }
    }
    close({allowReconnect: allowReconnect} = {
      allowReconnect: true
    }) {
      if (!allowReconnect) {
        this.monitor.stop();
      }
      if (this.isOpen()) {
        return this.webSocket.close();
      }
    }
    reopen() {
      logger.log(`Reopening WebSocket, current state is ${this.getState()}`);
      if (this.isActive()) {
        try {
          return this.close();
        } catch (error) {
          logger.log("Failed to reopen WebSocket", error);
        } finally {
          logger.log(`Reopening WebSocket in ${this.constructor.reopenDelay}ms`);
          setTimeout(this.open, this.constructor.reopenDelay);
        }
      } else {
        return this.open();
      }
    }
    getProtocol() {
      if (this.webSocket) {
        return this.webSocket.protocol;
      }
    }
    isOpen() {
      return this.isState("open");
    }
    isActive() {
      return this.isState("open", "connecting");
    }
    isProtocolSupported() {
      return indexOf.call(supportedProtocols, this.getProtocol()) >= 0;
    }
    isState(...states) {
      return indexOf.call(states, this.getState()) >= 0;
    }
    getState() {
      if (this.webSocket) {
        for (let state in adapters.WebSocket) {
          if (adapters.WebSocket[state] === this.webSocket.readyState) {
            return state.toLowerCase();
          }
        }
      }
      return null;
    }
    installEventHandlers() {
      for (let eventName in this.events) {
        const handler = this.events[eventName].bind(this);
        this.webSocket[`on${eventName}`] = handler;
      }
    }
    uninstallEventHandlers() {
      for (let eventName in this.events) {
        this.webSocket[`on${eventName}`] = function() {};
      }
    }
  }
  Connection.reopenDelay = 500;
  Connection.prototype.events = {
    message(event) {
      if (!this.isProtocolSupported()) {
        return;
      }
      const {identifier: identifier, message: message, reason: reason, reconnect: reconnect, type: type} = JSON.parse(event.data);
      switch (type) {
       case message_types.welcome:
        this.monitor.recordConnect();
        return this.subscriptions.reload();

       case message_types.disconnect:
        logger.log(`Disconnecting. Reason: ${reason}`);
        return this.close({
          allowReconnect: reconnect
        });

       case message_types.ping:
        return this.monitor.recordPing();

       case message_types.confirmation:
        this.subscriptions.confirmSubscription(identifier);
        return this.subscriptions.notify(identifier, "connected");

       case message_types.rejection:
        return this.subscriptions.reject(identifier);

       default:
        return this.subscriptions.notify(identifier, "received", message);
      }
    },
    open() {
      logger.log(`WebSocket onopen event, using '${this.getProtocol()}' subprotocol`);
      this.disconnected = false;
      if (!this.isProtocolSupported()) {
        logger.log("Protocol is unsupported. Stopping monitor and disconnecting.");
        return this.close({
          allowReconnect: false
        });
      }
    },
    close(event) {
      logger.log("WebSocket onclose event");
      if (this.disconnected) {
        return;
      }
      this.disconnected = true;
      this.monitor.recordDisconnect();
      return this.subscriptions.notifyAll("disconnected", {
        willAttemptReconnect: this.monitor.isRunning()
      });
    },
    error() {
      logger.log("WebSocket onerror event");
    }
  };
  const extend = function(object, properties) {
    if (properties != null) {
      for (let key in properties) {
        const value = properties[key];
        object[key] = value;
      }
    }
    return object;
  };
  class Subscription {
    constructor(consumer, params = {}, mixin) {
      this.consumer = consumer;
      this.identifier = JSON.stringify(params);
      extend(this, mixin);
    }
    perform(action, data = {}) {
      data.action = action;
      return this.send(data);
    }
    send(data) {
      return this.consumer.send({
        command: "message",
        identifier: this.identifier,
        data: JSON.stringify(data)
      });
    }
    unsubscribe() {
      return this.consumer.subscriptions.remove(this);
    }
  }
  class SubscriptionGuarantor {
    constructor(subscriptions) {
      this.subscriptions = subscriptions;
      this.pendingSubscriptions = [];
    }
    guarantee(subscription) {
      if (this.pendingSubscriptions.indexOf(subscription) == -1) {
        logger.log(`SubscriptionGuarantor guaranteeing ${subscription.identifier}`);
        this.pendingSubscriptions.push(subscription);
      } else {
        logger.log(`SubscriptionGuarantor already guaranteeing ${subscription.identifier}`);
      }
      this.startGuaranteeing();
    }
    forget(subscription) {
      logger.log(`SubscriptionGuarantor forgetting ${subscription.identifier}`);
      this.pendingSubscriptions = this.pendingSubscriptions.filter((s => s !== subscription));
    }
    startGuaranteeing() {
      this.stopGuaranteeing();
      this.retrySubscribing();
    }
    stopGuaranteeing() {
      clearTimeout(this.retryTimeout);
    }
    retrySubscribing() {
      this.retryTimeout = setTimeout((() => {
        if (this.subscriptions && typeof this.subscriptions.subscribe === "function") {
          this.pendingSubscriptions.map((subscription => {
            logger.log(`SubscriptionGuarantor resubscribing ${subscription.identifier}`);
            this.subscriptions.subscribe(subscription);
          }));
        }
      }), 500);
    }
  }
  class Subscriptions {
    constructor(consumer) {
      this.consumer = consumer;
      this.guarantor = new SubscriptionGuarantor(this);
      this.subscriptions = [];
    }
    create(channelName, mixin) {
      const channel = channelName;
      const params = typeof channel === "object" ? channel : {
        channel: channel
      };
      const subscription = new Subscription(this.consumer, params, mixin);
      return this.add(subscription);
    }
    add(subscription) {
      this.subscriptions.push(subscription);
      this.consumer.ensureActiveConnection();
      this.notify(subscription, "initialized");
      this.subscribe(subscription);
      return subscription;
    }
    remove(subscription) {
      this.forget(subscription);
      if (!this.findAll(subscription.identifier).length) {
        this.sendCommand(subscription, "unsubscribe");
      }
      return subscription;
    }
    reject(identifier) {
      return this.findAll(identifier).map((subscription => {
        this.forget(subscription);
        this.notify(subscription, "rejected");
        return subscription;
      }));
    }
    forget(subscription) {
      this.guarantor.forget(subscription);
      this.subscriptions = this.subscriptions.filter((s => s !== subscription));
      return subscription;
    }
    findAll(identifier) {
      return this.subscriptions.filter((s => s.identifier === identifier));
    }
    reload() {
      return this.subscriptions.map((subscription => this.subscribe(subscription)));
    }
    notifyAll(callbackName, ...args) {
      return this.subscriptions.map((subscription => this.notify(subscription, callbackName, ...args)));
    }
    notify(subscription, callbackName, ...args) {
      let subscriptions;
      if (typeof subscription === "string") {
        subscriptions = this.findAll(subscription);
      } else {
        subscriptions = [ subscription ];
      }
      return subscriptions.map((subscription => typeof subscription[callbackName] === "function" ? subscription[callbackName](...args) : undefined));
    }
    subscribe(subscription) {
      if (this.sendCommand(subscription, "subscribe")) {
        this.guarantor.guarantee(subscription);
      }
    }
    confirmSubscription(identifier) {
      logger.log(`Subscription confirmed ${identifier}`);
      this.findAll(identifier).map((subscription => this.guarantor.forget(subscription)));
    }
    sendCommand(subscription, command) {
      const {identifier: identifier} = subscription;
      return this.consumer.send({
        command: command,
        identifier: identifier
      });
    }
  }
  class Consumer {
    constructor(url) {
      this._url = url;
      this.subscriptions = new Subscriptions(this);
      this.connection = new Connection(this);
    }
    get url() {
      return createWebSocketURL(this._url);
    }
    send(data) {
      return this.connection.send(data);
    }
    connect() {
      return this.connection.open();
    }
    disconnect() {
      return this.connection.close({
        allowReconnect: false
      });
    }
    ensureActiveConnection() {
      if (!this.connection.isActive()) {
        return this.connection.open();
      }
    }
  }
  function createWebSocketURL(url) {
    if (typeof url === "function") {
      url = url();
    }
    if (url && !/^wss?:/i.test(url)) {
      const a = document.createElement("a");
      a.href = url;
      a.href = a.href;
      a.protocol = a.protocol.replace("http", "ws");
      return a.href;
    } else {
      return url;
    }
  }
  function createConsumer(url = getConfig("url") || INTERNAL.default_mount_path) {
    return new Consumer(url);
  }
  function getConfig(name) {
    const element = document.head.querySelector(`meta[name='action-cable-${name}']`);
    if (element) {
      return element.getAttribute("content");
    }
  }
  exports.Connection = Connection;
  exports.ConnectionMonitor = ConnectionMonitor;
  exports.Consumer = Consumer;
  exports.INTERNAL = INTERNAL;
  exports.Subscription = Subscription;
  exports.SubscriptionGuarantor = SubscriptionGuarantor;
  exports.Subscriptions = Subscriptions;
  exports.adapters = adapters;
  exports.createConsumer = createConsumer;
  exports.createWebSocketURL = createWebSocketURL;
  exports.getConfig = getConfig;
  exports.logger = logger;
  Object.defineProperty(exports, "__esModule", {
    value: true
  });
}));

const createConsumer = ActionCable.createConsumer;

window.App || (window.App = {});
App.cable = createConsumer();
console.log("App.cable initialized:", App.cable);



let chatSubscription = null;

const ensureMembership = async (serverId) => {
    try {
        const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
        const response = await fetch(`/servers/${serverId}/ensure_membership.json`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-CSRF-Token": csrfToken,
            },
        });
        if (!response.ok) {
            throw new Error(`Failed to ensure membership: ${response.statusText}`);
        }

        const data = await response.json();
        if (data.message === "Membership ensured") {
            console.log("Membership already exists.");
        } else {
            console.log("Membership ensured:", data);
        }
    } catch (error) {
        console.error("Error ensuring membership:", error);
    }
};

const initializeChannel = async () => {
    const serverElement = document.getElementById("server-id");
    const messagesContainer = document.getElementById("messages");
    const messageForm = document.getElementById("message-form");

    if (!serverElement || !messagesContainer) {
        console.warn("Required elements not found. Skipping channel initialization.");
        return;
    }

    const serverId = serverElement.dataset.serverId;

    // Ensure membership before subscribing
    await ensureMembership(serverId);

    // Avoid duplicate subscriptions
    if (chatSubscription) {
        console.warn("Already subscribed to ServerChannel. Skipping subscription.");
        return;
    }

    // Subscribe to the server channel
    chatSubscription = App.cable.subscriptions.create(
        { channel: "ServerChannel", server_id: serverId },
        {
            connected() {
                console.log(`Connected to ServerChannel for server_${serverId}`);
            },
            disconnected() {
                console.log(`Disconnected from ServerChannel for server_${serverId}`);
                chatSubscription = null;
            },
            received(data) {
                handleReceivedData(data, messagesContainer);
            },
        }
    );

    // Attach event listener to the message form
    if (messageForm) {
        setupMessageForm(messageForm, chatSubscription);
    } else {
        console.warn("Message form not found. Skipping message submission setup.");
    }
};

// Handle received data (messages, system notifications, user statuses)
const handleReceivedData = (data, messagesContainer) => {
    if (data.type === "message") {
        // Ensure the message is appended only once
        const existingMessage = document.querySelector(`[data-message-id='${data.message.id}']`);
        if (!existingMessage) {
            appendMessage(messagesContainer, data.message);
        }
    } else if (data.type === "system") {
        // Ensure system messages are appended only once
        const existingSystemMessage = document.querySelector(`[data-system-message='${data.message}']`);
        if (!existingSystemMessage) {
            appendSystemMessage(messagesContainer, data.message);
        }
    } else if (data.type === "status" && data.user_id) {
        // Ensure status updates are processed only once
        updateUserStatus(data);
    } else {
        console.warn("Unexpected data received:", JSON.stringify(data, null, 2));
    }
};

// Append a regular chat message
const appendMessage = (container, message) => {
    if (container) {
        container.insertAdjacentHTML("beforeend", message);
        scrollToBottom(container);
    }
};

// Append a system message
const appendSystemMessage = (container, message) => {
    if (container) {
        container.insertAdjacentHTML(
            "beforeend",
            `<div data-system-message="${message}"><em>${message}</em></div>`
        );
        scrollToBottom(container);
    }
};

// Scroll to the bottom of a container
const scrollToBottom = (container) => {
    container.scrollTop = container.scrollHeight;
};

// Set up the message form for submission
const setupMessageForm = (form, subscription) => {
    const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
    const messageInput = document.getElementById("message-input");

    if (!messageInput) {
        console.warn("Message input field not found.");
        return;
    }

    form.addEventListener("submit", (event) => {
        event.preventDefault();
        const message = messageInput.value.trim();
        if (message !== "") {
            subscription.perform("send_message", {
                message: message,
                authenticity_token: csrfToken,
            });
            messageInput.value = ""; // Clear input field after sending
        }
    });
};

// Update user status dynamically
const updateUserStatus = (data) => {
    const userElement = document.querySelector(`.user[data-user-id='${data.user_id}']`);
    if (userElement) {
        console.log(`Updating user ${data.user_id} status to ${data.status}`);
        userElement.classList.remove("online", "offline");
        userElement.classList.add(data.status);
    } else {
        console.warn(`User element with ID ${data.user_id} not found.`);
    }
};


document.addEventListener("turbolinks:before-visit", () => {
    if (chatSubscription) {
        chatSubscription.unsubscribe();
        chatSubscription = null;
        console.log("Unsubscribed from ServerChannel before navigation.");
    }
});

// Attach initialization to Turbolinks and DOM events
document.addEventListener("DOMContentLoaded", initializeChannel);
document.addEventListener("turbolinks:load", initializeChannel);

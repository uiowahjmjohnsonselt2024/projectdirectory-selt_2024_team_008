// = require ./consumer
// = require actioncable

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
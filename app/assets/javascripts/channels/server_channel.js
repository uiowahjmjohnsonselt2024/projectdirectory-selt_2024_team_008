// = require ./consumer
// = require actioncable

let channelInitialized = false;
let chatSubscription = null;

const initializeChannel = () => {
    if (channelInitialized) {
        console.log("Channel already initialized. Skipping...");
        return;
    }

    console.log("Initializing ServerChannel");
    channelInitialized = true;

    const serverElement = document.getElementById("server-id");
    const messagesContainer = document.getElementById("messages");

    if (serverElement) {
        const serverId = serverElement.dataset.serverId;

        // Subscribe to the server channel
        chatSubscription = App.cable.subscriptions.create(
            { channel: "ServerChannel", server_id: serverId },
            {
                connected() {
                    console.log(`Connected to ServerChannel for server_${serverId}`);
                },
                disconnected() {
                    console.log(`Disconnected from ServerChannel for server_${serverId}`);
                },
                received(data) {
                    if (data.type === 'message') {
                        // Handle normal chat messages
                        console.log("New chat message received:", data.message);
                        if (messagesContainer) {
                            messagesContainer.insertAdjacentHTML("beforeend", data.message);
                            messagesContainer.scrollTop = messagesContainer.scrollHeight;
                        }
                    } else if (data.type === 'system') {
                        // Handle system messages (e.g., user join/leave)
                        console.log("System message received:", data.message);
                        if (messagesContainer) {
                            messagesContainer.insertAdjacentHTML("beforeend", `<em>${data.message}</em>`);
                            messagesContainer.scrollTop = messagesContainer.scrollHeight;
                        }
                    } else if (data.type === 'status' && data.user_id) {
                        // Handle status updates
                        console.log(`Status update received for user ${data.user_id}: ${data.status}`);
                        updateUserStatus(data);
                    } else {
                        console.warn("Unexpected data received:", JSON.stringify(data, null, 2));
                    }
                },
            }
        );

        // Event listener to the message form for sending messages
        const messageForm = document.getElementById("message-form");
        if (messageForm) {
            console.log(">>> Inside messageForm");
            messageForm.addEventListener("submit", (event) => {
                event.preventDefault();
                const input = document.getElementById("message-input");
                if (input.value.trim() !== "") {
                    chatSubscription.perform("send_message", { message: input.value }); // Calls send_message
                    input.value = ""; // Clear input field after sending
                }
            });
        } else {
            console.warn("Message form not found. Skipping message submission setup.");
        }
    } else {
        console.warn("Server ID element not found. Skipping channel initialization.");
    }
};

// Function to update user status dynamically
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

// Attach initialization to Turbolinks and DOM events
document.addEventListener("DOMContentLoaded", () => {
    if (!channelInitialized) {
        initializeChannel();
    }
});
document.addEventListener("turbolinks:load", () => {
    if (!channelInitialized) {
        initializeChannel();
    }
});
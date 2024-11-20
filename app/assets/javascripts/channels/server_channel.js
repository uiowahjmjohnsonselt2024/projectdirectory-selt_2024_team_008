// = require ./consumer
// = require actioncable

let channelInitialized = false;

const initializeChannel = () => {
    if (channelInitialized) {
        console.log("Channel already initialized. Skipping...");
        return;
    }
    channelInitialized = true;

    console.log("Initializing ServerChannel");

    const serverElement = document.getElementById("server-id");
    const messagesContainer = document.getElementById("messages");

    if (serverElement && messagesContainer) {
        const serverId = serverElement.dataset.serverId;

        // Unsubscribe from existing subscriptions for the same server
        App.cable.subscriptions.subscriptions.forEach((subscription) => {
            if (subscription.identifier.includes(`"server_id":"${serverId}"`)) {
                console.warn(`Unsubscribing duplicate subscription for server_${serverId}`);
                subscription.unsubscribe();
            }
        });

        // Create a new subscription
        const subscription = App.cable.subscriptions.create(
            { channel: "ServerChannel", server_id: serverId },
            {
                connected() {
                    console.log(`Connected to ServerChannel for server_${serverId}`);
                },
                disconnected() {
                    console.log(`Disconnected from ServerChannel for server_${serverId}`);
                },
                received(data) {
                    console.log("Message received:", data);

                    if (data.message) {
                        messagesContainer.insertAdjacentHTML("beforeend", data.message);
                        messagesContainer.scrollTop = messagesContainer.scrollHeight;
                    } else {
                        console.error("Received invalid data:", data);
                    }
                },
            }
        );

        console.log("Subscription created:", subscription);
    } else {
        console.warn("Server ID or messages container not found. Skipping setup.");
    }
};

// Compatibility for both DOMContentLoaded and Turbolinks
document.addEventListener("DOMContentLoaded", initializeChannel);
document.addEventListener("turbolinks:load", () => {
    channelInitialized = false; // Reset flag for Turbolinks navigation
    initializeChannel();
});
import consumer from "./consumer";

export function setupServerChannel() {
    document.addEventListener("turbolinks:load", () => {
        // Get server ID and messages container
        const serverElement = document.getElementById("server-id");
        const messagesContainer = document.getElementById("messages");

        if (serverElement && messagesContainer) {
            const serverId = serverElement.dataset.serverId;

            // Ensure no duplicate subscriptions
            consumer.subscriptions.subscriptions.forEach((subscription) => {
                if (subscription.identifier.includes(`"server_id":"${serverId}"`)) {
                    subscription.unsubscribe();
                }
            });

            consumer.subscriptions.create(
                { channel: "ServerChannel", server_id: serverId },
                {
                    connected() {
                        console.log(`Connected to ServerChannel for server ID: ${serverId}`);
                    },

                    disconnected() {
                        console.log(`Disconnected from ServerChannel for server ID: ${serverId}`);
                    },

                    received(data) {
                        console.log("Message received:", data);

                        // Validate and append the message
                        if (data.message) {
                            messagesContainer.insertAdjacentHTML("beforeend", data.message);
                            messagesContainer.scrollTop = messagesContainer.scrollHeight
                        } else {
                            console.error("Received data does not contain a message:", data);
                        }
                    },
                }
            );
        } else {
            console.warn("Server ID or messages container not found. Ensure the HTML structure is correct.");
        }
    });
}

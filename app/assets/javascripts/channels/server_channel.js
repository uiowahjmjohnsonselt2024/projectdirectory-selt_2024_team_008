//= require ./consumer
//= require actioncable

console.log(">>> server_channel.js loaded <<<");

window.setupServerChannel = function () {
    console.log("Setting up server channel");

    const serverElement = document.getElementById("server-id");
    const messagesContainer = document.getElementById("messages");

    if (!serverElement) {
        console.error("Server ID element (div#server-id) is missing from the DOM!");
    } else {
        console.log("Found serverElement:", serverElement);
    }

    if (!messagesContainer) {
        console.error("Messages container element (div#messages) is missing from the DOM!");
    } else {
        console.log("Found messagesContainer:", messagesContainer);
    }

    if (serverElement && messagesContainer) {
        const serverId = serverElement.dataset.serverId;
        console.log(`Subscribing to server_${serverId}`);

        // Ensure no duplicate subscriptions
        App.cable.subscriptions.subscriptions.forEach((subscription) => {
            if (subscription.identifier.includes(`"server_id":"${serverId}"`)) {
                console.warn(`Unsubscribing duplicate subscription for server_${serverId}`);
                subscription.unsubscribe();
            }
        });

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
                        console.error("Received data does not contain a message:", data);
                    }
                },
            }
        );

        console.log("Subscription created:", subscription);
    }
};

document.addEventListener("turbolinks:load", () => {
    console.log(">>> turbolinks:load event fired <<<");
    setupServerChannel();
});

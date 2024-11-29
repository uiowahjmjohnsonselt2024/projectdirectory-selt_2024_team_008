console.log(">>> server.js loaded <<<");

document.addEventListener("turbolinks:load", () => {
    console.log(">>> turbolinks:load event fired in server.js <<<");

    // Dynamically enable/disable the "Send" button
    const messageInput = document.getElementById("message_content");
    const sendButton = document.getElementById("send_button");

    if (messageInput && sendButton) {
        console.log(">>> Enabling dynamic send button behavior <<<");

        // Enable/disable the "Send" button dynamically
        messageInput.addEventListener("input", () => {
            sendButton.disabled = messageInput.value.trim() === "";
        });

        // Set initial state for the "Send" button
        sendButton.disabled = messageInput.value.trim() === "";
    } else {
        console.warn(">>> messageInput or sendButton not found <<<");
    }
});

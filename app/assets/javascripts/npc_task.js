document.addEventListener("DOMContentLoaded", () => {
    const chatHistory = document.getElementById("chat-history");
    const responseForm = document.getElementById("npc-response-form");
    const userResponse = document.getElementById("user-response");

    responseForm.addEventListener("submit", (event) => {
        event.preventDefault();

        const userMessage = userResponse.value.trim();
        if (userMessage) {

            // Append user message to chat with a specific class
            const userMessageElement = document.createElement("p");
            userMessageElement.classList.add("user-message");
            userMessageElement.innerHTML = `<strong>You:</strong> ${userMessage}`;
            chatHistory.appendChild(userMessageElement);

            // Clear the input
            userResponse.value = "";

            // Scroll to the bottom
            chatHistory.scrollTop = chatHistory.scrollHeight;

            // Append NPC response with a specific class
            const npcMessageElement = document.createElement("p");
            npcMessageElement.classList.add("npc-message");
            npcMessageElement.innerHTML = `<strong>NPC:</strong> Yes`;
            chatHistory.appendChild(npcMessageElement);

            // Scroll to the bottom
            chatHistory.scrollTop = chatHistory.scrollHeight;
        }
    });
});

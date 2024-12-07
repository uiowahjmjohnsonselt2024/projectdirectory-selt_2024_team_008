document.addEventListener("DOMContentLoaded", () => {
    const chatHistory = document.getElementById("chat-history");
    const responseForm = document.getElementById("npc-response-form");
    const userResponse = document.getElementById("user-response");

    responseForm.addEventListener("submit", (event) => {
        event.preventDefault();

        const userMessage = userResponse.value.trim();
        if (userMessage) {

            const userMessageElement = document.createElement("p");
            userMessageElement.innerHTML = `<strong>You:</strong> ${userMessage}`;
            chatHistory.appendChild(userMessageElement);

            userResponse.value = "";

            chatHistory.scrollTop = chatHistory.scrollHeight;

            const npcMessageElement = document.createElement("p");
            npcMessageElement.innerHTML = `<strong>NPC:</strong> Yes`;
            chatHistory.appendChild(npcMessageElement);

            chatHistory.scrollTop = chatHistory.scrollHeight;
        }
    });
});

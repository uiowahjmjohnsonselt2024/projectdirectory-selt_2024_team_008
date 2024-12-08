document.addEventListener("DOMContentLoaded", () => {
    const chatHistory = document.getElementById("chat-history");
    const responseForm = document.getElementById("npc-response-form");
    const userResponse = document.getElementById("user-response");
    const startButton = document.getElementById("start-interaction");
    const shardBalanceDisplay = document.querySelector(".shard-balance-display p");

    responseForm.classList.add("hidden");


    startButton.addEventListener("click", () => {
        startButton.classList.add("hidden"); // Hide start button
        responseForm.classList.remove("hidden"); // Show form

        // Fetch the first riddle
        fetch("/npc_task/chat", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').getAttribute("content"),
            },
            body: JSON.stringify({ message: null }), // Sending null to indicate page load
        })
            .then((response) => response.json())
            .then((data) => {
                const npcMessageElement = document.createElement("p");
                npcMessageElement.classList.add("npc-message");
                npcMessageElement.innerHTML = `<strong>NPC:</strong> ${data.npc_message}`;
                chatHistory.appendChild(npcMessageElement);
                chatHistory.scrollTop = chatHistory.scrollHeight;
            })
            .catch((error) => {
                console.error("Error fetching riddle:", error);
            });
    });


    responseForm.addEventListener("submit", (event) => {
        event.preventDefault();

        const userMessage = userResponse.value.trim();
        if (userMessage) {
            const userMessageElement = document.createElement("p");
            userMessageElement.classList.add("user-message");
            userMessageElement.innerHTML = `<strong>You:</strong> ${userMessage}`;
            chatHistory.appendChild(userMessageElement);

            userResponse.value = "";

            chatHistory.scrollTop = chatHistory.scrollHeight;

            fetch("/npc_task/chat", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').getAttribute("content"),
                },
                body: JSON.stringify({ message: userMessage }),
            })
                .then((response) => response.json())
                .then((data) => {
                    const npcMessageElement = document.createElement("p");
                    npcMessageElement.classList.add("npc-message");
                    npcMessageElement.innerHTML = `<strong>NPC:</strong> ${data.npc_message}`;
                    chatHistory.appendChild(npcMessageElement);

                    if (data.new_shard_balance !== undefined) {
                        shardBalanceDisplay.textContent = `Shard Balance: ${data.new_shard_balance} Shards`;
                    }

                    chatHistory.scrollTop = chatHistory.scrollHeight;
                })
                .catch((error) => {
                    console.error("Error:", error);
                    const errorMessageElement = document.createElement("p");
                    errorMessageElement.classList.add("npc-message");
                    errorMessageElement.innerHTML = `<strong>NPC:</strong> Sorry, something went wrong. Please try again.`;
                    chatHistory.appendChild(errorMessageElement);
                    chatHistory.scrollTop = chatHistory.scrollHeight;
                });
        }
    });
});

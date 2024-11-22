document.addEventListener("DOMContentLoaded", () => {
    console.log("multiplayer_sessions.js loaded");

    // Chat room elements
    const chatRoom = document.getElementById("chatRoom");
    const chatRoomToggle = document.getElementById("chatRoomToggle");
    const chatRoomClose = document.getElementById("chatRoomClose");
    const messagesContainer = document.getElementById("messages");
    const serverIdElement = document.getElementById("server-id");

    if (chatRoom && chatRoomToggle && chatRoomClose) {
        // Toggle chat room visibility
        chatRoomToggle.addEventListener("click", () => {
            chatRoom.style.display = "block";

            // Load messages dynamically when the chat room is opened
            if (messagesContainer && serverIdElement) {
                const serverId = serverIdElement.dataset.serverId;

                fetch(`/servers/${serverId}/messages`)
                    .then((response) => {
                        if (!response.ok) throw new Error("Failed to load messages");
                        return response.text();
                    })
                    .then((messagesHtml) => {
                        messagesContainer.innerHTML = messagesHtml;
                        console.log("Messages loaded into chat room");

                        // Scroll to the bottom of the messages container
                        scrollToBottom(messagesContainer);
                    })
                    .catch((error) => {
                        console.error("Error loading messages:", error);
                    });
            }
        });

        chatRoomClose.addEventListener("click", () => {
            chatRoom.style.display = "none";
        });
    } else {
        console.warn("Chat room elements not found. Skipping toggle functionality.");
    }

    // Function to scroll to the bottom of the messages container
    const scrollToBottom = (container) => {
        container.scrollTop = container.scrollHeight;
    };

    // Observe new messages and ensure scrolling
    if (messagesContainer) {
        const observer = new MutationObserver(() => {
            scrollToBottom(messagesContainer);
        });

        observer.observe(messagesContainer, { childList: true });
    }
});
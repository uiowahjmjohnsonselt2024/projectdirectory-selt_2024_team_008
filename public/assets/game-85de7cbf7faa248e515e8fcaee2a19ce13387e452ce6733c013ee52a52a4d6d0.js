document.addEventListener("turbolinks:load", () => {
    console.log("multiplayer_sessions.js loaded");

    const chatRoom = document.getElementById("chatRoom");
    const chatRoomToggle = document.getElementById("chatRoomToggle");
    const chatRoomClose = document.getElementById("chatRoomClose");

    if (!chatRoom || !chatRoomToggle || !chatRoomClose) {
        console.warn("Chat room elements not found. Skipping toggle functionality.");
        return;
    }

    chatRoomToggle.addEventListener("click", () => {
        chatRoom.style.display = "block"; // Show chat room
    });

    chatRoomClose.addEventListener("click", () => {
        chatRoom.style.display = "none"; // Hide chat room
    });

    document.addEventListener("click", (event) => {
        const isClickInside = chatRoom.contains(event.target) || chatRoomToggle.contains(event.target);
        if (!isClickInside && chatRoom.style.display === "block") {
            chatRoom.style.display = "none";
            console.log("Chat room closed by clicking outside.");
        }
    });
});

document.addEventListener("DOMContentLoaded", () => {
    console.log("multiplayer_sessions.js loaded");

    const chatRoom = document.getElementById("chatRoom");
    const chatRoomToggle = document.getElementById("chatRoomToggle");
    const chatRoomClose = document.getElementById("chatRoomClose");

    if (chatRoom && chatRoomToggle && chatRoomClose) {
        chatRoomToggle.addEventListener("click", () => {
            chatRoom.style.display = "block";
        });

        chatRoomClose.addEventListener("click", () => {
            chatRoom.style.display = "none";
        });
    } else {
        console.warn("Chat room elements not found. Skipping toggle functionality.");
    }
});
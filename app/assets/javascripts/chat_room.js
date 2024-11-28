document.addEventListener("turbolinks:load", () => {
    console.log("chat_room.js loaded");

    const chatRoom = document.getElementById("chatRoom");
    const chatRoomToggle = document.getElementById("chatRoomToggle");
    const chatRoomClose = document.getElementById("chatRoomClose");

    if (!chatRoom || !chatRoomToggle || !chatRoomClose) {
        console.warn("Chat room elements not found. Skipping toggle functionality.");
        return;
    }

    // Remove existing event listeners to prevent stacking
    chatRoomToggle.replaceWith(chatRoomToggle.cloneNode(true));
    chatRoomClose.replaceWith(chatRoomClose.cloneNode(true));

    // Re-fetch elements after cloning
    const newChatRoomToggle = document.getElementById("chatRoomToggle");
    const newChatRoomClose = document.getElementById("chatRoomClose");

    // Show chat room and hide button
    newChatRoomToggle.addEventListener("click", () => {
        chatRoom.style.display = "block";
        newChatRoomToggle.style.display = "none";
    });

    // Hide chat room and show button
    newChatRoomClose.addEventListener("click", () => {
        chatRoom.style.display = "none";
        newChatRoomToggle.style.display = "block";
    });

    // Close chat room by clicking outside
    document.addEventListener("click", (event) => {
        const isClickInside =
            chatRoom.contains(event.target) || newChatRoomToggle.contains(event.target);
        if (!isClickInside && chatRoom.style.display === "block") {
            chatRoom.style.display = "none";
            newChatRoomToggle.style.display = "block";
            console.log("Chat room closed by clicking outside.");
        }
    });
});
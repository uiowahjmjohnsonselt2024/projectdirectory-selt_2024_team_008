import consumer from "./consumer"

consumer.subscriptions.create({ channel: "ServerChannel", server_id: SERVER_ID }, {
    received(data) {
        const messages = document.getElementById("messages")
        messages.insertAdjacentHTML("beforeend", data)
    }
})
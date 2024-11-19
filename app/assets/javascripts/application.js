//= require rails-ujs
//= require turbolinks
//= require channels/server_channel
//= require actioncable
//= require servers
//= require_tree .

console.log(">>> application.js loaded <<<");

document.addEventListener("turbolinks:load", () => {
    console.log(">>> turbolinks:load event fired <<<");

    // Check if the user is on a server page
    if (window.location.pathname.startsWith("/servers")) {
        console.log(">>> Initializing ServerChannel <<<");

        const serverElement = document.getElementById("server-id");
        if (serverElement) {
            setupServerChannel(); // Call the function to initialize the channel
        } else {
            console.warn(">>> Server ID element not found <<<");
        }
    } else {
        console.log(">>> ServerChannel not initialized (wrong path) <<<");
    }
});

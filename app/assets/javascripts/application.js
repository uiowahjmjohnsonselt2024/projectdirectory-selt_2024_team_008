//= require rails-ujs
//= require turbolinks
//= require_tree .

if (window.location.pathname.startsWith("/servers")) {
    import("./channels/server_channel").then((module) => {
        module.setupServerChannel(); // Call the setup function
    });
}

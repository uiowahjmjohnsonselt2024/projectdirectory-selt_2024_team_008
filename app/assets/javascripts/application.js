// Rails Unobtrusive JavaScript (handles non-GET requests in forms, links, etc.)
//= require rails-ujs

// Turbolinks speeds up navigation by using AJAX to load content
//= require turbolinks

// ActionCable for WebSocket communication
//= require actioncable

// Include specific JavaScript files
//= require servers
//= require game

// Include all other JavaScript files in the directory tree
//= require_tree .

console.log(">>> application.js loaded <<<");
document.addEventListener("turbolinks:load", () => {
    console.log(">>> turbolinks:load event fired <<<");
});
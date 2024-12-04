// Rails Unobtrusive JavaScript (handles non-GET requests in forms, links, etc.)
//= require rails-ujs

// Turbolinks speeds up navigation by using AJAX to load content
//= require turbolinks

// ActionCable for WebSocket communication
//= require actioncable

// Include specific JavaScript files
//= require welcome
//= require mystery_boxes
//= require shop
//= require servers
//= require chat_room
//= require game_logic

// Include all other JavaScript files in the directory tree
//= require_tree .


console.log(">>> application.js loaded <<<");
document.addEventListener("turbolinks:load", () => {
    console.log(">>> turbolinks:load event fired <<<");
});

document.addEventListener('DOMContentLoaded', function () {
    const tabs = document.querySelectorAll('.shop-tab');
    tabs.forEach(tab => {
        tab.addEventListener('click', function (event) {
            event.preventDefault();
            const targetId = this.getAttribute('href').substring(1);
            const targetSection = document.getElementById(targetId);
            if (targetSection) {
                targetSection.scrollIntoView({ behavior: 'smooth' });
            }
        });
    });
});

// Rails Unobtrusive JavaScript (handles non-GET requests in forms, links, etc.)
//= require rails-ujs

// Turbolinks speeds up navigation by using AJAX to load content
//= require turbolinks

// ActionCable for WebSocket communication
//= require actioncable
//= require ./channels/consumer
//= require ./channels/server_channel
//= require ./channels/game_logic_channel

// Include specific JavaScript files
//= require welcome
//= require mystery_boxes
//= require shop
//= require servers
//= require chat_room
//= require game_ui

// Include all other JavaScript files in the directory tree
//= require_tree .


console.log(">>> application.js loaded <<<");
document.addEventListener("turbolinks:load", () => {
    console.log(">>> turbolinks:load event fired <<<");
});

document.addEventListener('turbolinks:load', function () {
    var audio = document.getElementById('bg-audio');
    var toggleBtn = document.getElementById('toggle-music-btn');

    if (toggleBtn && audio) {
        toggleBtn.addEventListener('click', function () {
            if (audio.paused) {
                audio.play().then(() => {
                    toggleBtn.textContent = '🔇'; // Update to mute icon
                }).catch(err => {
                    console.error('Error playing audio:', err);
                });
            } else {
                audio.pause();
                toggleBtn.textContent = '♫'; // Update to play icon
            }
        });
    }
});

document.addEventListener('DOMContentLoaded', function () {
    const currentPath = window.location.pathname; // Get the current path
    const musicToggleContainer = document.querySelector('.music-toggle-container');

    // Define paths where the toggle button should not appear
    const excludedPaths = ['/servers']; // Add specific paths for exclusion

    if (excludedPaths.some(path => currentPath.startsWith(path)) && musicToggleContainer) {
        musicToggleContainer.remove(); // Dynamically remove the music toggle button
    }
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

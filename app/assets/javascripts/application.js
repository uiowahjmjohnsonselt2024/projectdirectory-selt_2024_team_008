//= require rails-ujs
// = require turbolinks
//= require actioncable
//= require servers
//= require_tree .
//= require mystery_boxes
//= require shop

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

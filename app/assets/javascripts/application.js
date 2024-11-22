//= require rails-ujs
//= require turbolinks
//= require actioncable
//= require servers
//= require_tree .
//= require multiplayer_sessions

console.log(">>> application.js loaded <<<");

document.addEventListener("turbolinks:load", () => {
    console.log(">>> turbolinks:load event fired <<<");
});
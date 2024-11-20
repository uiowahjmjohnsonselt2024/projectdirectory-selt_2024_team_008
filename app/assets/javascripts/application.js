//= require rails-ujs
//= require turbolinks
//= require_tree .
//= require shop


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

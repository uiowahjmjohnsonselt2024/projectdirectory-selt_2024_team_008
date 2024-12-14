document.addEventListener('turbolinks:load', () => {
    const images = [
        '<%= asset_path "scrolling_bg1.png" %>',
        '<%= asset_path "scrolling_bg2.png" %>',
        '<%= asset_path "scrolling_bg3.png" %>',
        '<%= asset_path "scrolling_bg4.png" %>',
        '<%= asset_path "scrolling_bg5.png" %>',
        '<%= asset_path "scrolling_bg6.png" %>',
    ];
    const bgContainer = document.querySelector('.background-container');
    let currentIndex = 0;

    setInterval(() => {
        currentIndex = (currentIndex + 1) % images.length;
        bgContainer.style.backgroundImage = `url(${images[currentIndex]})`;
    }, 6000); // Change image every 5 seconds
});

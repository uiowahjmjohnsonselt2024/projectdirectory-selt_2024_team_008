document.addEventListener("DOMContentLoaded", () => {
    const openCaseButton = document.getElementById("open-case-btn");
    const boxOpeningVideo = document.getElementById("box-opening-video");
    const itemReveal = document.getElementById("item-reveal");
    const itemName = document.getElementById("item-name");
    const itemImage = document.getElementById("item-image");

    const items = [
        { name: "Rare Item 1", image: "/assets/images/item1.png" },
        { name: "Rare Item 2", image: "/assets/images/item1.png" },
        { name: "Rare Item 3", image: "/assets/images/item1.png" },
        { name: "Rare Item 4", image: "/assets/images/item1.png" },
        { name: "Rare Item 5", image: "/assets/images/item1.png" },
        { name: "Rare Item 6", image: "/assets/images/item1.png" },
    ];

    openCaseButton.addEventListener("click", () => {
        // Hide the button
        openCaseButton.style.display = "none";

        // Show the video
        boxOpeningVideo.style.display = "block";
        boxOpeningVideo.play();

        // When the video ends, reveal the item
        boxOpeningVideo.addEventListener("ended", () => {
            const randomItem = items[Math.floor(Math.random() * items.length)];
            boxOpeningVideo.style.display = "none";

            // Update item reveal section
            itemName.textContent = randomItem.name;
            itemImage.src = randomItem.image;
            itemReveal.style.display = "block";
        });
    });
});

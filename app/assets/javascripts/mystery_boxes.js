document.addEventListener("DOMContentLoaded", () => {
    const openCaseButton = document.getElementById("open-case-btn");
    const boxImage = document.getElementById("box-image");
    const boxOpeningVideo = document.getElementById("box-opening-video");
    const itemReveal = document.getElementById("item-reveal");
    const itemName = document.getElementById("item-name");
    const itemImage = document.getElementById("item-image");

    const items = [
        { name: "Rare Item 1", image: "app/assets/images/item1.png" },
        { name: "Rare Item 2", image: "app/assets/images/item1.png" },
        { name: "Rare Item 3", image: "app/assets/images/item1.png" },
        { name: "Rare Item 4", image: "app/assets/images/item1.png" },
        { name: "Rare Item 5", image: "app/assets/images/item1.png" },
        { name: "Rare Item 6", image: "app/assets/images/item1.png" },
    ];

    openCaseButton.addEventListener("click", () => {
        // Hide the button
        openCaseButton.style.display = "none";

        // Show the video
        boxImage.style.display = "none";
        boxOpeningVideo.style.display = "block";
        boxOpeningVideo.play();


        // When the video ends, reveal the item
        boxOpeningVideo.addEventListener("ended", () => {
            const randomItem = items[Math.floor(Math.random() * items.length)];
            boxOpeningVideo.style.display = "none";

            // Update the image to show the revealed item
            boxImage.src = randomItem.image;
            boxImage.style.display = "block";

            // update the item name
            if (itemName) {
                itemName.textContent = randomItem.name;
            }

            // show a reveal section
            if (itemReveal) {
                itemImage.src = randomItem.image;
                itemReveal.style.display = "block";
            }

            // Bring back the open
            openCaseButton.style.display = "block";

        });
    });
});
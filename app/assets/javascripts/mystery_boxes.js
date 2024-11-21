document.addEventListener("DOMContentLoaded", () => {
    const openCaseButton = document.getElementById("open-case-btn");
    const boxImage = document.getElementById("box-image");
    const boxOpeningVideo = document.getElementById("box-opening-video");
    const itemReveal = document.getElementById("item-reveal");
    const itemName = document.getElementById("item-name");
    const itemImage = document.getElementById("item-image");
    const mysteryBoxCountElement = document.querySelector(".shard-balance-display p strong");

    const items = [
        { name: "Rare Item 1", image: "app/assets/images/item1.png" },
        { name: "Rare Item 2", image: "app/assets/images/item1.png" },
        { name: "Rare Item 3", image: "app/assets/images/item1.png" },
        { name: "Rare Item 4", image: "app/assets/images/item1.png" },
        { name: "Rare Item 5", image: "app/assets/images/item1.png" },
        { name: "Rare Item 6", image: "app/assets/images/item1.png" },
    ];

    openCaseButton.addEventListener("click", () => {
        // Disable the button to prevent multiple clicks
        openCaseButton.disabled = true;

        // Send a request to the server to open the mystery box
        fetch("/mystery_boxes/open_box", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content, // Include the CSRF token
            },
        })
            .then((response) => response.json())
            .then((data) => {
                if (data.success) {
                    // Update the mystery box count
                    if (mysteryBoxCountElement) {
                        mysteryBoxCountElement.textContent = data.remaining_boxes;
                    }

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

                        // Update the item name
                        if (itemName) {
                            itemName.textContent = randomItem.name;
                        }

                        // Show the item reveal section
                        if (itemReveal) {
                            itemImage.src = randomItem.image;
                            itemReveal.style.display = "block";
                        }

                        // Re-enable and show the button
                        openCaseButton.style.display = "block";
                        openCaseButton.disabled = false;
                    });
                } else {
                    // Handle the error (e.g., no boxes remaining)
                    alert(data.message);
                    openCaseButton.disabled = false;
                }
            })
            .catch((error) => {
                console.error("Error opening box:", error);
                openCaseButton.disabled = false;
            });
    });
});

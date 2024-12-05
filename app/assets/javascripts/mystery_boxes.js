document.addEventListener("DOMContentLoaded", () => {
    const openCaseButton = document.getElementById("open-case-btn");
    const boxOpeningVideo = document.getElementById("box-opening-video");
    const boxImage = document.getElementById("box-image");
    const itemReveal = document.getElementById("item-reveal");
    const itemName = document.getElementById("item-name");
    const mysteryBoxCount = document.getElementById("mystery-box-count");

    openCaseButton.addEventListener("click", () => {
        openCaseButton.style.display = "none";
        boxImage.style.display = "none";
        boxOpeningVideo.style.display = "block";
        boxOpeningVideo.play();

        fetch("/mystery_boxes/open_box", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').getAttribute("content")
            },
        })
            .then((response) => response.json())
            .then((data) => {
                if (data.success) {
                    itemReveal.style.display = "none";
                    // When the video ends, reveal the random item
                    boxOpeningVideo.onended = () => {
                        // Hide the video
                        boxOpeningVideo.style.display = "none";

                        // Update and display the item image and name
                        boxImage.src = data.item_image_url; // Assuming `item_image_url` is sent from the server
                        boxImage.style.display = "block";
                        itemName.textContent = `You got: ${data.item_name}`;
                        itemReveal.style.display = "block";

                        // Update mystery box count
                        if (mysteryBoxCount) {
                            mysteryBoxCount.textContent = data.remaining_boxes;
                        }

                        // Re-enable the button
                        openCaseButton.disabled = false;
                        openCaseButton.style.display = "block";
                    };
                } else {
                    // Handle cases where no mystery boxes are left
                    alert(data.message);
                    openCaseButton.disabled = false;
                    openCaseButton.style.display = "block";
                }
            })
            .catch((error) => {
                console.error("Error opening box:", error);
                openCaseButton.disabled = false;
                openCaseButton.style.display = "block";
            });
    });
});


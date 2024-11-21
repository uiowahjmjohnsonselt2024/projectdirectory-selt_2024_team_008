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
                    // When the video ends, reveal the random item
                    boxOpeningVideo.addEventListener("ended", () => {
                        boxOpeningVideo.style.display = "none";

                        if (itemName) {
                            itemName.textContent = `You got: ${data.item_name}`;
                            itemReveal.style.display = "block";
                        }

                        if (mysteryBoxCount) {
                            mysteryBoxCount.textContent = data.remaining_boxes;
                        }

                        openCaseButton.style.display = "block";
                    });
                } else {
                    // Handle cases where no mystery boxes are left
                    alert(data.message);
                    openCaseButton.style.display = "block";
                }
            })
            .catch((error) => {
                console.error("Error opening box:", error);
                openCaseButton.style.display = "block";
            });
    });
});


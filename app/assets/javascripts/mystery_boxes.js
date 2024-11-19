document.addEventListener("DOMContentLoaded", () => {
    const openCaseButton = document.getElementById("open-case-btn");
    const itemSlider = document.getElementById("item-slider");
    const items = document.querySelectorAll(".item");

    openCaseButton.addEventListener("click", () => {
        const totalItems = items.length;
        const randomIndex = Math.floor(Math.random() * totalItems); // Randomly select the final item
        const sliderWidth = itemSlider.scrollWidth;
        const containerWidth = document.getElementById("case-container").offsetWidth;
        const itemWidth = sliderWidth / totalItems;

        let cycles = 40; // Number of cycles before slowing down
        let currentIndex = 0;
        const animationDuration = 50000; // Total animation duration in milliseconds
        const intervalTime = animationDuration / (cycles * totalItems); // Time per cycle step

        itemSlider.style.transition = "none";
        itemSlider.style.transform = "translateX(0)";

        let cycleInterval = setInterval(() => {
            // Calculate the current position
            currentIndex = (currentIndex + 1) % totalItems;
            const offset = -(currentIndex * itemWidth);

            // Update the slider position
            itemSlider.style.transition = "transform 0.1s linear";
            itemSlider.style.transform = `translateX(${offset}px)`;

            cycles--;

            if (cycles <= 0) {
                clearInterval(cycleInterval);

                // After cycling, land on the selected item
                setTimeout(() => {
                    const finalOffset = -(randomIndex * itemWidth);
                    itemSlider.style.transition = "transform 1s ease-out";
                    itemSlider.style.transform = `translateX(${finalOffset}px)`;

                    alert(`You received: ${items[randomIndex].innerText}`); // Show the received item
                }, 500);
            }
        }, intervalTime);
    });
});


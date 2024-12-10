document.addEventListener("turbolinks:load", () => {
    console.log(">>> turbolinks:load event fired in game_ui.js <<<");

    const cells = document.querySelectorAll(".grid-cell");
    console.log("Number of grid cells:", cells.length);

    if (cells.length === 0) {
        console.warn("No .grid-cell elements found!");
        return;
    }

    cells.forEach(cell => {
        // Add new listeners without replacing the node
        cell.addEventListener("mouseover", () => {
            if (!cell.classList.contains("occupied")) {
                cell.style.backgroundColor = "#ccc"; // Temporary highlight
            }
        });

        cell.addEventListener("mouseout", () => {
            if (!cell.classList.contains("occupied")) {
                cell.style.backgroundColor = ""; // Restore background color set by game_logic_channel.js
            }
        });

        cell.addEventListener("click", () => {
            const x = cell.dataset.x;
            const y = cell.dataset.y;
            console.log(`Cell clicked at (${x}, ${y})`);
        });
    });
    const pauseMenu = document.getElementById("pauseMenu");
    const pauseMenuToggle = document.getElementById("pauseMenuToggle");
    const pauseMenuClose = document.getElementById("pauseMenuClose");

    if (pauseMenu && pauseMenuToggle && pauseMenuClose) {
        // Show pause menu and hide toggle button
        pauseMenuToggle.addEventListener("click", () => {
            pauseMenu.style.display = "block";
            pauseMenuToggle.style.display = "none";
        });

        // Hide pause menu and show toggle button
        pauseMenuClose.addEventListener("click", () => {
            pauseMenu.style.display = "none";
            pauseMenuToggle.style.display = "block";
        });

        // Close pause menu by clicking outside
        document.addEventListener("click", (event) => {
            const isClickInside = pauseMenu.contains(event.target) || pauseMenuToggle.contains(event.target);
            if (!isClickInside && pauseMenu.style.display === "block") {
                pauseMenu.style.display = "none";
                pauseMenuToggle.style.display = "block";
                console.log("Pause menu closed by clicking outside.");
            }
        });
    }
});
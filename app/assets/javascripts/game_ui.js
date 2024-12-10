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

        // cell.addEventListener("click", () => {
        //     const x = cell.dataset.x;
        //     const y = cell.dataset.y;
        //     console.log(`Cell clicked at (${x}, ${y})`);
        // });
    });
});
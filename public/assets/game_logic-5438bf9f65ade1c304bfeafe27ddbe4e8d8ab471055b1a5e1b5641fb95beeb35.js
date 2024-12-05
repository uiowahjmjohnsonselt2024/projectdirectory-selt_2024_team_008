document.addEventListener("turbolinks:load", () => {
    console.log(">>> turbolinks:load event fired in game_logic.js <<<");

    const cells = document.querySelectorAll(".grid-cell");
    console.log("Number of grid cells:", cells.length);

    if (cells.length === 0) {
        console.warn("No .grid-cell elements found!");
        return;
    }

    cells.forEach(cell => {
        // Remove any existing click listeners
        const newCell = cell.cloneNode(true);
        cell.parentNode.replaceChild(newCell, cell);

        // Add new listeners
        newCell.addEventListener("mouseover", () => {
            newCell.style.backgroundColor = "#ccc";
        });

        newCell.addEventListener("mouseout", () => {
            newCell.style.backgroundColor = "#f0f0f0";
        });

        newCell.addEventListener("click", () => {
            const x = newCell.dataset.x;
            const y = newCell.dataset.y;
            console.log(`Cell clicked at (${x}, ${y})`);
        });
    });
});

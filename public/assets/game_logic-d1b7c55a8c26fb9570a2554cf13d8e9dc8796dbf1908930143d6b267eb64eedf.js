document.addEventListener("turbolinks:load", () => {
    console.log(">>> turbolinks:load event fired <<<");

    const cells = document.querySelectorAll(".grid-cell");
    console.log("Number of grid cells:", cells.length);

    if (cells.length === 0) {
        console.warn("No .grid-cell elements found!");
        return;
    }

    cells.forEach(cell => {
        cell.addEventListener("mouseover", () => {
            cell.style.backgroundColor = "#ccc";
        });

        cell.addEventListener("mouseout", () => {
            cell.style.backgroundColor = "#f0f0f0";
        });

        cell.addEventListener("click", () => {
            const x = cell.dataset.x;
            const y = cell.dataset.y;
            console.log(`Cell clicked at (${x}, ${y})`);
        });
    });
});

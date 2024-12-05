document.addEventListener("turbo:load", () => {
    console.log("Turbo Drive status:", typeof Turbo !== "undefined" ? "Active" : "Inactive");
    console.log(">>> game_logic.js loaded <<<");

    const cells = document.querySelectorAll(".grid-cell");

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
            // Perform actions (e.g., send a move to the server)
        });
    });
});

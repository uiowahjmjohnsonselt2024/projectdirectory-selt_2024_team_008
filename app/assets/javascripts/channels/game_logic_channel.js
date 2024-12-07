// = require ./consumer
// = require actioncable

let gameLogicSubscription = null;

const initializeGameLogicChannel = () => {
    const gameElement = document.getElementById("server-id");
    if (!gameElement) return;

    const gameId = gameElement.dataset.serverId; // Assuming server ID maps to game ID
    const userId = gameElement.dataset.userId;

    // Subscribe to the GameLogicChannel
    gameLogicSubscription = consumer.subscriptions.create(
        { channel: "GameLogicChannel", game_id: gameId },
        {
            connected() {
                console.log(`Connected to GameLogicChannel for game ${gameId}`);
            },
            disconnected() {
                console.log(`Disconnected from GameLogicChannel`);
            },
            received(data) {
                // Update grid based on received data
                if (data.grid) {
                    updateGrid(data.grid);
                    console.log(`User ${data.user_id} moved at (${data.x}, ${data.y})`);
                } else if (data.error) {
                    alert(data.error); // Display error messages
                }
            },

            // Client-side method to make a move
            makeMove(x, y) {
                this.perform("make_move", { x: x, y: y, user_id: userId });
            },
        }
    );

    // Attach click listeners to grid cells
    document.querySelectorAll(".grid-cell").forEach((cell) => {
        cell.addEventListener("click", () => {
            const x = cell.dataset.x;
            const y = cell.dataset.y;
            gameLogicSubscription.makeMove(x, y);
        });
    });
};

// Update the grid dynamically
const updateGrid = (grid) => {
    document.querySelectorAll(".grid-cell").forEach((cell) => {
        const x = parseInt(cell.dataset.x, 10);
        const y = parseInt(cell.dataset.y, 10);
        const value = grid[y][x];

        if (value) {
            cell.innerHTML = `<span>${value}</span>`; // Example: Show user ID or marker
            cell.classList.add("occupied"); // Optional: Add a CSS class for styling
        } else {
            cell.innerHTML = "";
            cell.classList.remove("occupied");
        }
    });
};

document.addEventListener("turbolinks:load", initializeGameLogicChannel);
document.addEventListener("turbolinks:before-visit", () => {
    if (gameLogicSubscription) {
        gameLogicSubscription.unsubscribe();
        gameLogicSubscription = null;
    }
});
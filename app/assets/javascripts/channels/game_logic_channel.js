// = require ./consumer
// = require actioncable

let gameLogicSubscription = null;

const ensureGameMembership = async (gameId) => {
    const gameElement = document.getElementById("server-id");
    if (!gameElement) {
        console.error("Server element not found. Cannot ensure membership.");
        return;
    }

    try {
        const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
        const response = await fetch(`/games/${gameId}/ensure_membership.json`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-CSRF-Token": csrfToken,
            },
        });

        if (!response.ok) {
            throw new Error(`Failed to ensure game membership: ${response.statusText}`);
        }

        const data = await response.json();
        console.log("Game membership ensured:", data.message || data);
    } catch (error) {
        console.error("Error ensuring game membership:", error);
        alert("Unable to join the game. Please try again.");
        throw error; // Prevent further execution if membership fails
    }
};

const initializeGameLogicChannel = async () => {
    console.log('>>> Initializing game_logic_channel.js <<<')

    const gameElement = document.getElementById("game-element");
    if (!gameElement) {
        console.warn("Game element not found. Skipping GameLogicChannel initialization.");
        return;
    }

    const gameId = gameElement.dataset.gameId; // Assuming server ID maps to game ID
    const userId = gameElement.dataset.userId;

    try {
        // Ensure membership before subscribing
        await ensureGameMembership(gameId);

        // Subscribe to the GameLogicChannel
        gameLogicSubscription = App.cable.subscriptions.create(
            { channel: "GameLogicChannel", game_id: gameId },
            {
                connected() {
                    console.log(`Connected to GameLogicChannel for game ${gameId}`);
                },
                disconnected() {
                    console.log(`Disconnected from GameLogicChannel`);
                },
                received(data) {
                    // Handle received data
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
    } catch (error) {
        console.error("Failed to initialize GameLogicChannel:", error);
    }
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
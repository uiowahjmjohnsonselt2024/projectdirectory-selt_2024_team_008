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

    const gameId = gameElement.dataset.gameId;
    const userId = gameElement.dataset.userId;

    try {
        // Ensure membership before subscribing
        await ensureGameMembership(gameId);

        let visited = {}

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
                    if (data.grid && data.visited) {
                        visited = data.visited
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
const updateGrid = (grid = [], visited = {}) => {
    // Clear all grid cells
    document.querySelectorAll(".grid-cell").forEach((cell) => {
        cell.innerHTML = ""; // Clear content
        cell.classList.remove("occupied", "visited");
    });

    // Update the visited state
    grid.forEach((row, y) => {
        row?.forEach((value, x) => {
            if (value) {
                // Mark the tile as visited
                if (!visited[y]) visited[y] = {};
                visited[y][x] = value; // Track the player who visited this tile
            }
        });
    });

    // Apply the visited styling
    Object.keys(visited).forEach((y) => {
        Object.keys(visited[y]).forEach((x) => {
            const cell = document.querySelector(`.grid-cell[data-x='${x}'][data-y='${y}']`);
            if (cell) {
                cell.classList.add("visited"); // Apply visited styling
            }
        });
    });

    // Update the grid with the current player positions
    grid.forEach((row, y) => {
        row?.forEach((value, x) => {
            if (value) {
                const cell = document.querySelector(`.grid-cell[data-x='${x}'][data-y='${y}']`);
                if (cell) {
                    cell.innerHTML = `<span>${value}</span>`; // Display the player
                    cell.classList.add("occupied"); // Mark as occupied
                }
            }
        });
    });
};

document.addEventListener("turbolinks:load", initializeGameLogicChannel);
document.addEventListener("turbolinks:before-visit", () => {
    if (gameLogicSubscription) {
        gameLogicSubscription.unsubscribe();
        gameLogicSubscription = null;
    }
});
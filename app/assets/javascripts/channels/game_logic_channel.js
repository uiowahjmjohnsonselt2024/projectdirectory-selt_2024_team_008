// = require ./consumer
// = require actioncable

let gameLogicSubscription = null;
let lastPosition = { x: null, y: null };

const SHARD_COST_PER_TILE = 2;

const userColors = {};
const getUserColor = (userId) => {
    if (!userColors[userId]) {
        // Generate a unique pastel color for each user
        const hue = Math.floor(Math.random() * 360);
        userColors[userId] = `hsl(${hue}, 70%, 80%)`;
    }
    return userColors[userId];
};

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
    console.log('>>> Initializing GameLogicChannel <<<');

    const gameElement = document.getElementById("game-element");
    if (!gameElement) {
        console.warn("Game element not found. Skipping GameLogicChannel initialization.");
        return;
    }

    const gameId = gameElement.dataset.gameId;
    const userId = parseInt(gameElement.dataset.userId, 10);

    try {
        // Ensure membership before subscribing
        await ensureGameMembership(gameId);
        await fetchGameState(gameId);

        console.log("After ensure membership")

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
                    handleGameChannelEvent(data, userId, lastPosition);
                },

                makeMove(x, y) {
                    handleMove(x, y, lastPosition, userId, this);
                },
            }
        );

        // Attach click listeners to grid cells
        attachGridCellListeners(lastPosition);
    } catch (error) {
        console.error("Failed to initialize GameLogicChannel:", error);
    }
};

// Handle received data
const handleGameChannelEvent = (data, userId, lastPosition) => {
    console.log(`data.type: ${data.type}`);
    switch (data.type) {
        case "game_state":
            updateGrid(data.grid);
            break;
        case "tile_updates":
            // Update only the specific tile when a tile update is received
            if (data.updates) {
                data.updates.forEach(update => updateTile(update.x, update.y, update.username));
            }
            break;
        case "balance_update":
            if (data.user_id === userId) {
                updateShardBalance(data.balance);
            }
            break;
        case "balance_error":
            showFlashMessage(data.message, 'alert');
            triggerShardBalanceShake();
            break;
        case "error":
            showFlashMessage(data.message || "An error occurred.", 'alert');
            break;
        default:
            console.warn(`Unhandled data type: ${data.type}`);
    }
};

// Handle move logic
const handleMove = (x, y, lastPosition, userId, channel) => {
    const distance = calculateDistance(lastPosition, { x, y });

    if (distance === Infinity) {
        showFlashMessage("Invalid move! You can only move vertically or horizontally.", "alert");
        return;
    }

    const shardCost = calculateShardCost(distance);
    const currentShardBalance = parseInt(document.querySelector('.shard-balance-display p').textContent.match(/\d+/)[0], 10);

    if (distance > 1 && shardCost > currentShardBalance) {
        triggerShardBalanceShake();
        showFlashMessage("Insufficient shards to make this move!", "alert");
        return;
    }

    if (distance > 1) {
        const confirmMove = confirm(`Moving ${distance} tiles will cost ${shardCost} shards. Proceed?`);
        if (!confirmMove) return;
    }

    // Clear the previous position in the grid
    if (lastPosition.x !== null && lastPosition.y !== null) {
        updateTile(lastPosition.x, lastPosition.y, null); // Clear the previous tile
    }

    channel.perform("make_move", { x, y, user_id: userId });

    // Update the local last position
    lastPosition.x = x;
    lastPosition.y = y;
};

// Attach click listeners to grid cells
const attachGridCellListeners = (lastPosition) => {
    document.querySelectorAll(".grid-cell").forEach((cell) => {
        cell.addEventListener("click", () => {
            const x = parseInt(cell.dataset.x, 10);
            const y = parseInt(cell.dataset.y, 10);

            if (lastPosition.x === null || lastPosition.y === null) {
                lastPosition.x = x;
                lastPosition.y = y;
            }

            gameLogicSubscription.makeMove(x, y);
        });
    });
};

// Calculate distance between two positions
const calculateDistance = (from, to) => {
    if (from.x === null || from.y === null) return 0; // Initial move

    // Calculate Chebyshev distance
    const horizontalDistance = Math.abs(to.x - from.x);
    const verticalDistance = Math.abs(to.y - from.y);

    // Allow only horizontal or vertical moves
    if (horizontalDistance > 0 && verticalDistance > 0) {
        return Infinity; // Invalid move, return a high value
    }

    return Math.max(horizontalDistance, verticalDistance);
};

// Calculate shard cost for a move
const calculateShardCost = (distance) => {
    return (distance - 1) * SHARD_COST_PER_TILE;
}

// Update the shard balance display
const updateShardBalance = (newBalance) => {
    const balanceDisplay = document.querySelector('.shard-balance-display p');
    if (balanceDisplay) {
        balanceDisplay.textContent = `Shard Balance: ${newBalance} Shards`;
    }
};

// Update the grid dynamically
const updateGrid = (grid = [], visited = {}) => {
    // Clear all grid cells
    document.querySelectorAll(".grid-cell").forEach((cell) => {
        cell.innerHTML = ""; // Clear content
        cell.classList.remove("occupied");
        // cell.style.backgroundColor = "";
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
                const userId = visited[y][x];
                const color = getUserColor(userId);
                console.log(`Setting visited color for cell at (${x}, ${y}) to ${color}`);
                cell.style.backgroundColor = color; // Set visited colo
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
                    const color = getUserColor(value);
                    console.log(`Setting occupied color for cell at (${x}, ${y}) to ${color}`);
                    cell.style.backgroundColor = color; // Set player color
                }
            }
        });
    });
};

const updateTile = (x, y, username) => {
    // Find the target tile based on coordinates
    const cell = document.querySelector(`.grid-cell[data-x='${x}'][data-y='${y}']`);

    // Clear the tile if the username is empty (optional)
    if (!username && cell) {
        cell.innerHTML = "";
        cell.classList.remove("occupied");
        cell.style.backgroundColor = "";
        return;
    }

    // Update the tile with the user's username
    if (cell) {
        cell.innerHTML = `<span>${username}</span>`;
        cell.classList.add("occupied");
        const color = getUserColor(username);
        cell.style.backgroundColor = color;
    } else {
        console.warn(`Tile at (${x}, ${y}) not found.`);
    }
};

// Trigger the shake effect on shard balance display
const triggerShardBalanceShake = () => {
    const balanceDisplay = document.querySelector('.shard-balance-display');
    if (balanceDisplay) {
        balanceDisplay.classList.add('shake');
        setTimeout(() => {
            balanceDisplay.classList.remove('shake');
        }, 500); // Duration of the shake animation
    }
};

const showFlashMessage = (message, type = "alert") => {
    const flashContainer = document.getElementById("flash-messages");

    if (!flashContainer) {
        console.error("Flash container not found. Unable to display flash message.");
        return;
    }

    // Set z-index to bring the flash message forward
    flashContainer.style.zIndex = '1001';

    // Create the flash message element
    const flashMessage = document.createElement("div");
    flashMessage.className = type === "alert" ? "alert" : "notice";
    flashMessage.innerHTML = `
        ${message}
        <button onclick="this.parentElement.style.display='none';" aria-label="Close flash message">×</button>
    `;

    // Append the flash message to the container
    flashContainer.appendChild(flashMessage);

    // Automatically remove the flash message after 3 seconds
    setTimeout(() => {
        flashMessage.style.display = 'none';
        flashContainer.removeChild(flashMessage);
        flashContainer.style.zIndex = '-1';
    }, 3000);
};

const fetchGameState = async (gameId) => {
    try {
        const response = await fetch(`/games/${gameId}/game_state`);
        if (!response.ok) throw new Error(`Failed to fetch game state: ${response.statusText}`);

        const jsonData = await response.json();
        if (jsonData.grid && jsonData.user_position !== undefined) {
            console.log("Fetched game state:", jsonData.grid, jsonData.user_position);
            updateGrid(jsonData.grid); // Update the grid UI
            if (jsonData.user_position) {
                lastPosition.x = jsonData.user_position[0];
                lastPosition.y = jsonData.user_position[1];
            }
        } else {
            console.error("Unexpected response from game_state:", jsonData);
        }
    } catch (error) {
        console.error("Error fetching game state:", error);
    }
};

document.addEventListener("turbolinks:load", async () => {
    const gameElement = document.getElementById("game-element");
    if (gameElement) {
        const gameId = gameElement.dataset.gameId;
        // await fetchGameState(gameId); // Fetch the grid state on page load
        await initializeGameLogicChannel();
    }
});
document.addEventListener("turbolinks:before-visit", () => {
    if (gameLogicSubscription) {
        gameLogicSubscription.unsubscribe();
        gameLogicSubscription = null;
    }
});
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
            if (data.positions) {
                updateGrid(data.positions)
            }
            break;
        case "tile_updates":
            // Update only the specific tile when a tile update is received
            if (data.updates) {
                requestAnimationFrame(() => {
                    data.updates.forEach(update => updateTile(update.x, update.y, update.username, update.color));
                });
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

    // Check if the target cell is occupied
    const targetCell = document.querySelector(`.grid-cell[data-x='${x}'][data-y='${y}']`);
    if (targetCell && targetCell.classList.contains("occupied")) {
        showFlashMessage("Invalid move! The target cell is already occupied.", "alert");
        return;
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

const updateGrid = (positions) => {
    positions.forEach(pos => {
        updateTile(pos.x, pos.y, pos.username, pos.color);
    });
};

const updateTile = (x, y, username, color) => {
    console.log(`updateTile data: x:${x}, y:${y}, username:${username}, color:${color} `)
    // Find the target tile based on coordinates
    const cell = document.querySelector(`.grid-cell[data-x='${x}'][data-y='${y}']`);

    // Clear the tile if the username is empty (optional)
    if (cell) {
        if (!username) {
            // Clear the tile
            cell.innerHTML = "";
            // cell.classList.remove("occupied");
            cell.className = "grid-cell"; // Reset to default
            return;
        }

        // Update the tile with the user's username and color class
        cell.innerHTML = `<span>${username}</span>`;
        cell.className = `grid-cell ${color} occupied`;
        console.log(`Updated tile at (${x}, ${y}) with username=${username}, color=${color}`);
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
        if (jsonData.positions) {
            console.log("Fetched game state:", jsonData.positions);

            // updateGrid(jsonData.grid); // Update the grid UI

            // Update the grid with all positions
            jsonData.positions.forEach(pos => updateTile(pos.x, pos.y, pos.username, pos.color));

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
        await fetchGameState(gameId); // Fetch the grid state on page load
        await initializeGameLogicChannel();
    }
});
document.addEventListener("turbolinks:before-visit", () => {
    if (gameLogicSubscription) {
        gameLogicSubscription.unsubscribe();
        gameLogicSubscription = null;
    }
});
// = require ./consumer
// = require actioncable

let gameLogicSubscription = null;
let lastPosition = { x: null, y: null };

const SHARD_COST_PER_TILE = 2;

const userColors = {};
const tileColorMapping = {
    "tile-color-1": "#f28b82", // Light red
    "tile-color-2": "#fbbc04", // Light orange
    "tile-color-3": "#fff475", // Light yellow
    "tile-color-4": "#ccff90", // Light green
    "tile-color-5": "#a7ffeb", // Light cyan
    "tile-color-6": "#cbf0f8", // Light blue
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
    const username = gameElement.dataset.username

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
                    handleMove(x, y, lastPosition, userId, this, username);
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
            // Update only the specific tiles when a tile update is received
            if (data.updates) {
                requestAnimationFrame(() => {
                    data.updates.forEach(update => {
                        updateTile(
                            update.x,
                            update.y,
                            update.username,
                            update.color,
                            update.owner,
                            update.occupant_avatar
                        );
                    });
                    refreshGridCellListeners();
                });
            }
            break;

        case "tile_action":
            handleTileAction(data);
            break;
        case "enter_tic_tac_toe":
            const gameElement = document.getElementById("game-element");
            if (gameElement) {
                const gameId = gameElement.dataset.gameId;
                window.location.href = `/games/${gameId}/tic_tac_toe`;
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

        case "move_error":
            showFlashMessage(data.message || "Invalid move.", "alert");
            break;

        case "error":
            showFlashMessage(data.message || "An error occurred.", 'alert');
            break;

        default:
            console.warn(`Unhandled data type: ${data.type}`);
    }
};

// Handle move logic
const handleMove = (x, y, lastPosition, userId, channel, username) => {
    let distance = calculateDistance(lastPosition, { x, y });

    // Prevent duplicate confirmations for the same tile.
    const activeTiles = document.querySelectorAll('.grid-cell.confirming');
    const isAlreadyConfirming = Array.from(activeTiles).some(
        (tile) => parseInt(tile.dataset.x, 10) === x && parseInt(tile.dataset.y, 10) === y
    );

    if (isAlreadyConfirming) {
        console.log("Action already in progress for this tile.");
        return; // Exit to prevent duplicate interactions.
    }

    // Add 'confirming' class to target tile temporarily.
    const targetCell = document.querySelector(`.grid-cell[data-x='${x}'][data-y='${y}']`);
    if (targetCell) {
        targetCell.classList.add('confirming');
        setTimeout(() => targetCell.classList.remove('confirming'), 5000); // 5-sec safety period.
    }

    if (lastPosition.x === x && lastPosition.y === y) {
        console.log("User clicked on their current tile.");

        // Trigger a tile action
        channel.perform("make_move", { x, y, user_id: userId });
        return;
    }

    if (distance === Infinity) {
        showFlashMessage("Invalid move! You can only move vertically or horizontally.", "alert");
        return;
    }

    let shardCost = calculateShardCost(distance);
    const currentShardBalance = parseInt(document.querySelector('.shard-balance-display p').textContent.match(/\d+/)[0], 10);

    if (shardCost > currentShardBalance) {
        triggerShardBalanceShake();
        showFlashMessage("Insufficient shards to make this move!", "alert");
        return;
    }

    // Confirmation handling for unowned tile:
    if (targetCell && !targetCell.classList.contains(("owned"))) {
        const confirmOwnership = confirm(
            `This tile is unowned. Claiming it will cost ${shardCost} shards. Do you want to proceed?`
        );

        if (!confirmOwnership) return;

        // Proceed with move.
        channel.perform("make_move", { x, y, user_id: userId });
        lastPosition.x = x; // Update last position
        lastPosition.y = y;
        return;
    }

    // Handle movement to owned tiles
    if (targetCell && targetCell.classList.contains("owned")) {
        const owner = targetCell.dataset.owner;
        if (owner === username) {
            console.log(`Distance: ${distance}`);

            distance -= 1;
            shardCost -= 2;

            const confirmMove = confirm(`Moving ${distance} tiles will cost ${shardCost} shards. Proceed?`);
            if (!confirmMove) return;


            channel.perform("make_move", {x, y, user_id: userId});
            lastPosition.x = x; // Update last position
            lastPosition.y = y;
            return;
        }
        // Tile is owned by someone else, show an error message.
        showFlashMessage("Invalid move! You can only move to tiles you own.", "alert");
    }
};

// Handle entering a tile
const handleTileAction = (data) => {
    const { x, y, message } = data;

    // Display message or update UI for the tile
    const tile = document.querySelector(`.grid-cell[data-x='${x}'][data-y='${y}']`);
    if (tile) {
        tile.classList.add("active-tile");

        // Optionally remove the "active-tile" class after some time
        setTimeout(() => {
            tile.classList.remove("active-tile");
        }, 3000);
    }
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

    return Math.max(horizontalDistance, verticalDistance) + 1;
};

// Calculate shard cost for a move
const calculateShardCost = (distance) => {
    // Ensure the cost is at least the value of SHARD_COST_PER_TILE
    return Math.max(1, distance) * SHARD_COST_PER_TILE;
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
        updateTile(pos.x, pos.y, pos.username, pos.color, pos.owner, pos.occupant_avatar);
    });
};

const updateTile = (x, y, username, color, owner, occupantAvatar) => {
    console.log(`updateTile data: x:${x}, y:${y}, username:${username}, color:${color}, owner:${owner}, avatar:${occupantAvatar ? 'present' : 'none'}`);

    // Find the target tile based on coordinates
    const cell = document.querySelector(`.grid-cell[data-x='${x}'][data-y='${y}']`);

    if (cell) {
        if (!username && !owner) {
            cell.className = "grid-cell"; // Reset to default
            cell.removeAttribute("data-owner");
            cell.innerHTML = "";
            cell.style.borderColor = "";
            return;
        }
        if (username) {
            cell.className = `grid-cell occupied`;
            cell.style.borderColor = "";

            let avatarElement = cell.querySelector(".tile-avatar");
            if (!avatarElement) {
                avatarElement = document.createElement("img");
                avatarElement.className = "tile-avatar";
                cell.appendChild(avatarElement);
            }

            if (occupantAvatar) {
                avatarElement.src = occupantAvatar.startsWith('/assets')
                    ? `${window.location.origin}${occupantAvatar}`
                    : occupantAvatar;
            } else {
                avatarElement.src = "/assets/defaultAvatar.png";
            }
        } else {
            const avatarElement = cell.querySelector(".tile-avatar");
            if (avatarElement) {
                avatarElement.remove();
            }
            cell.innerHTML = "";
            cell.classList.remove("occupied");
        }

        if (owner) {
        cell.classList.add("owned");
        cell.dataset.owner = owner;
        cell.style.borderColor = tileColorMapping[color];
        }
    }
    console.log(`Updated tile at (${x}, ${y}) with username=${username}, color=${color}, owner=${owner}`);
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

            // Update the grid with all positions
            jsonData.positions.forEach(pos =>
                updateTile(pos.x, pos.y, pos.username, pos.color, pos.owner)
            );
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
        if (!gameLogicSubscription) await initializeGameLogicChannel();
    }
});

document.addEventListener("turbolinks:before-visit", () => {
    if (gameLogicSubscription) {
        gameLogicSubscription.unsubscribe();
        gameLogicSubscription = null;
    }
});

const refreshGridCellListeners = () => {
    document.querySelectorAll(".grid-cell").forEach((cell) => {
        cell.addEventListener("click", () => {
            const x = parseInt(cell.dataset.x, 10);
            const y = parseInt(cell.dataset.y, 10);
            gameLogicSubscription.makeMove(x, y);
        });
    });
};
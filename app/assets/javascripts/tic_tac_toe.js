// Handles all client clicks with event listeners
document.addEventListener("DOMContentLoaded", () => {
    const boardContainer = document.querySelector(".board");
    const turns = { X: "O", O: "X" };
    let currentTurn = "X";
    let board = Array(9).fill(null);
    const messageDisplay = document.querySelector(".game-message");
    const shardBalanceDisplay = document.querySelector(".shard-balance-display p");
    // Handling cell(and individual square) clicks by user
    boardContainer.addEventListener("click", () => {
        const cell = event.target;
        if (cell.classList.contains("cell") && !cell.textContent) {
            const cellIndex = cell.dataset.index;
            cell.textContent = currentTurn;
            board[cellIndex] = currentTurn;

            // Send move to the server
            fetch("/tic_tac_toe/play", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').getAttribute("content"),
                },
                body: JSON.stringify({
                    move: cellIndex,
                    board: board,
                    current_turn: currentTurn,
                }),

            })
                .then((response) => response.json())
                .then((data) => {
                    board = data.board; // Update board with server data

                    // Check the game status
                    if (data.status !== "continue") {
                        // Display the result message
                        messageDisplay.textContent = data.message;

                        // Update shard balance
                        shardBalanceDisplay.textContent = `Shard Balance: ${data.new_shard_balance} Shards`;

                        // Disable further moves
                        boardContainer.style.pointerEvents = "none";


                    }
                    else {
                        currentTurn = turns[currentTurn];
                    }
                })
                .catch((error) => {
                    console.error("Error:", error);
                    messageDisplay.textContent = "An error occurred. Please try again.";
                });
        }
    })
});

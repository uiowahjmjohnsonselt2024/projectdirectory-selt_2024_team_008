document.addEventListener("DOMContentLoaded", () => {
    const boardContainer = document.querySelector(".board");
    const turns = { X: "O", O: "X" };
    let currentTurn = "X";
    let board = Array(9).fill(null);
    const messageDisplay = document.querySelector(".game-message");
    const shardBalanceDisplay = document.querySelector(".shard-balance-display p");

    boardContainer.addEventListener("click", (event) => {
        const cell = event.target;

        if (!cell.classList.contains("cell") || cell.textContent) {
            return;
        }

        const cellIndex = parseInt(cell.dataset.index, 10);

        fetch("/games/$(gameId}/tic_tac_toe/play", {
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
                if(data.error) {
                    console.error("Server error: ", data.error);
                    messageDisplay.textContent = "A server error occurred. Please Try again";
                    return;
                }
                // Update the entire board
                data.board.forEach((mark, index) => {
                    const cell = document.querySelector(`.cell[data-index="${index}"]`);
                    if (mark) {
                        cell.textContent = mark;
                        cell.classList.add(mark.toLowerCase());
                    }
                    board[index] = mark;
                });

                // Check game status
                if (data.status !== "continue") {
                    messageDisplay.textContent = data.message;
                    shardBalanceDisplay.textContent = `Shard Balance: ${data.new_shard_balance} Shards`;
                    boardContainer.classList.add("disabled");
                } else {
                    currentTurn = turns[currentTurn];
                }
            })
            .catch((error) => {
                console.error("Error:", error);
                messageDisplay.textContent = "An error occurred. Please try again.";
            });
    });
});
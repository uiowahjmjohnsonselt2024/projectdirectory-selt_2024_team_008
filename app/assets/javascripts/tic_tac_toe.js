let eventListenersAttached = false;

document.addEventListener("turbolinks:load", () => {
    if (eventListenersAttached) return; // Prevent re-attaching

    const boardContainer = document.querySelector(".board");
    let currentTurn = "X";
    let board = Array(9).fill("");

    const messageDisplay = document.querySelector(".game-message");
    const shardBalanceDisplay = document.querySelector(".shard-balance-display p");

    boardContainer.addEventListener("click", (event) => {
        const cell = event.target;
        if (!cell.classList.contains("cell") || cell.textContent) return;

        const cellIndex = parseInt(cell.dataset.index, 10);
        console.log(`User clicked cellIndex=${cellIndex}, board before move:`, board);

        fetch(`/games/${gameId}/tic_tac_toe/play`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').getAttribute("content"),
            },
            body: JSON.stringify({
                move: cellIndex,
                'board[]': board,
                current_turn: currentTurn,
            }),
        })
            .then(response => response.json())
            .then((data) => {
                console.log("Server response:", data);
                if (data.error) {
                    console.error("Server error:", data.error);
                    messageDisplay.textContent = "A server error occurred. Please try again.";
                    return;
                }

                data.board.forEach((mark, index) => {
                    const cellElement = document.querySelector(`.cell[data-index="${index}"]`);
                    if (mark) {
                        cellElement.textContent = mark;
                        cellElement.className = 'cell ' + mark.toLowerCase();
                    } else {
                        cellElement.textContent = '';
                        cellElement.className = 'cell';
                    }
                    board[index] = mark || "";
                });

                if (data.status !== "continue") {
                    messageDisplay.textContent = data.message;
                    shardBalanceDisplay.textContent = `Shard Balance: ${data.new_shard_balance} Shards`;
                    boardContainer.classList.add("disabled");
                }
            })
            .catch((error) => {
                console.error("Error:", error);
                messageDisplay.textContent = "An error occurred. Please try again.";
            });
    });

    eventListenersAttached = true;
});
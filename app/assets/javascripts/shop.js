document.addEventListener("turbolinks:load", () => {
    const form = document.getElementById("shard-form");

    if (form) {
        form.addEventListener("ajax:success", (event) => {
            const [data, _status, _xhr] = event.detail;
            const calculatedCostElement = document.getElementById("calculated-cost");
            calculatedCostElement.textContent = `Cost: ${data.amount} ${data.currency}`;
        });

        form.addEventListener("ajax:error", () => {
            const calculatedCostElement = document.getElementById("calculated-cost");
            calculatedCostElement.textContent = "Error calculating cost. Please try again.";
        });
    }
});

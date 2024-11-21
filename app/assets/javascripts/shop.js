document.addEventListener('turbolinks:load', () => {
    const convertButton = document.getElementById('convert-button');
    const buyButton = document.getElementById('buy-button');

    if (convertButton) {
        convertButton.addEventListener('click', () => {
            const amount = document.getElementById('shard-amount').value;
            const currency = document.getElementById('currency-selector').value;

            fetch('/shard_accounts/convert_currency', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': document.head.querySelector('meta[name="csrf-token"]').content
                },
                body: JSON.stringify({ amount: amount, currency: currency })
            })
                .then(response => response.json())
                .then(data => {
                    document.getElementById('conversion-result').textContent = `Converted Amount: ${data.converted_amount} ${currency}`;
                });
        });
    }

    if (buyButton) {
        buyButton.addEventListener('click', () => {
            const amount = document.getElementById('shard-amount').value;
            const currency = document.getElementById('currency-selector').value;
            const conversionText = document.getElementById('conversion-result').textContent;

            if (amount && conversionText) {
                if (confirm(`Are you sure you want to buy ${amount} Shards for ${conversionText.split(': ')[1]}?`)) {
                    // Trigger purchase logic here
                    alert('Purchase successful!');
                }
            } else {
                alert('Please enter a valid amount and perform the conversion first.');
            }
        });
    }
});

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
                    if (data.converted_amount) {
                        document.getElementById('conversion-result').textContent = `Converted Amount: ${data.converted_amount} ${currency}`;
                    } else {
                        alert(data.error || 'Error converting shards.');
                    }
                })
                .catch(error => {
                    console.error('Error during conversion:', error);
                    alert('An unexpected error occurred.');
                });
        });
    }

    if (buyButton) {
        buyButton.addEventListener('click', () => {
            const amount = document.getElementById('shard-amount').value;
            const conversionText = document.getElementById('conversion-result').textContent;

            if (amount && conversionText) {
                const priceText = conversionText.split(': ')[1];

                if (confirm(`Are you sure you want to buy ${amount} Shards for ${priceText}?`)) {
                    fetch('/shard_accounts/add_funds', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                            'X-CSRF-Token': document.head.querySelector('meta[name="csrf-token"]').content,
                            'X-Requested-With': 'XMLHttpRequest' // Explicitly mark as AJAX
                        },
                        body: JSON.stringify({ amount: amount, currency: 'USD' })
                    })
                        .then(response => {
                            if (!response.ok) {
                                throw new Error('Network response was not ok');
                            }
                            return response.json();
                        })
                        .then(data => {
                            if (data.success) {
                                alert(`Successfully purchased ${amount} Shards!`);
                                const balanceDisplay = document.querySelector('.shard-balance-display');
                                if (balanceDisplay) {
                                    balanceDisplay.textContent = `Shard Balance: ${data.new_balance} Shards`;
                                }
                            } else {
                                alert(data.error || 'Error completing purchase.');
                            }
                        })
                        .catch(error => {
                            console.error('Error during purchase:', error);
                            alert('An unexpected error occurred during the purchase.');
                        });

                }
            } else {
                alert('Please enter a valid amount and perform the conversion first.');
            }
        });
    }
});

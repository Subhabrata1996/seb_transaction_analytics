SELECT account_id, COUNT(transaction_id) AS number_of_transactions
FROM ${TABLE_NAME}
GROUP BY account_id
ORDER BY COUNT(transaction_id) DESC
LIMIT 5

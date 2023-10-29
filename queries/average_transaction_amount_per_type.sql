SELECT transaction_type, AVG(amount) AS average_amount
FROM ${TABLE_NAME}
GROUP BY transaction_type

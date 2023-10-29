SELECT account_id, balance
FROM ${TABLE_NAME}
QUALIFY ROW_NUMBER() OVER (PARTITION BY account_id ORDER BY transaction_date DESC) = 1
ORDER BY balance DESC
LIMIT 10

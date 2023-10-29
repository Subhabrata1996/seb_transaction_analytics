# Analytics SQL queries

### What are the top ten accounts with the highest balances?

Using window function we get the latest balance for each account and then sort it in descending order of the latest balance.

`QUALIFY ROW_NUMBER() OVER (PARTITION BY account_id ORDER BY transaction_date DESC) = 1`
`LIMIT 10`


restricts the result to 10 records

QUALIFY command enables us to do this in a single query rather than using a CTE or subquery.

### What is the average transaction amount by type (deposit, withdrawal, transfer)?

Simple aggregation function of `AVG()` enables us to do this analysis, grouping by transaction_type

### Who are the top five customers with the most transactions?

Simple aggregation function `COUNT()` enables us to do this, grouping by account_id. `LIMIT` enables us to retrict records to 5 rows.


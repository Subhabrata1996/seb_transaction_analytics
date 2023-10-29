# Python transformation
The usecase requires to have a python transformation on the raw csv file.

As this script needs to run in GCP, we have chosen cloud functions to host and run this script. the script entry point is the function "transform_load_csv_file". This function is triggered using an HTTP POST event.


The input parameters required for this function is configured as ENVIRONMENT_VARIABLE in terraform, another option would have been to send it inside the request body

transform_load_csv_file : reads the CSV file from GCS bucket into a dataframe and performs the cleansing and transformation of the dataframe

    `replace_error_transactions_with_zero` : replace nulls or error amount columns to 0. casts the amount column to numeric and also creates a subset of failed rows to be stored in error table.
    
    `format_datetime` : cast the transaction_date column to datetime and also creates a subset of failed rows to be stored in error table.
    
    `calculate_current_balance` : calculates the balance after each transaction of each account. uses pandas cumsum() function to get the cumulative sum

## Unit-tests
We have used `pytest` to write unit tests for our function. to run the test use the below command

```bash
pip install -r requirements.txt
```

```bash
python main_test.py
```
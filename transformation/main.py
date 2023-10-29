from cloudevents.http import CloudEvent
import functions_framework
from google.cloud import storage
from google.cloud import bigquery
import pandas as pd
import os

def replace_error_transactions_with_zero(input_df: pd.DataFrame,
                                        column_name: str):
    """ This function cleans a numeric column and gets the rows
        that failed in conversion

    Args:
        input_df: Input dataframe
        column_name: name of the numeric column in the dataframe

    Returns:
        result_df: cleaned dataframe that have been successfully converted
            to numeric
        error_df: dataframe with error records that were not able to clean
    """
    # Replace "error" string in amount with "0".
    # Remove this line if assumption is incorrect
    input_df[column_name] = input_df[column_name].str.replace("error", "0")
    # Replace nulls with 0
    input_df[column_name].fillna("0", inplace=True)
    # Try to cast the amount column to numeric, errors="coerce"
    # enables us to capture failed casting attemps as null 
    input_df[column_name] = pd.to_numeric(input_df[column_name],
                                          errors="coerce")
    # Return two dataframes - one that is successfully cased to numeric
    # Other the error rows that we were not able to cast
    return input_df[input_df[column_name].notnull()],\
    input_df[input_df[column_name].isnull()]

def format_datetime(input_df: pd.DataFrame, column_name: str):
    """ This function cleans a date column and gets the rows
        that failed in conversion

    Args:
        input_df: Input dataframe
        column_name: name of the datetime column in the dataframe

    Returns:
        result_df: cleaned dataframe that have been successfully converted
            to datetime
        error_df: dataframe with error records that were not able to clean
    """
    # Try to cast the transaction_date column to numeric, errors="coerce"
    # enables us to capture failed casting attemps as nulls
    input_df[column_name] = pd.to_datetime(input_df[column_name],
                                           errors="coerce")
    # Return two dataframes - one that is successfully cased to datetime
    # Other the error rows that we were not able to cast
    return input_df[input_df[column_name].notnull()],\
    input_df[input_df[column_name].isnull()]

def calculate_current_balance(input_df: pd.DataFrame, account_column: str,
                             transaction_date_column: str, amount_column: str):
    """ This function calculates the balance after each
        transaction for an account.

    Args:
        input_df: Input dataframe
        account_column: name of the column in the dataframe
            that contains account identifier
        transaction_date_column: name of the column that holds
            the transaction date
        amount_column: name of the column that contains amount for
            each transaction

    Returns:
        result_df: dataframe with new calculated column "balance"
    """
    # We are using cumsum() method of aggregation that sums up all the numbers
    # before the current row. In order for this to work we first sort the dataframe
    # by transaction time. This logic works because debits are captured as negetive.
    input_df.sort_values(by=[account_column, transaction_date_column], inplace=True)
    input_df["balance"] = input_df.groupby(account_column)[amount_column].cumsum()
    return input_df

@functions_framework.http
def transform_load_csv_file(request):
    """This function is triggered by an HTTP post event.

    Args:
        request: The request body for the POST request
    
    Returns:
        response: string response for completion
    """
    client = storage.Client()
    # Extract the environment variables set by terraform for the GCS location
    bucket = os.environ.get("CSV_GCS_BUCKET")
    name = os.environ.get("CSV_FILE_NAME")
    # Load csv data to pandas dataframe
    transcation_df = pd.read_csv(f"gs://{bucket}/{name}")
    # Cleanse the amount column for error rows and nulls
    transcation_df, amount_error_df = replace_error_transactions_with_zero(
        transcation_df, "amount")
    # Format transaction_date column as datetime
    # capture the error rows into *_error_df
    transcation_df, dateformat_error_df = format_datetime(
        transcation_df, "transaction_date")
    transcation_df = calculate_current_balance(transcation_df,
                                               "account_id",
                                               "transaction_date",
                                               "amount")

    bq_client = bigquery.Client()
    # Extract the environment variables set by terraform for Bigquery
    dataset_id = os.environ.get("BIGQUERY_DATASET_ID")
    table_id = os.environ.get("BIGQUERY_TABLE_NAME")
    error_table_id = os.environ.get("BIGQUERY_ERROR_TABLE_NAME")
    
    # Bigquery load configurations. WRITE_TRUNCATE clears the table every run
    # and inserts the records. for incremental strategy use WRITE_APPEND
    job_config = bigquery.LoadJobConfig()
    job_config.write_disposition = "WRITE_TRUNCATE"
    job_config.autodetect = True

    table_ref = bq_client.dataset(dataset_id).table(table_id)
    # Load transformed data to bigquery
    job = bq_client.load_table_from_dataframe(transcation_df, table_ref,
                                              job_config=job_config)
    job.result()

    print("Data loaded into BigQuery successfully.")

    if len(pd.concat([amount_error_df, dateformat_error_df]).index) > 0:
        # Load the error records in the error table
        table_ref = bq_client.dataset(dataset_id).table(error_table_id)
        job = bq_client.load_table_from_dataframe(
            pd.concat([amount_error_df, dateformat_error_df]), table_ref,
            job_config=job_config)
        job.result()

        print("error records loaded into BigQuery successfully.")
    else:
        print("All rows processed successfully.")

    return "Transformation and Load completed."
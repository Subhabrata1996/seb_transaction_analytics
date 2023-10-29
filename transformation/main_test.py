
import numpy as np
import pandas as pd
import pytest

import main

def test_replace_error_transactions_with_zero():
    # Sample test data
    sample_data = {
        'transaction_id': [1, 2, 3, 4, 5, 6],
        'amount': ['100.21', 'error', '-50', 'error', '75.2', 'null']
    }

    sample_df = pd.DataFrame(sample_data)
    # Test the function with the sample DataFrame
    result_df, error_df = main.replace_error_transactions_with_zero(sample_df, 'amount')

    # Check if 'error' values were replaced with '0'
    assert result_df['amount'].tolist() == [100.21, 0, -50, 0, 75.2]

    # Check if the 'error' rows are in the error_df
    assert all(np.isnan(value) for value in error_df['amount'].tolist())

    # Check if the 'error' values were coerced to numeric
    assert all(result_df['amount'].apply(lambda x: isinstance(x, (int, float))))

def test_format_datetime():
    sample_data = {
        'datetime_str': ['2023-01-15 10:30:00', 'error', '2023-02-20', '2023-03-25 20:00:00'],
    }

    sample_df = pd.DataFrame(sample_data)

    # Test the function with the sample DataFrame
    result_df, error_df = main.format_datetime(sample_df, 'datetime_str')

    # Check if the datetime strings were successfully converted to datetime objects
    assert all(isinstance(value, pd.Timestamp) for value in result_df['datetime_str'])

    # Check if the 'error' values are correctly separated into the error DataFrame
    assert all(np.isnat(value) for value in error_df['datetime_str'].values)

def test_calculate_current_balance():
    # Create a sample DataFrame
    data = {
        'account_id': [1, 1, 2, 2, 3, 3],
        'transaction_date': ['2023-01-01', '2023-01-02', '2023-01-01', '2023-01-02', '2023-01-01', '2023-01-02'],
        'amount': [100, 50, 200, 75, 300, 100],
    }
    sample_df = pd.DataFrame(data)

    # Calculate the current balance using the function
    result_df = main.calculate_current_balance(sample_df, 'account_id', 'transaction_date', 'amount')

    # Check if the 'balance' column is correctly calculated
    expected_balances = [100, 150, 200, 275, 300, 400]
    assert result_df['balance'].tolist() == expected_balances

if __name__ == '__main__':
    pytest.main()
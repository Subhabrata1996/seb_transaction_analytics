project             = "seb-test-exercise"
bucket_name         = "seb-test-exercise-transaction-bucket"
location            = "europe-west1"
csv_file_name       = "fake_dataset.csv"
csv_file_path       = "../data/fake_dataset.csv"
dataset_id          = "seb_transaction_analytics"
result_table_name   = "transactions"
error_table_name    = "error_records"
schema              = <<EOF
    [
      {
        "name": "transaction_id",
        "type": "STRING"
      },
      {
        "name": "account_id",
        "type": "INTEGER"
      },
      {
        "name": "transaction_type",
        "type": "STRING"
      },
      {
        "name": "amount",
        "type": "FLOAT"
      },
      {
        "name": "transaction_date",
        "type": "DATETIME"
      },
      {
        "name": "balance",
        "type": "FLOAT"
      }
    ]
  EOF
entry_point         = "transform_load_csv_file"
alert_email_address = "subhabrataiam@gmail.com"
path_to_queries     = "../queries/"
cron_schedule       = "* 9 * * *"
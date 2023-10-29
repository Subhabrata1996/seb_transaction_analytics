# GCP Infrastructure
We use terraform to provision and maintain our infrastructure. All the parameters in the terraform configuration can be altered and updated using the `vars.auto.tfvars` file. Each variable in the file will be explained in later section.

## Components


Below are the components we provision using terraform

### GCS Bucket

GCS bucket is created using terraform and serves two purposes :
1. Stores the raw CSV file that contains our data
2. Stores the python source code for cloud function in zip format

We upload the CSV file using "google_storage_bucket_object" resource. For the source code, we use the "archive_file" datasource to compress and create a local .zip file and then upload it using "google_storage_bucket_object". The local zip file is created in the planning stage of terraform.

### Bigquery

We create a dataset in bigquery using "google_bigquery_dataset" resource. Following that we create two tables and three views :

#### tables
  1. transaction : stores the transformed data from the CSV file using cloud function. This table also has an additional column - `balance`
  2. error_record : stores the error records that were not properly processed by the cloud function script.

#### views
  Based on the .sql files in the `queries` folder we create views for each file. we use `for_each` to itterate through each files and name the view same as the file name. We also use `templatefile` to replace the [TABLE_NAME] parameter with the table_id created by terraform.
  1. accounts_with_highest_balance
  2. average_transaction_amount_per_type
  3. top_customers_with_most_transactions

### Service Account

We have to create a service account with "roles/cloudfunctions.invoker" role to enable cloud scheduler to invoke the cloud function.
We use "google_service_account" resource to create the SA and "google_project_iam_member" to bind the proper role to the SA.

### Cloud function

The cloud function is provisioned using terraform "google_cloudfunctions_function" resource, it uses the zip file source code we previously uploaded to GCS bucket. The cloud function uses environment variable to get the correct GCS path to the csv file and bigquery table.

### Cloud scheduler

We also provision a cloud scheduler using terraform resource "google_cloud_scheduler_job". This is an HTTP POST job that triggers the cloud function. This scheduler uses the SA we created previously. CRON expression used by this scheduler is configurable.

### Monitoring

We create an email alerting channel using terraform resource "google_monitoring_notification_channel". the address configured for alerts can be entered in the `vars.auto.tfvars`.

Once channel is created we create a alert policy to monitor logs of cloud function failure using "google_monitoring_alert_policy" resource.


## Variables to be configured
We need define the following parameters for the pipeline to work as expected :
1. `project` : GCP project ID with all the pre-requisites mentioned in the main page.
2. `bucket_name` : GCS bucket name where we shall store the CSV file as well the python source archive. This needs to be GLOBALLY UNIQUE, hence prefixing it with project id might be a good idea.
3. `location` : GCP region where the infrastructure and data will be hosted
4. `csv_file_name` : Name of the raw CSV file that contains the data.
5. `csv_file_path` : relative path to the CSV file in local file system.
6. `dataset_id` : Bigquery dataset id that will be created and store the tables and views.
7. `result_table_name` : Table name where the transformed transaction will be stored.
8. `error_table_name` : Table name where error records will be stored
9. `schema` : JSON format of the table schema. tweak if the CSV structure changes.
10. `entry_point` : The main entry point for the cloud function. In our source code it is transform_load_csv_file.
11. `alert_email_address` : Email address where the alert notification will be sent on pipeline failures.
12. `path_to_queries` : Relative path where SQL queries are stored
13. `cron_scedule` : CRON expression for cloud scheduler. "0 9 * * *" denotes everyday at 9 AM.
14. `python_source_dir` : Relative path to the python source code. "../transformation/" by default based on the uploaded structure.
15. `python_zip_output_file_name` : Name of the zip file created by the archive resource. "transformation.zip" by default
16. `service_account_name` : Cloud scheduler service account name. "transformation-scheduler" by default.
17. `cloud_function_name` : Name of the cloud function. "transform_load_raw_csv" by default
18. `cloud_scheduler_name` : Name of cloud scheduler."function-scheduler" by default 
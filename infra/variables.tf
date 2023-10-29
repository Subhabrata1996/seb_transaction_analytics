variable "project" {
  description = "GCP project ID."
  type        = string
}

variable "bucket_name" {
  description = "The bucket used for storing raw CSV files."
  type        = string
}

variable "location" {
  description = "Region for GCS bucket."
  type        = string
}

variable "csv_file_name" {
  description = "CSV file name to be uploaded."
  type        = string
}

variable "csv_file_path" {
  description = "Relative path of the CSV file."
  type        = string
}

variable "dataset_id" {
  description = "Bigquery dataset ID."
  type        = string
}

variable "result_table_name" {
  description = "Table name for the transformed transaction data."
  type        = string
}

variable "error_table_name" {
  description = "Table name for the transaction data which have error while processing."
  type        = string
}

variable "schema" {
  description = "Table name for the transaction data which have error while processing."
  type        = string
}

variable "entry_point" {
  description = "Entry point to the cloud function."
  type        = string
}

variable "alert_email_address" {
  description = "Email address where alert will be sent."
  type        = string
}

variable "path_to_queries" {
  description = "Relative path to the folder where analysis queries are stored."
  type        = string
}

variable "cron_schedule" {
  description = "CRON expression for cloud scheduler"
  type        = string
}

variable "python_source_dir" {
  description = "Relative path to the python source directory."
  type        = string
  default     = "../transformation/"
}

variable "python_zip_output_file_name" {
  description = "Name of the python source zip file, that will be used by cloud function."
  type        = string
  default     = "transformation.zip"
}

variable "service_account_name" {
  description = "Name of the service account that will be used by cloud scheduler."
  type        = string
  default     = "transformation-scheduler"
}

variable "cloud_function_name" {
  description = "Name of the cloud function that will host the transformation script."
  type        = string
  default     = "transform_load_raw_csv"
}

variable "cloud_scheduler_name" {
  description = "Name of the cloud scheduler that will execute the data pipeline everyday."
  type        = string
  default     = "function-scheduler"
}
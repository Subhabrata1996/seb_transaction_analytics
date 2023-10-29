terraform {
  required_version = "~>1.2.6"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~>4.52.0"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.location
}

resource "google_storage_bucket" "bucket" {
  project  = var.project
  name     = var.bucket_name
  location = var.location
}

// Upload CSV file to GCS Bucket
resource "google_storage_bucket_object" "csv_file_upload" {
  name   = var.csv_file_name
  source = var.csv_file_path
  bucket = google_storage_bucket.bucket.id
}

// Zip and upload the python cloud function script to GCS bucket
data "archive_file" "my_zip" {
  type        = "zip"
  source_dir  = var.python_source_dir
  output_path = var.python_zip_output_file_name
}

resource "google_storage_bucket_object" "file_upload" {
  name   = var.python_zip_output_file_name
  source = var.python_zip_output_file_name
  bucket = google_storage_bucket.bucket.id
}

// Create bigquery dataset that will store the result table and analytics views
resource "google_bigquery_dataset" "seb_analytics_dataset" {
  dataset_id = var.dataset_id
  project    = var.project
  location   = var.location
}

resource "google_bigquery_table" "bigquery_result_table" {
  dataset_id          = google_bigquery_dataset.seb_analytics_dataset.dataset_id
  project             = var.project
  table_id            = var.result_table_name
  schema              = var.schema
  deletion_protection = false
}

// The records not correctly parsed by the transformation script will be inserted in the error table
resource "google_bigquery_table" "bigquery_error_table" {
  dataset_id          = google_bigquery_dataset.seb_analytics_dataset.dataset_id
  project             = var.project
  table_id            = var.error_table_name
  schema              = var.schema
  deletion_protection = false
}

// Service account to trigger cloud scheduler HTTP job.
resource "google_service_account" "transformation_scheduler_sa" {
  account_id   = var.service_account_name
  display_name = var.service_account_name
  project      = var.project
}

resource "google_project_iam_member" "cf_invoker" {
  project = var.project
  role    = "roles/cloudfunctions.invoker"
  member  = "serviceAccount:${google_service_account.transformation_scheduler_sa.email}"
}

// Cloud function that will execure the transformation script
resource "google_cloudfunctions_function" "transformation_cloud_function" {
  depends_on            = [google_storage_bucket_object.file_upload]
  name                  = var.cloud_function_name
  runtime               = "python38"
  entry_point           = var.entry_point
  source_archive_bucket = google_storage_bucket.bucket.id
  source_archive_object = var.python_zip_output_file_name
  project               = var.project
  trigger_http          = true
  region                = var.location
  available_memory_mb   = 512
  timeout               = 60
  environment_variables = {
    PROJECT                   = var.project,
    CSV_GCS_BUCKET            = google_storage_bucket.bucket.id,
    CSV_FILE_NAME             = var.csv_file_name,
    BIGQUERY_DATASET_ID       = google_bigquery_dataset.seb_analytics_dataset.dataset_id,
    BIGQUERY_TABLE_NAME       = var.result_table_name,
    BIGQUERY_ERROR_TABLE_NAME = var.error_table_name
  }
}

// Cloud scheduler that will trigger the HTTP cloud function based on cron expression 
resource "google_cloud_scheduler_job" "function_scheduler" {
  name      = var.cloud_scheduler_name
  schedule  = var.cron_schedule
  time_zone = "UTC"
  region    = var.location
  http_target {
    http_method = "POST"
    uri         = google_cloudfunctions_function.transformation_cloud_function.https_trigger_url
    headers = {
      "Authorization" = "bearer $(gcloud auth print-identity-token)"
      "Content-Type" = "application/json"
    }
    body = ""
    oidc_token {
      service_account_email = google_service_account.transformation_scheduler_sa.email
    }
  }
}

// Email channel for alerting
resource "google_monitoring_notification_channel" "email" {
  display_name = "Email Alert"
  type         = "email"

  labels = {
    email_address = var.alert_email_address
  }
}

// Cloud monitoring alery configuration
resource "google_monitoring_alert_policy" "transformation_failure_alert" {
  display_name = "Transformation Failure Alert"
  combiner     = "OR"
  conditions {
    display_name = "Function Failure Condition"

    condition_matched_log {
      filter = "resource.type = \"cloud_function\" AND resource.labels.function_name = \"transform_load_raw_csv\" AND resource.labels.project_id=${var.project} AND severity>=\"ERROR\""
    }
  }

  alert_strategy {
    auto_close = "604800s"
    notification_rate_limit {
      period = "3600s"
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]
}

locals {
  view_files = fileset(var.path_to_queries, "*.sql")
}

// Create analysis views based on .SQL files
resource "google_bigquery_table" "analysis_views" {
  for_each   = fileset(var.path_to_queries, "*.sql")
  dataset_id = google_bigquery_dataset.seb_analytics_dataset.dataset_id
  table_id   = substr(each.value, 0, length(each.value) - 4)
  view {
    use_legacy_sql = false
    query          = templatefile("${var.path_to_queries}/${each.value}", { TABLE_NAME = "${google_bigquery_table.bigquery_result_table.dataset_id}.${google_bigquery_table.bigquery_result_table.table_id}" })
  }
  deletion_protection = false
}
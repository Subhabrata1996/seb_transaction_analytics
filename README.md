# SEB Transaction analytics
This project uses terraform and python to provision and schedule a data pipeline that extracts data from a raw CSV file and loads it into bigquery for analytics.

## Pre-requisites

For this pipeline to work properly we need the following components in place -
1. GCP Project - A GCP Project will valid billing account linked to it
2. Enabled APIs - The project should have the below APIs enabled : (Only a project EDIToR or OWNER has the permission to perform this task)
  a. Bigquery
  b. Cloud Storage
  c. Cloud Functions
  d. Cloud Scheduler
  e. Cloud Monitoring
This can be achieved using the GCP UI or by command line using [gcloud](https://cloud.google.com/endpoints/docs/openapi/enable-api)
3. We will be using personal GCP account credentials for this exercise, but this is also possible using service account. Either way the GCP account or SA should have the following roles assigned to it:
   a. Cloud Storage - Storage Admin
   b. Bigquery - Bigquery Admin
   c. Cloud Function - Cloud function developer
   d. Cloud Scheduler - Cloud Scheduler Admin
   e. Monitoring - Editor
   f. IAM - Admin
4. Google Cloud CLI installed in your development environment - [install gcloud](https://cloud.google.com/sdk/docs/install)
5. [Python](https://wiki.python.org/moin/BeginnersGuide/Download)
6. Virtual environment - To isolate dependencies across different python projects its recommended to use a python virtualization framework - [venv](https://docs.python.org/3/library/venv.html)
7. Terraform - All our infrastructure will be provisioned using an Infrastructure As A Code framework - terraform. Install and configure [Terraform](https://developer.hashicorp.com/terraform/downloads)

## Getting Started
Download and extract the SEB.zip file in your local file system. The folder SEB will have 4 folders apart from this readme file :
1. data : This folder will contain the CSV file provided for the exercise.
2. infra : This folder contains all the infrastructure configuration that will be provisioned for this project.
3. queries : This will contain the SQL queries that will be created as Bigquery views as described in the assignment
4. transformation : This folder contains the python transformation script and unit tests for the python module

Once familierized with the structure, navigate to the infra folder
```bash
cd infra
```
All configurations are maintained in the [vars.auto.tfvars](infra/vars.auto.tfvars) file. More information on the configuration file and terraform will be available in the [README](infra/README.MD) file inside infra directory.

Change the variable as per the GCP project and settings we want.

### Authenticating gcloud
From local development console we need authenticate gcloud using personal account or a service account. Use the below commands to authenticate gcloud

```bash
gcloud auth application-default login
```

```bash
gcloud config set project YOUR_PROJECT_ID
```

## Provision Infrastructure

Once the configuration file is edited as per project, we can not start provisioning the infrastructure.

use terraform init to initialize the terraform project and install the neccessary providers

```bash
terraform init
```

once initialization is complete - use terraform plan to get an overview of what changes in the infrastructure will be caused. Its a good idea to review the changes that will be caused

```bash
terraform plan
```

once we are happy with the plan, we can use terraform apply to provision the infrastructure.

```bash
terraform apply
```

This step will create all the components for data pipeline. Once completed we can verify the components in GCP project.

As this is a test exercise, we can also use terraform destroy to delete everything we have created using terraform and save cost.


```bash
terraform destroy
```

## Verify pipeline
We can verify that the pipeline works by navigating to bigquery and we should find the configured dataset, tables and analisys views.

We can also look at the logs of cloud function and cloud scheduler from GCP console.

As the cloud scheduler is set to run at 9AM UTC everyday, by default the pipeline will not run when the infra is deployed. we can either change the schedule to something more frequent like every 5 mins - */5 * * * * or trigger the cloud scheduler manually using console.

To verify if our error handling and alert mechanism works we can have two test cases -
1. Delete the csv file manually from GCS bucket and run the pipeline. This will send an alert to the configured email address as the cloud function will fail.
2. Insert error records in the CSV file -

abc-123,1234,dummy,-277.84,2023-05-22 23:56:58

abc-321,1234,credit,dummy,2023-05-22 23:56:58

abc-432,1234,credit,-277.84,2023-05-22

abc-322,1234,credit,-277.84,2023-05-32 23:56:58

This should identify the error records and populate it in the error table.

## Considerations
I have made the following assumptions for this project, code may be tweaked if these considerations are incorrect.
1. transaction_amount "error" - I have explicitly converted them to 0 and not considered them as error records. By making the amount as 0 the calculated column "balance" will not be impacted. If this assumption is wrong - please see the [python source code](transformation/main.py) to comment out this step.
2. balance - As we don't know the starting balance of each account, we consider the balance to be 0 and the first transaction of each account becomes our base balance.
3. What are the top ten accounts with the highest balances? - I have considered the balance of each account as on last transaction

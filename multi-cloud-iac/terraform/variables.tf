variable "azure_location" {
  description = "Default Azure location for resources."
  type        = string
  default     = "eastus"
}

variable "aws_region" {
  description = "Default AWS region for resources."
  type        = string
  default     = "us-east-1"
}

variable "gcp_project_id" {
  description = "GCP project id used by the Google provider."
  type        = string
}

variable "gcp_region" {
  description = "Default GCP region for resources."
  type        = string
  default     = "us-central1"
}

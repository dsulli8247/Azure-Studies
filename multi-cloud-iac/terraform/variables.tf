variable "azure_subscription_id" {
  description = "Azure subscription ID used by the AzureRM provider."
  type        = string
}

variable "aws_region" {
  description = "Default AWS region for resources."
  type        = string
  default     = "us-east-1"
}

variable "gcp_project_id" {
  description = "GCP project id used by the Google provider."
  type        = string
  default     = "your-gcp-project-id"
}

variable "gcp_region" {
  description = "Default GCP region for resources."
  type        = string
  default     = "us-central1"
}

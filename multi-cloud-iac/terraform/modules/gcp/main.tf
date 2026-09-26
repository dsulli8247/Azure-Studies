variable "project_id" {
  description = "GCP project id."
  type        = string
}

variable "region" {
  description = "GCP region."
  type        = string
}

output "status" {
  value       = "GCP module scaffolded."
  description = "Initial placeholder output for GCP module."
}

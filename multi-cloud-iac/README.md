# multi-cloud-iac

Starter project for a Dev Container-based Terraform development environment targeting Azure, AWS, and GCP.

## What this includes

- Dev Container configuration in `.devcontainer`
- Terraform starter configuration in `terraform`
- Provider and variable scaffolding for all three clouds

## Quick start

1. Open the `multi-cloud-iac` folder in VS Code.
2. Reopen in Container when prompted.
3. In the container terminal:
   - `terraform -version`
   - `az version`
   - `aws --version`
   - `gcloud --version`
   - Authenticate as needed: `az login`, `aws configure`, `gcloud auth application-default login`
4. Go to `terraform` and run:
   - `cd terraform`
   - `cp terraform.tfvars.example terraform.tfvars`
   - Edit `terraform.tfvars` and set `gcp_project_id`
   - `terraform init`
   - `terraform validate`

## Next steps

- Add reusable modules under `terraform/modules`
- Add environment-specific variable files
- Add CI to run `terraform fmt -check`, `terraform validate`, and `terraform plan`

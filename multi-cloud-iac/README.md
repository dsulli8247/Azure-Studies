# multi-cloud-iac

Starter project for a Dev Container-based Terraform development environment targeting Azure, AWS, and GCP.

## What this includes

- Dev Container configuration in `/home/runner/work/Azure-Studies/Azure-Studies/multi-cloud-iac/.devcontainer`
- Terraform starter configuration in `/home/runner/work/Azure-Studies/Azure-Studies/multi-cloud-iac/terraform`
- Provider and variable scaffolding for all three clouds

## Quick start

1. Open `/home/runner/work/Azure-Studies/Azure-Studies/multi-cloud-iac` in VS Code.
2. Reopen in Container when prompted.
3. In the container terminal:
   - `terraform -version`
   - `az version`
   - `aws --version`
   - `gcloud --version`
4. Go to `/home/runner/work/Azure-Studies/Azure-Studies/multi-cloud-iac/terraform` and run:
   - `terraform init`
   - `terraform validate`

## Next steps

- Add reusable modules under `/home/runner/work/Azure-Studies/Azure-Studies/multi-cloud-iac/terraform/modules`
- Add environment-specific variable files
- Add CI to run `terraform fmt -check`, `terraform validate`, and `terraform plan`

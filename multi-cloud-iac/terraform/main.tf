module "azure" {
  source = "./modules/azure"

  location = var.azure_location
}

module "aws" {
  source = "./modules/aws"

  region = var.aws_region
}

module "gcp" {
  source = "./modules/gcp"

  project_id = var.gcp_project_id
  region     = var.gcp_region
}

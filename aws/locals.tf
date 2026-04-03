# See: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/resource-tagging
locals {
  additional_tags = {
    Project = var.project_name
  }
}
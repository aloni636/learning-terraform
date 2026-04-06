# See: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/resource-tagging
locals {
  additional_tags = {
    Project = var.project_name
  }
  public_azs         = { for az, cfg in var.availability_zones : az => cfg if cfg.public_cidr != null }
  has_public_subnets = length(local.public_azs) > 0
  private_azs        = { for az, cfg in var.availability_zones : az => cfg }
  nat_azs            = { for az, cfg in var.availability_zones : az => cfg if cfg.private_nat }
  rds_azs            = { for az, cfg in var.availability_zones : az => cfg if cfg.private_rds_az }
}

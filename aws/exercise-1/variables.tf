variable "project_name" {
  description = "The name of the project associated with all its resources"
  type        = string
  default     = "learning-terraform"
}

# See: https://docs.aws.amazon.com/global-infrastructure/latest/regions/aws-availability-zones.html
variable "region" {
  default     = "eu-central-1"
  type        = string
  description = "The region of the provisioned resources"
}

# See: https://docs.aws.amazon.com/global-infrastructure/latest/regions/aws-availability-zones.html
variable "availability_zone_id" {
  default     = "euc1-az1"
  type        = string
  description = "The availability zone id of the provisioned resources"
}

# See: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/resource-tagging
locals {
  additional_tags = {
    Project = var.project_name
  }
}

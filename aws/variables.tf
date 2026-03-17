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

# t3 is the default instead of t4 because X84_64 is compatible with more software compared to ARM
variable "instance_type" {
  default     = "t3.micro"
  type        = string
  description = "The instance type of the provisioned EC2 instance"
}

variable "public_ssh_key_path" {
  default     = "~/.ssh/id_ed25519.pub"
  type        = string
  description = "The public-key used to log into the provisioned public EC2 instance"
}

# See: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/resource-tagging
locals {
  additional_tags = {
    Project = var.project_name
  }
}

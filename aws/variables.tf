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
variable "availability_zones" {
  default = {
    # Public range:    10.0.0.0 - 10.0.127.255
    # Private range: 10.0.128.0 - 10.0.255.255
    "euc1-az1" = {
      public_cidr  = "10.0.0.0/19",   # Range: 10.0.0.0 - 10.0.31.255; Possible IPs: 8192
      private_cidr = "10.0.128.0/19", # Range: 10.0.128.0 - 10.0.159.255; Possible IPs: 8192
    },
    "euc1-az2" = {
      public_cidr  = "10.0.32.0/19",  # Range: 10.0.32.0 - 10.0.63.255; Possible IPs: 8192
      private_cidr = "10.0.160.0/19", # Range: 10.0.160.0 - 10.0.181.255; Possible IPs: 8192
    },
  }
  type = map(object({
    public_cidr  = string
    private_cidr = string
  }))
  description = "The availability zones configuration of the provisioned VPC"
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

variable "s3_bucket_name" {
  type = string
}

# See: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/resource-tagging
locals {
  additional_tags = {
    Project = var.project_name
  }
}

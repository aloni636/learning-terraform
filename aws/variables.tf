variable "project_name" {
  description = "The name of the project associated with all its resources"
  type        = string
  default     = "learning-terraform"
}

# See: https://docs.aws.amazon.com/global-infrastructure/latest/regions/aws-availability-zones.html
variable "region" {
  type        = string
  description = <<EOF
  The region of the provisioned resources. \
  See: https://docs.aws.amazon.com/global-infrastructure/latest/regions/aws-availability-zones.html
  EOF
  nullable = false
}

# 
variable "availability_zones" {
  type = map(object({
    public_cidr  = string
    private_cidr = string
  }))
  description = <<EOF
  The availability zones configuration of the provisioned VPC. \
  See: https://docs.aws.amazon.com/global-infrastructure/latest/regions/aws-availability-zones.html
  EOF
  nullable = false
}

# t3 is the default instead of t4 because X84_64 is compatible with more software compared to ARM
variable "instance_type" {
  default     = "t3.micro"
  type        = string
  description = "The instance type of the provisioned EC2 instance"
  nullable = false
}

variable "public_ssh_key_path" {
  default     = "~/.ssh/id_ed25519.pub"
  type        = string
  description = "The public-key file location used to log into the provisioned public EC2 instance"
  nullable = false
}

variable "s3_bucket_name" {
  type = string
  description = "The S3 bucket name provisioned for the private subnets"
  nullable = false
}

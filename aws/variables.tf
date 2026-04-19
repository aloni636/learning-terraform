variable "project_name" {
  description = "The name of the project associated with all its resources"
  type        = string
  default     = "learning-terraform"
}

# See: https://docs.aws.amazon.com/global-infrastructure/latest/regions/aws-availability-zones.html
variable "region" {
  type        = string
  description = <<-EOF
  The region of the provisioned resources. \
  See: https://docs.aws.amazon.com/global-infrastructure/latest/regions/aws-availability-zones.html
  EOF
  nullable    = false
}

# Each key is an availability zone name (NOT AZ-ID!), which can be queried from the aws cli:
# `aws ec2 describe-availability-zones --region <YOUR_REGION>` --query "AvailabilityZones[*].ZoneName"`
# https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-availability-zones.html
variable "availability_zones" {
  type = map(object({
    public_cidr  = optional(string)
    private_cidr = string
    ssm_cidr     = string
    private_nat  = optional(bool, false)
    rds_cidr     = optional(string)
    main_az      = optional(bool, false)
    private_ec2  = optional(bool, false)
  }))
  description = <<-EOF
  A key/value pairs of `<availability_zone_name> = <configuration>` \
  controlling the availability zone configurations of the provisioned VPC. \
  See: https://docs.aws.amazon.com/global-infrastructure/latest/regions/aws-availability-zones.html
  EOF
  nullable    = false

  # RDS requires at least 2 azs to allow internal AWS maintenance
  validation {
    condition     = length([for az, cfg in var.availability_zones : az if cfg.rds_cidr != null]) >= 2
    error_message = <<-EOF
    RDS requires at least 2 availability zones to deploy an RDS instance.
    Consider allocating IP ranges in at least 2 AZs for RDS.
    EOF
  }

  validation {
    condition     = length([for az, cfg in var.availability_zones : az if cfg.main_az]) == 1
    error_message = <<-EOF
    Only one AZ can be the main AZ. Main AZ is used to place the RDS instance and the \
    SSM based bastion EC2 instance in it.
    EOF
  }

  validation {
    condition     = alltrue([for az, cfg in var.availability_zones : cfg.rds_cidr != null if cfg.main_az])
    error_message = <<-EOF
    Main AZ is used to place an RDS instance within it, therefore it must have an RDS cidr block.
    EOF
  }

  validation {
    # Return true only if every private_nat enabled az has a corresponding public_cidr block,
    # as we cannot deploy a not without a public facing subnet
    condition     = alltrue([for az, cfg in var.availability_zones : cfg.private_nat == (cfg.public_cidr != null)])
    error_message = <<-EOF
    NAT requires at a public subnet.
    Make sure every AZ with `private_nat=true` has a public_cidr block defined.
    EOF
  }
}

# t3 is the default instead of t4 because X84_64 is compatible with more software compared to ARM
variable "ec2_instance_type" {
  default     = "t3.micro"
  type        = string
  description = "The instance type of all provisioned EC2 instances"
  nullable    = false
}

variable "bastion_instance_type" {
  default     = "t4g.nano"
  type        = string
  description = "The instance type of the provisioned bastion/jump-box for RDS"
  nullable    = false
}

variable "public_ssh_key_path" {
  default     = "~/.ssh/id_ed25519.pub"
  type        = string
  description = "The public-key file location used to log into the provisioned public EC2 instance"
  nullable    = false
}

# t4 is the default because the software is managed by AWS and is guaranteed to be compatible with ARM
# See: https://aws.amazon.com/rds/postgresql/pricing/#:~:text=On%2DDemand%20DB%20Instances%20costs
variable "rds_instance_type" {
  default     = "db.t4g.small"
  type        = string
  description = "The instance type of the provisioned RDS instance"
  nullable    = false
}

variable "s3_bucket_name" {
  type        = string
  description = "The S3 bucket name provisioned for the private subnets"
  nullable    = false
}

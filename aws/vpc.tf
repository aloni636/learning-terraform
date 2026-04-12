# The most basic VPC possible
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"

  # Necessary for SSM endpoint within the private subnet
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.additional_tags, {
    "Name" = "${var.project_name}-vpc"
  })
}

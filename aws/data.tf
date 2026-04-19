# ----- My IP for Security Groups ----- #
data "http" "my_ip_raw" {
  url = "https://ifconfig.me/ip"
}

locals {
  my_ipv4      = data.http.my_ip_raw.response_body
  my_ipv4_cidr = "${data.http.my_ip_raw.response_body}/32"
}

output "my_ip_raw_response" {
  value = data.http.my_ip_raw.response_body
}

# ----- AWS AMI for EC2 ----- #
/* Terraform docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
Canonical AMI owner: https://documentation.ubuntu.com/aws/aws-how-to/instances/find-ubuntu-images/#ownership-verification
Ubuntu release names: https://documentation.ubuntu.com/project/release-team/list-of-releases/
Query all current Ubuntu 24.04 (Noble) images using: 
```
aws ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/*24.04*" \
  --query 'Images[*].[ImageId,Name]' \
  --output table
``` */
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical AMI owner ID
}

# See: https://docs.aws.amazon.com/systems-manager/latest/userguide/parameter-store-public-parameters-ami.html
# Access the AMI id with the `value` attribute
data "aws_ssm_parameter" "amazon_linux_arm" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-arm64"
}

# CIDR blocks dedicated to the regional S3 services, accessible from the VPC gateway
data "aws_prefix_list" "s3" {
  name = "com.amazonaws.${var.region}.s3"
}

# NOTE: You can view all s3 prefix lists (list of CIDR blocks) by uncommenting this block:
# output "aws_s3_prefix_list" { value = data.aws_prefix_list.s3.cidr_blocks }
output "aws_ami_ubuntu_name" { value = data.aws_ami.ubuntu.name }
output "aws_ami_ubuntu_creation_date" { value = data.aws_ami.ubuntu.creation_date }
output "aws_ami_amazon_linux_ami" { value = data.aws_ssm_parameter.amazon_linux_arm.name }

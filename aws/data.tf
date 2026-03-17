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

output "aws_ami_ubuntu_name" {
  value = data.aws_ami.ubuntu.name
}
output "aws_ami_ubuntu_creation_date" {
  value = data.aws_ami.ubuntu.creation_date
}

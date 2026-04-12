# ----- Public EC2 Instance ----- #
resource "aws_key_pair" "deployer" {
  # Trick to conditionally create a resource
  # NOTE: This resource is now a list with 0 or 1 items, so referencing it requires indexing
  count = local.has_public_subnets ? 1 : 0

  key_name   = "${var.project_name}-deployer-key"
  public_key = file(var.public_ssh_key_path)
  tags = merge(local.additional_tags, {
    "Name" = "${var.project_name}-public-ec2-instance-public-key"
  })
}

# NOTE: When unspecified, default EBS storage is (as of 17/3/26) an 8GB gp3 SSD
resource "aws_instance" "public_instances" {
  for_each = local.public_azs

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.ec2_instance_type
  subnet_id     = aws_subnet.public_subnets[each.key].id
  # Security groups are merged and cannot conflict with each other because they only support allow lists
  vpc_security_group_ids = [ # NOTE: Don't use `security_groups` if the EC2 instance is within a VPC
    aws_security_group.allow_my_ip_inbound_ssh.id,
    aws_security_group.allow_all_outbound_ipv4.id,
  ]
  key_name = aws_key_pair.deployer[0].key_name

  tags = merge(local.additional_tags, {
    "Name" = "${var.project_name}-public-ec2-instance-${each.key}"
  })
}

output "public_instance_ip_addresses" {
  value       = { for k, v in aws_instance.public_instances : k => v.public_ip }
  description = "Use the public IP to connect to the public instance: `ssh ubuntu@<PUBLIC-IP>`"
}

# ----- Private EC2 Instance ----- #
resource "aws_instance" "private_instances" {
  for_each = var.availability_zones

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.ec2_instance_type
  subnet_id     = aws_subnet.private_subnets[each.key].id
  vpc_security_group_ids = [
    aws_security_group.allow_outbound_ssm.id,
    aws_security_group.allow_all_outbound_ipv4.id,
    aws_security_group.allow_outbound_s3.id,
    aws_security_group.outbound_rds.id
  ]

  iam_instance_profile        = aws_iam_instance_profile.private_ec2_profile.name
  associate_public_ip_address = false

  tags = merge(local.additional_tags, {
    "Name" = "${var.project_name}-private-ec2-instance-${each.key}"
  })
}

output "private_instance_ids" {
  value       = { for k, v in aws_instance.private_instances : k => v.id }
  description = "Use the instance ids with SSM to connect to the private instance: `aws ssm start-session --target <INSTANCE-ID>`"
}

resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-deployer-key"
  public_key = file(var.public_ssh_key_path)
  tags = merge(local.additional_tags, {
    "Name" = "${var.project_name}-public-ec2-instance-public-key"
  })
}

# NOTE: When unspecified, default EBS storage is (as of 17.3.26) an 8GB gp3 SSD
resource "aws_instance" "public_instance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public_subnet.id
  # Security groups are merged and cannot conflict with each other because they only support allow lists
  security_groups = [aws_security_group.allow_public_ssh.id]
  key_name        = aws_key_pair.deployer.key_name

  tags = merge(local.additional_tags, {
    "Name" = "${var.project_name}-public-ec2-instance"
  })
}

output "public_instance_ip_address" {
  value = aws_instance.public_instance.public_ip
}

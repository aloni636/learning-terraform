# The most basic VPC possible
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"

  tags = merge(local.additional_tags, {
    "Name" = "${var.project_name}-vpc"
  })
}

# Not a lot of config available for gateways
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(local.additional_tags, {
    "Name" = "${var.project_name}-igw"
  })
}

# ----- Subnets ----- #
resource "aws_subnet" "public_zone" {
  vpc_id               = aws_vpc.vpc.id
  cidr_block           = "10.0.0.0/19" # Range: 10.0.0.0 - 10.0.31.255; Possible IPs: 8192
  availability_zone_id = var.availability_zone_id

  map_public_ip_on_launch = true # Defaults to false

  tags = merge(local.additional_tags, {
    "Name" = "${var.project_name}-public-zone"
  })
}

/* NOTE: Every subnet has a route table. One without an explicit route table gets associated
   with a default one which maps the entire VPC cidr block to local, i.e. `10.0.0.0/16: local` */
resource "aws_subnet" "private_zone" {
  vpc_id               = aws_vpc.vpc.id
  cidr_block           = "10.0.32.0/19" # Range: 10.0.32.0 - 10.0.63.255; Possible IPs: 8192
  availability_zone_id = var.availability_zone_id

  tags = merge(local.additional_tags, {
    "Name" = "${var.project_name}-private-zone"
  })
}

# ----- Public Routes Table ----- #
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  # Route every destination (apart from local IPs, i.e. 10.0.0.0/19) to the internet
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(local.additional_tags, {
    "Name" = "${var.project_name}-public-route-table"
  })
}

resource "aws_route_table_association" "public_zone" {
  subnet_id      = aws_subnet.public_zone.id
  route_table_id = aws_route_table.public_route_table.id
}

# ----- Firewall ----- #
# See: https://registry.terraform.io/providers/-/aws/latest/docs/resources/security_group
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow inbound SSH only from my IP and any outbound traffic"
  vpc_id      = aws_vpc.vpc.id

  tags = merge(local.additional_tags, {
    Name = "${var.project_name}-allow-ssh-security-group"
  })
}

resource "aws_vpc_security_group_ingress_rule" "allow_inbound_ssh_ipv4" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv4         = local.my_ipv4_cidr
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22

  tags = merge(local.additional_tags, {
    "Name" = "${var.project_name}-allow-inbound-ssh-ipv4"
  })
}

/* NOTE: By default AWS creates an ALLOW_ALL egress rule,
   but AWS terraform provider removes it, which means we have to re-add it */
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports

  tags = merge(local.additional_tags, {
    "Name" = "${var.project_name}-allow-all-egress-traffic-ipv4"
  })
}




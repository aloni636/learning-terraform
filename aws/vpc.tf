# The most basic VPC possible
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"

  # Necessary for SSM endpoint within the private subnet
  enable_dns_hostnames = true
  enable_dns_support = true

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
resource "aws_subnet" "public_subnet" {
  vpc_id               = aws_vpc.vpc.id
  cidr_block           = "10.0.0.0/19" # Range: 10.0.0.0 - 10.0.31.255; Possible IPs: 8192
  availability_zone_id = var.availability_zone_id

  map_public_ip_on_launch = true # Defaults to false

  tags = merge(local.additional_tags, {
    "Name" = "${var.project_name}-public-subnet"
  })
}

/* NOTE: Every subnet has a route table. One without an explicit route table gets associated
   with a default one which maps the entire VPC cidr block to local, i.e. `10.0.0.0/16: local` */
resource "aws_subnet" "private_subnet" {
  vpc_id               = aws_vpc.vpc.id
  cidr_block           = "10.0.32.0/19" # Range: 10.0.32.0 - 10.0.63.255; Possible IPs: 8192
  availability_zone_id = var.availability_zone_id

  tags = merge(local.additional_tags, {
    "Name" = "${var.project_name}-private-subnet"
  })
}

# ----- NAT Gateway for Private Subnet ----- #
resource "aws_eip" "eip" {
  domain = "vpc"

  depends_on = [aws_internet_gateway.igw]
  tags = merge(local.additional_tags, {
    "Name" = "${var.project_name}-eip"
  })
}

# See: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway#public-nat
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id     = aws_eip.eip.id
  subnet_id         = aws_subnet.public_subnet.id # Where to place the NAT service
  availability_mode = "zonal"                     # classic NATs are zonal, while newer NATs can also be regional for high availability

  depends_on = [aws_internet_gateway.igw]
  tags = merge(local.additional_tags, {
    "Name" = "${var.project_name}-nat-gateway"
  })
}

# ----- Public Route Table ----- #
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

resource "aws_route_table_association" "public_subnet_route_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# ----- Private Route Tables ----- #
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = merge(local.additional_tags, {
    "Name" = "${var.project_name}-private-route-table"
  })
}

resource "aws_route_table_association" "private_subnet_route_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}

# ----- Public Firewall ----- #
# See: https://registry.terraform.io/providers/-/aws/latest/docs/resources/security_group
/* NOTE: Security groups are defined at the VPC level but are attached to
   ENI (Elastic Network Interface) supporting resources like EC2, RDS, Lambda, etc. */
resource "aws_security_group" "allow_my_ip_inbound_ssh" {
  name        = "allow_my_ip_inbound_ssh"
  description = "Allow inbound SSH only from my IP and any outbound traffic"
  vpc_id      = aws_vpc.vpc.id

  tags = merge(local.additional_tags, {
    Name = "${var.project_name}-allow-my-ip-inbound-ssh"
  })
}

resource "aws_security_group" "allow_all_outbound_ipv4" {
  name        = "allow_all_outbound_ipv4"
  description = "Allow any outbound ipv4 communication"
  vpc_id      = aws_vpc.vpc.id

  tags = merge(local.additional_tags, {
    Name = "${var.project_name}-allow-all-outbound-ipv4"
  })
}

resource "aws_vpc_security_group_ingress_rule" "allow_my_ip_inbound_ssh_rule" {
  security_group_id = aws_security_group.allow_my_ip_inbound_ssh.id
  cidr_ipv4         = local.my_ipv4_cidr
  from_port         = 22
  ip_protocol       = "tcp" # SSH is based on TCP protocol
  to_port           = 22

  tags = merge(local.additional_tags, {
    "Name" = "${var.project_name}-allow-my-ip-inbound-ssh-rule"
  })
}

/* NOTE: By default AWS creates an ALLOW_ALL egress rule,
   but AWS terraform provider removes it, which means we have to re-add it */
resource "aws_vpc_security_group_egress_rule" "allow_all_outbound_ipv4_rule" {
  security_group_id = aws_security_group.allow_all_outbound_ipv4.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports

  tags = merge(local.additional_tags, {
    "Name" = "${var.project_name}-allow-all-outbound-ipv4-rule"
  })
}

# ----- Private SSM Firewall ----- #
resource "aws_security_group" "allow_outbound_ssm" {
  name        = "allow_outbound_ssm"
  description = "Allow HTTPS from private instances to SSM endpoints"
  vpc_id      = aws_vpc.vpc.id

  tags = merge(local.additional_tags, {
    Name = "${var.project_name}-allow-outbound-ssm"
  })
}

# SSM requires port 443; See: https://docs.aws.amazon.com/general/latest/gr/ssm.html#ssm_region
resource "aws_vpc_security_group_egress_rule" "allow_outbound_ssm_rule" {
  security_group_id = aws_security_group.allow_outbound_ssm.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  /* Different from classical cidr block notation, this security rule means that 
     only SSM endpoints can be contacted from this security group */
  referenced_security_group_id = aws_security_group.allow_inbound_ssm.id
}

resource "aws_security_group" "allow_inbound_ssm" {
  name        = "allow_inbound_ssm"
  description = "Allow HTTPS from private instances to SSM endpoints"
  vpc_id      = aws_vpc.vpc.id

  tags = merge(local.additional_tags, {
    Name = "${var.project_name}-allow-inbound-ssm"
  })
}

resource "aws_vpc_security_group_ingress_rule" "allow_inbound_ssm_rule" {
  security_group_id = aws_security_group.allow_inbound_ssm.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  /* Different from classical cidr block notation, this security rule means that 
     only resources with outbound SSM security group can access SSM endpoints */
  referenced_security_group_id = aws_security_group.allow_outbound_ssm.id

  tags = merge(local.additional_tags, {
    Name = "${var.project_name}-allow-inbound-ssm-rule"
  })
}

# ----- Private Subnet SSM Endpoints ----- #
resource "aws_vpc_endpoint" "ssm_endpoints" {
  for_each = toset(["ssm", "ssmmessages", "ec2messages"])

  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_subnet.id]
  security_group_ids  = [aws_security_group.allow_inbound_ssm.id]
  # We need DNS to make sure the public SSM service IP gets translated to a private IP within the subnet
  private_dns_enabled = true

  tags = merge(local.additional_tags, {
    Name = "${var.project_name}-${each.value}-endpoint"
  })
}

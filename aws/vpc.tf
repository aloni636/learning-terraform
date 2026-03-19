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

# Gateways (which are AZ agnostic) don't have a lot of config
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(local.additional_tags, {
    "Name" = "${var.project_name}-igw"
  })
}

locals {

}

# ----- Subnets ----- #
resource "aws_subnet" "public_subnets" {
  for_each = var.availability_zones

  vpc_id               = aws_vpc.vpc.id
  cidr_block           = each.value.public_cidr
  availability_zone_id = each.key

  map_public_ip_on_launch = true # Defaults to false

  tags = merge(local.additional_tags, {
    "Name" = "${var.project_name}-public-subnet-${each.key}"
  })
}

/* NOTE: Every subnet has a route table. One without an explicit route table gets associated
   with a default one which maps the entire VPC cidr block to local, i.e. `10.0.0.0/16: local` */
resource "aws_subnet" "private_subnets" {
  for_each = var.availability_zones

  vpc_id               = aws_vpc.vpc.id
  cidr_block           = each.value.private_cidr
  availability_zone_id = each.key

  tags = merge(local.additional_tags, {
    "Name" = "${var.project_name}-private-subnet-${each.key}"
  })
}

# ----- NAT Gateway For Each AZ ----- #
# NOTE: NAT for each AZ is more resilient but costs ~32$ per AZ plus 0.05$ per GB data processing cost
#       Which is actually 2.5x higher then cross AZ data transfers (accounting for per direction cost)
# NAT Pricing: https://aws.amazon.com/vpc/pricing/#:~:text=VPC%20Encryption%20Controls-,NAT%20Gateway%20Pricing,-If%20you%20choose
# Cross Region Pricing: https://aws.amazon.com/ec2/pricing/on-demand/#Data_Transfer_within_the_same_AWS_Region:~:text=Data%20Transfer%20within%20the%20same%20AWS%20Region
resource "aws_eip" "eips" {
  for_each = var.availability_zones

  domain = "vpc"

  depends_on = [aws_internet_gateway.igw]
  tags = merge(local.additional_tags, {
    "Name" = "${var.project_name}-eip-${each.key}"
  })
}

# See: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway#public-nat
resource "aws_nat_gateway" "nat_gateways" {
  for_each = var.availability_zones

  # When iterating over a map, terraform allows accessing the created resources by the map keys
  allocation_id     = aws_eip.eips[each.key].id
  subnet_id         = aws_subnet.public_subnets[each.key].id # Where to place the NAT service
  availability_mode = "zonal"                                # Newer NATs can be regional, automatically provisioned per AZ, but cost is still per AZ

  depends_on = [aws_internet_gateway.igw]
  tags = merge(local.additional_tags, {
    "Name" = "${var.project_name}-nat-gateway-${each.key}"
  })
}

# ----- Public Route Table Shared Across AZs ----- #
# NOTE: A public route table is basically an all traffic route rule to internet gateway, so it can be shared across all AZs
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  # Route every destination (apart from local IPs, i.e. 10.0.0.0/17) to the internet
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(local.additional_tags, {
    "Name" = "${var.project_name}-public-route-table"
  })
}

resource "aws_route_table_association" "public_subnet_route_association" {
  for_each = var.availability_zones

  subnet_id      = aws_subnet.public_subnets[each.key].id
  route_table_id = aws_route_table.public_route_table.id
}

# ----- Private Route Table For Each AZ ----- #
# NOTE: We split each route table because we provision NAT per private AZ, reducing transfer costs
resource "aws_route_table" "private_route_tables" {
  for_each = var.availability_zones

  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateways[each.key].id
  }

  tags = merge(local.additional_tags, {
    "Name" = "${var.project_name}-private-route-table-${each.key}"
  })
}

resource "aws_route_table_association" "private_subnet_route_association" {
  for_each = var.availability_zones

  subnet_id      = aws_subnet.private_subnets[each.key].id
  route_table_id = aws_route_table.private_route_tables[each.key].id
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

  vpc_id             = aws_vpc.vpc.id
  service_name       = "com.amazonaws.${var.region}.${each.value}"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = values(aws_subnet.private_subnets)[*].id
  security_group_ids = [aws_security_group.allow_inbound_ssm.id]
  # We need DNS to make sure the public SSM service IP gets translated to a private IP within the subnet
  private_dns_enabled = true

  tags = merge(local.additional_tags, {
    Name = "${var.project_name}-${each.value}-endpoint"
  })
}

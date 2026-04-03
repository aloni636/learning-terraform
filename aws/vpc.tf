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
# NOTE[PRICING]: NAT for each AZ is more resilient but costs ~32$ per AZ plus 0.05$ per GB data processing cost
#       Which is actually 2.5x higher than cross AZ data transfers (accounting for per direction cost)
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

# ----- Private Subnet SSM Network Interface Endpoints ----- #
/* NOTE[PRICING]: Interface endpoints are actually quite expensive, and because SSM
   requires 3 services, and each endpoint must reside within each AZ, we get this
   wonderful pricing formula: 3 x AZ 
   With the bulk of the pricing being on flat per hour per AZ, each AZ SSM costs around 3*(0.01$*24*30) = 21.6$
   See: https://aws.amazon.com/privatelink/pricing/#:~:text=source%20or%20destination.-,Interface%20Endpoint%20pricing,-You%20can%20use */
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

# ----- S3 Endpoint ----- #
# See: https://docs.aws.amazon.com/AmazonS3/latest/userguide/example-bucket-policies-vpc-endpoint.html?utm_source=chatgpt.com
resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = values(aws_route_table.private_route_tables)[*].id

  tags = merge(local.additional_tags, {
    Name = "${var.project_name}-s3-gateway-endpoint"
  })
}

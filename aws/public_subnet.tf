# Gateways (which are AZ agnostic) don't have a lot of config
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "igw"
  }
}

# ----- Subnets ----- #
resource "aws_subnet" "public_subnets" {
  for_each = local.public_azs

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = each.value.public_cidr
  availability_zone = each.key

  map_public_ip_on_launch = true # Defaults to false

  tags = {
    Name = "public-subnet-${each.key}"
  }
}

# ----- Public Route Table Shared Across AZs ----- #
# NOTE: A public route table is basically an all traffic route rule to internet gateway, so it can be shared across all AZs
resource "aws_route_table" "public_route_table" {
  count = local.has_public_subnets ? 1 : 0

  vpc_id = aws_vpc.vpc.id

  # Route every destination (apart from local IPs, i.e. 10.0.0.0/17) to the internet
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public_subnet_route_association" {
  for_each = local.public_azs

  subnet_id      = aws_subnet.public_subnets[each.key].id
  route_table_id = aws_route_table.public_route_table[0].id
}

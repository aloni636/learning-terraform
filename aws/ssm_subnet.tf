resource "aws_subnet" "ssm" {
  for_each = var.availability_zones

  vpc_id               = aws_vpc.vpc.id
  cidr_block           = each.value.ssm_cidr
  availability_zone_id = each.key

  tags = merge(local.additional_tags, {
    "Name" = "${var.project_name}-rds-subnet-${each.key}"
  })
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
  subnet_ids         = values(aws_subnet.ssm)[*].id
  security_group_ids = [aws_security_group.allow_inbound_ssm.id]
  # We need DNS to make sure the public SSM service IP gets translated to a private IP within the subnet
  private_dns_enabled = true

  tags = merge(local.additional_tags, {
    Name = "${var.project_name}-${each.value}-endpoint"
  })
}
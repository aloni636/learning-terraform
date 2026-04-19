/* NOTE: Every subnet has a route table. One without an explicit route table gets associated
   with a default one which maps the entire VPC cidr block to local, i.e. `10.0.0.0/16: local` */
resource "aws_subnet" "rds" {
  for_each = local.rds_azs

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = each.value.rds_cidr
  availability_zone = each.key

  tags = {
    Name = "rds-subnet-${each.key}"
  }
}

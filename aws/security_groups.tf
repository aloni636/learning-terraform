# ----- Public Instances SGs ----- #
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
  ip_protocol       = "-1" # semantically equivalent to all protocols

  tags = merge(local.additional_tags, {
    "Name" = "${var.project_name}-allow-all-outbound-ipv4-rule"
  })
}


# ----- Private SSM SGs ----- #
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


# ----- Private S3 Access SGs ----- #
resource "aws_security_group" "allow_outbound_s3" {
  name        = "allow_outbound_s3"
  description = "Allow HTTPS from private instances to S3 gateway endpoint"
  vpc_id      = aws_vpc.vpc.id

  tags = merge(local.additional_tags, {
    Name = "${var.project_name}-allow-inbound-s3"
  })
}

# See: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule#usage-with-prefix-list-ids
resource "aws_vpc_security_group_egress_rule" "allow_outbound_s3_gateway" {
  # S3 Gateway interfaces are implemented at the routing level which means we
  # can avoid the metered billing of a VPC endpoint interface by allowing
  # outbound traffic to the public IP ranges, which will be routed through
  # the Gateway interface:
  # https://docs.aws.amazon.com/AmazonS3/latest/userguide/privatelink-interface-endpoints.html
  security_group_id = aws_security_group.allow_outbound_s3.id
  description       = "S3 Gateway Egress"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  # The CIDR blocks dedicated to S3 services, accessible from the gateway
  prefix_list_id = data.aws_prefix_list.s3.id
}

# ----- Private RDS SGs ----- #
resource "aws_security_group" "outbound_rds" {
  name        = "outbound_rds"
  description = "Allow outbound HTTPS from instances to RDS endpoints"
  vpc_id      = aws_vpc.vpc.id

  tags = merge(local.additional_tags, {
    Name = "${var.project_name}-allow-outbound-rds"
  })
}

resource "aws_vpc_security_group_egress_rule" "outbound_rds_rule" {
  security_group_id            = aws_security_group.outbound_rds.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.inbound_rds.id

  tags = local.additional_tags
}

resource "aws_security_group" "inbound_rds" {
  name        = "inbound_rds"
  description = "Allow inbound HTTPS from instances to RDS endpoints"
  vpc_id      = aws_vpc.vpc.id

  tags = merge(local.additional_tags, {
    Name = "${var.project_name}-allow-inbound-rds"
  })
}

resource "aws_vpc_security_group_ingress_rule" "inbound_rds_rule" {
  security_group_id            = aws_security_group.inbound_rds.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.outbound_rds.id

  tags = merge(local.additional_tags, {
    Name = "${var.project_name}-allow-inbound-rds-rule"
  })
}

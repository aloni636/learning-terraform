locals {
  # jsonencode is the recommended way to define roles
  STS_EC2_ASSUME_ROLE_POLICY = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  SSM_POLICY_ARN = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ----- Private EC2 Role ----- #
# See: https://docs.aws.amazon.com/systems-manager/latest/userguide/setup-instance-permissions.html#instance-profile-add-permissions
resource "aws_iam_role" "private_ec2" {
  name = "${var.project_name}-private-ec2-role"

  assume_role_policy = local.STS_EC2_ASSUME_ROLE_POLICY
  tags = {
    Name = "private-ec2-role"
  }
}

resource "aws_iam_role_policy_attachment" "private_ec2" {
  for_each = {
    ssm = local.SSM_POLICY_ARN,
    s3  = aws_iam_policy.s3_read_write_policy.arn
  }
  role       = aws_iam_role.private_ec2.name
  policy_arn = each.value
}


# A profile which can be attached to EC2 instances
resource "aws_iam_instance_profile" "private_ec2_profile" {
  name = "${var.project_name}-private-ec2-profile"
  role = aws_iam_role.private_ec2.name

  tags = {
    Name = "private-ec2-profile"
  }
}


# ----- SSM Bastion Role ----- #
resource "aws_iam_role" "bastion" {
  name = "bastion-role"

  # jsonencode is the recommended way to define roles
  assume_role_policy = local.STS_EC2_ASSUME_ROLE_POLICY
  tags = {
    Name = "bastion-role"
  }
}

resource "aws_iam_role_policy_attachment" "bastion" {
  for_each   = { ssm = local.SSM_POLICY_ARN }
  role       = aws_iam_role.bastion.name
  policy_arn = each.value
}

# A profile which can be attached to EC2 instances
resource "aws_iam_instance_profile" "bastion_profile" {
  name = "${var.project_name}-bastion-profile"
  role = aws_iam_role.bastion.name

  tags = {
    Name = "bastion-profile"
  }
}

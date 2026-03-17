# See: https://docs.aws.amazon.com/systems-manager/latest/userguide/setup-instance-permissions.html#instance-profile-add-permissions
resource "aws_iam_role" "ec2_ssm_role" {
  name = "${var.project_name}-ec2-ssm-role"

  # jsonencode is the recommended way to define roles
  assume_role_policy = jsonencode({
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
  tags = merge(local.additional_tags, {
    "Name" = "${var.project_name}-ec2-ssm-role"
  })
}

# A policy which dictates that EC2 instances can communicate with SSM
resource "aws_iam_role_policy_attachment" "ec2_ssm_core" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# A profile which can be attached to EC2 instances
resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "${var.project_name}-ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm_role.name

  tags = merge(local.additional_tags, {
    "Name" = "${var.project_name}-ec2-ssm-profile"
  })
}


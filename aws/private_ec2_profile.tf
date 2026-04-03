# See: https://docs.aws.amazon.com/systems-manager/latest/userguide/setup-instance-permissions.html#instance-profile-add-permissions
resource "aws_iam_role" "private_ec2_role" {
  name = "${var.project_name}-private-ec2-role"

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
    "Name" = "${var.project_name}-private-ec2-role"
  })
}

# A policy which dictates that EC2 instances can communicate with SSM
resource "aws_iam_role_policy_attachment" "ec2_ssm_core_policy_attachment" {
  role       = aws_iam_role.private_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


/* See: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_grammar.html
        https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-policy-language-overview.html */
resource "aws_iam_policy" "s3_read_write_policy" {
  name = "${var.project_name}-s3-read_write-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = "${aws_s3_bucket.s3_bucket.arn}"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.s3_bucket.arn}/*"
      }
    ]
  })

  tags = merge(local.additional_tags, {
    "Name" = "${var.project_name}-s3-read_write-policy"
  })
}

resource "aws_iam_role_policy_attachment" "ec2_s3_iam_attachment" {
  role       = aws_iam_role.private_ec2_role.id
  policy_arn = aws_iam_policy.s3_read_write_policy.arn
}

# A profile which can be attached to EC2 instances
resource "aws_iam_instance_profile" "private_ec2_profile" {
  name = "${var.project_name}-private-ec2-profile"
  role = aws_iam_role.private_ec2_role.name

  tags = merge(local.additional_tags, {
    "Name" = "${var.project_name}-private-ec2-profile"
  })
}

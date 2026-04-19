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

  tags = {
    Name = "s3-read_write-policy"
  }
}
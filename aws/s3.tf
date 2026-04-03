# Secure, least-privilege-approach, S3 private bucket
# Accessible only from the private subnet by EC2 instances with 's3_read_write_policy' IAM policy
resource "aws_s3_bucket" "s3_bucket" {
  bucket        = var.s3_bucket_name
  force_destroy = true # WARNING: This flag will lead to data loss if terraform destroys this bucket!

  tags = merge(local.additional_tags, {
    "Name" = "${var.project_name}-s3-bucket"
  })
}

# See: https://registry.terraform.io/providers/-/aws/latest/docs/resources/s3_bucket_public_access_block#example-usage
resource "aws_s3_bucket_public_access_block" "s3_bucket_no_public_access_policy" {
  bucket = aws_s3_bucket.s3_bucket.id

  block_public_acls       = true # NACLs; will be relevant later on
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Allow access only from my VPC

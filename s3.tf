# Random suffix for globally unique S3 bucket name
resource "random_id" "suffix" {
  byte_length = 4
}

# S3 — free plan: 5 GB standard storage, 20K GET, 2K PUT/month
# ⚠️ Storing more than 5 GB incurs standard S3 charges
# ⚠️ Enabling versioning causes each version to count toward the 5 GB limit

resource "aws_s3_bucket" "assets" {
  bucket = "${var.name}-assets-${random_id.suffix.hex}"

  tags = merge(var.tags, {
    Name = "${var.name}-assets"
  })
}

# Block all public access — CloudFront OAC is used for serving content
resource "aws_s3_bucket_public_access_block" "assets" {
  bucket = aws_s3_bucket.assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# AES256 server-side encryption (SSE-S3, free)
# ⚠️ Using aws:kms would incur KMS charges
resource "aws_s3_bucket_server_side_encryption_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Versioning disabled — each version counts toward the 5 GB free quota
resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id

  versioning_configuration {
    status = "Disabled"
  }
}

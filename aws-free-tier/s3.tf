# Random suffix for globally unique S3 bucket name.
resource "random_id" "suffix" {
  byte_length = 4
}

# S3 — terraform-aws-modules/s3-bucket
# Free tier: 5 GB of S3 Standard storage, 20,000 GET requests, 2,000 PUT requests (12-month).
# ⚠️ Enabling versioning causes each version to count toward the 5 GB limit
# ⚠️ Storing more than 5 GB will incur standard S3 charges
module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket = "${var.project_name}-assets-${random_id.suffix.hex}"

  # Block all public access — security best practice
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # AES256 server-side encryption (SSE-S3, free)
  # ⚠️ Using aws:kms encryption may incur KMS charges
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  # Versioning disabled — each version counts toward the 5 GB free quota
  versioning = {
    enabled = false
  }

  tags = {
    Name = "${var.project_name}-assets"
  }
}

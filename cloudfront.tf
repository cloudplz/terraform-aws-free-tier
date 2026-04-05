# CloudFront — always free: 1 TB data out + 10M HTTP requests/month
# Fronts the S3 assets bucket using Origin Access Control (OAC).
# ⚠️ Do NOT add web_acl_id — WAF is not free
# ⚠️ price_class = "PriceClass_All" routes to all edge locations; PriceClass_100 is cheaper beyond free tier

data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

resource "aws_cloudfront_origin_access_control" "assets" {
  for_each = var.features.cloudfront ? { this = {} } : {}

  name                              = "${var.name}-oac"
  description                       = "OAC for ${var.name} S3 assets"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "assets" {
  for_each = var.features.cloudfront ? { this = {} } : {}

  enabled             = true
  default_root_object = "index.html"
  comment             = "${var.name} assets distribution"
  price_class         = "PriceClass_100" # US, Canada, Europe — cheaper beyond free tier

  origin {
    domain_name              = aws_s3_bucket.assets.bucket_regional_domain_name
    origin_id                = "s3-${aws_s3_bucket.assets.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.assets["this"].id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-${aws_s3_bucket.assets.id}"
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  # ⚠️ Do NOT add web_acl_id — WAF is not free

  tags = merge(var.tags, {
    Name = "${var.name}-distribution"
  })
}

# Grant CloudFront OAC permission to read from the S3 bucket
resource "aws_s3_bucket_policy" "cloudfront_access" {
  for_each = var.features.cloudfront ? { this = {} } : {}

  bucket = aws_s3_bucket.assets.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudFrontServicePrincipal"
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.assets.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.assets["this"].arn
        }
      }
    }]
  })

  # Ensure public access block is applied before the bucket policy
  depends_on = [aws_s3_bucket_public_access_block.assets]
}

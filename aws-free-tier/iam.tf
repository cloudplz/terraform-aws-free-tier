# IAM — terraform-aws-modules/iam
# Free tier: IAM is always free. No charges for users, roles, or policies.

# IAM policy granting S3 access to the assets bucket.
# Follows least-privilege: only the specific bucket and objects within it.
module "iam_policy_s3_access" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 5.0"

  name        = "${var.project_name}-s3-access"
  description = "Allow EC2 to read/write objects in the ${var.project_name} assets bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3BucketAccess"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = module.s3_bucket.s3_bucket_arn
      },
      {
        Sid    = "S3ObjectAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${module.s3_bucket.s3_bucket_arn}/*"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-s3-access"
  }
}

# IAM role for EC2, trusted by ec2.amazonaws.com.
module "iam_assumable_role_ec2" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 5.0"

  role_name         = "${var.project_name}-ec2-role"
  create_role       = true
  role_requires_mfa = false

  trusted_role_services = ["ec2.amazonaws.com"]

  custom_role_policy_arns = [
    module.iam_policy_s3_access.arn
  ]
}

# Instance profile wrapping the IAM role for attachment to EC2.
resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-ec2-profile"
  role = module.iam_assumable_role_ec2.iam_role_name
}

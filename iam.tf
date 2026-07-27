# IAM — always free. No charges for roles, policies, or instance profiles.

# ────────────────────────────────────────────────
# EC2 Role (gated by features.compute)
# ────────────────────────────────────────────────

resource "aws_iam_role" "ec2" {
  for_each = var.features.compute ? { this = {} } : {}

  name = "${var.name}-ec2-role"
  tags = local.common_tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "s3_access" {
  for_each = var.features.compute && var.features.storage ? { this = {} } : {}

  name        = "${var.name}-s3-access"
  description = "Allow EC2 to read/write objects in the ${var.name} assets bucket"
  tags        = local.common_tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "S3BucketList"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = aws_s3_bucket.assets["this"].arn
      },
      {
        Sid      = "S3ObjectAccess"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "${aws_s3_bucket.assets["this"].arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_s3" {
  for_each = var.features.compute && var.features.storage ? { this = {} } : {}

  role       = aws_iam_role.ec2["this"].name
  policy_arn = aws_iam_policy.s3_access["this"].arn
}

# SSM Session Manager — enables shell access without SSH keys or open ports
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  for_each = var.features.compute ? { this = {} } : {}

  role       = aws_iam_role.ec2["this"].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  for_each = var.features.compute ? { this = {} } : {}

  name = "${var.name}-ec2-profile"
  role = aws_iam_role.ec2["this"].name
  tags = local.common_tags
}

# ────────────────────────────────────────────────
# Lambda Execution Role (gated by features.serverless)
# ────────────────────────────────────────────────

resource "aws_iam_role" "lambda" {
  for_each = var.features.serverless ? { this = {} } : {}

  name = "${var.name}-lambda-role"
  tags = local.common_tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  for_each = var.features.serverless ? { this = {} } : {}

  role       = aws_iam_role.lambda["this"].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ────────────────────────────────────────────────
# EventBridge Scheduler Role (gated by features.serverless)
# ────────────────────────────────────────────────

resource "aws_iam_role" "scheduler" {
  for_each = var.features.serverless ? { this = {} } : {}

  name = "${var.name}-scheduler-role"
  tags = local.common_tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "scheduler.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "scheduler_invoke_lambda" {
  for_each = var.features.serverless ? { this = {} } : {}

  name = "${var.name}-scheduler-invoke-lambda"
  tags = local.common_tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["lambda:InvokeFunction"]
      Resource = aws_lambda_function.handler["this"].arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "scheduler_lambda" {
  for_each = var.features.serverless ? { this = {} } : {}

  role       = aws_iam_role.scheduler["this"].name
  policy_arn = aws_iam_policy.scheduler_invoke_lambda["this"].arn
}

# ────────────────────────────────────────────────
# Step Functions Role (gated by features.step_functions)
# ────────────────────────────────────────────────

resource "aws_iam_role" "sfn" {
  for_each = var.features.step_functions ? { this = {} } : {}

  name = "${var.name}-sfn-role"
  tags = local.common_tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "states.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "sfn_invoke_lambda" {
  for_each = var.features.step_functions ? { this = {} } : {}

  name = "${var.name}-sfn-invoke-lambda"
  tags = local.common_tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["lambda:InvokeFunction"]
      Resource = aws_lambda_function.handler["this"].arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "sfn_lambda" {
  for_each = var.features.step_functions ? { this = {} } : {}

  role       = aws_iam_role.sfn["this"].name
  policy_arn = aws_iam_policy.sfn_invoke_lambda["this"].arn
}

# ────────────────────────────────────────────────
# Bedrock Logging Role (gated by features.bedrock_logging)
# ────────────────────────────────────────────────

resource "aws_iam_role" "bedrock_logging" {
  for_each = var.features.bedrock_logging ? { this = {} } : {}

  name = "${var.name}-bedrock-logging-role"
  tags = local.common_tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "bedrock.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "bedrock_logging" {
  for_each = var.features.bedrock_logging ? { this = {} } : {}

  name = "${var.name}-bedrock-logging"
  tags = local.common_tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams",
      ]
      Resource = "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/${var.name}/bedrock:*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "bedrock_logging" {
  for_each = var.features.bedrock_logging ? { this = {} } : {}

  role       = aws_iam_role.bedrock_logging["this"].name
  policy_arn = aws_iam_policy.bedrock_logging["this"].arn
}

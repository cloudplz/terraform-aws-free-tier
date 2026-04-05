# IAM — always free. No charges for roles, policies, or instance profiles.

# ────────────────────────────────────────────────
# EC2 Role (always created)
# ────────────────────────────────────────────────

resource "aws_iam_role" "ec2" {
  name = "${var.project_name}-ec2-role"

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
  name        = "${var.project_name}-s3-access"
  description = "Allow EC2 to read/write objects in the ${var.project_name} assets bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "S3BucketList"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = aws_s3_bucket.assets.arn
      },
      {
        Sid      = "S3ObjectAccess"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "${aws_s3_bucket.assets.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_s3" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.s3_access.arn
}

# SSM Session Manager — enables shell access without SSH keys or open ports
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2.name
}

# ────────────────────────────────────────────────
# Lambda Execution Role (always created)
# ────────────────────────────────────────────────

resource "aws_iam_role" "lambda" {
  name = "${var.project_name}-lambda-role"

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
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ────────────────────────────────────────────────
# EventBridge Scheduler Role (always created)
# ────────────────────────────────────────────────

resource "aws_iam_role" "scheduler" {
  name = "${var.project_name}-scheduler-role"

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
  name = "${var.project_name}-scheduler-invoke-lambda"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["lambda:InvokeFunction"]
      Resource = aws_lambda_function.handler.arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "scheduler_lambda" {
  role       = aws_iam_role.scheduler.name
  policy_arn = aws_iam_policy.scheduler_invoke_lambda.arn
}

# ────────────────────────────────────────────────
# Step Functions Role (gated by features.step_functions)
# ────────────────────────────────────────────────

resource "aws_iam_role" "sfn" {
  for_each = var.features.step_functions ? { this = {} } : {}

  name = "${var.project_name}-sfn-role"

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

  name = "${var.project_name}-sfn-invoke-lambda"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["lambda:InvokeFunction"]
      Resource = aws_lambda_function.handler.arn
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

  name = "${var.project_name}-bedrock-logging-role"

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

  name = "${var.project_name}-bedrock-logging"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams",
      ]
      Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/${var.project_name}/bedrock:*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "bedrock_logging" {
  for_each = var.features.bedrock_logging ? { this = {} } : {}

  role       = aws_iam_role.bedrock_logging["this"].name
  policy_arn = aws_iam_policy.bedrock_logging["this"].arn
}

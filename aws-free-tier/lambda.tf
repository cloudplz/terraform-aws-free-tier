# Lambda placeholder source code — inline via archive_file data source.
data "archive_file" "lambda_placeholder" {
  type        = "zip"
  output_path = "${path.module}/.build/lambda.zip"

  source {
    content  = "exports.handler = async (e) => ({ statusCode: 200, body: 'ok' });"
    filename = "index.mjs"
  }
}

# Lambda — terraform-aws-modules/lambda
# Free tier (always free): 1M requests/month + 400,000 GB-seconds/month.
# memory_size = 128 MB maximizes the number of free GB-seconds
# (128 MB × 3,200,000 seconds = 400,000 GB-seconds).
# ⚠️ Increasing memory_size reduces the free seconds proportionally
# ⚠️ timeout > 10 increases the risk of long-running invocations eating free quota
module "lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 7.0"

  function_name = "${var.project_name}-handler"
  description   = "Placeholder Lambda function for ${var.project_name}"
  handler       = "index.handler"
  runtime       = "nodejs22.x" # Current active LTS as of 2026

  memory_size = 128 # Minimum — maximizes free tier GB-seconds
  timeout     = 10  # ⚠️ Higher timeout risks consuming free quota on runaway invocations

  create_package = false
  local_existing_package = data.archive_file.lambda_placeholder.output_path

  environment_variables = {
    DB_HOST = module.rds.db_instance_address
    DB_NAME = module.rds.db_instance_name
    DB_USER = var.db_username
  }

  tags = {
    Name = "${var.project_name}-handler"
  }
}

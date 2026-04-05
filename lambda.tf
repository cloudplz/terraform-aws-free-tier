# Lambda placeholder source code — inline via archive_file data source
data "archive_file" "lambda_placeholder" {
  type        = "zip"
  output_path = "${path.module}/.build/lambda.zip"

  source {
    content  = "export const handler = async (e) => ({ statusCode: 200, body: JSON.stringify({ message: 'ok', event: e }) });"
    filename = "index.mjs"
  }
}

# Lambda — always free: 1M requests/month + 400K GB-seconds/month
# memory_size = 128 MB maximizes free GB-seconds (128 MB × 3.2M sec = 400K GB-sec)
# ⚠️ Increasing memory_size reduces the free seconds proportionally
# ⚠️ timeout > 10 risks consuming free quota on runaway invocations

resource "aws_lambda_function" "handler" {
  function_name    = "${var.project_name}-handler"
  description      = "Placeholder Lambda function for ${var.project_name}"
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  role             = aws_iam_role.lambda.arn
  filename         = data.archive_file.lambda_placeholder.output_path
  source_code_hash = data.archive_file.lambda_placeholder.output_base64sha256

  memory_size = 128  # Minimum — maximizes free tier GB-seconds
  timeout     = 10   # ⚠️ Higher timeout risks consuming free quota

  tags = {
    Name = "${var.project_name}-handler"
  }
}

# Lambda Function URL — required for the $20 Lambda credit activity
# Provides a dedicated HTTPS endpoint without needing API Gateway
# authorization_type = "NONE" makes it publicly invocable — demo/study use only
resource "aws_lambda_function_url" "handler" {
  function_name      = aws_lambda_function.handler.function_name
  authorization_type = "NONE"
}

# Required for public Function URL access when using Terraform (console adds this automatically)
# Without this, the Function URL returns 403 even with authorization_type = "NONE"
resource "aws_lambda_permission" "function_url_public" {
  statement_id           = "AllowPublicFunctionURL"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.handler.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}

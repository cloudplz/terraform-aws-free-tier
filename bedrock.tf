# Bedrock — model invocation logging configuration
# ⚠️ Bedrock model inference is NOT free — you pay per token/request
# ⚠️ This file configures the logging INFRASTRUCTURE around Bedrock (free)
#
# To earn the $20 Bedrock credit activity:
#   1. In the AWS Console → Bedrock → Model access → Manage model access
#   2. Enable a model (e.g., Amazon Nova Lite — low cost for testing)
#   3. Go to Bedrock → Playgrounds → Text
#   4. Submit any prompt (e.g., "Hello, what is 2+2?")
#   Your $20 credit will appear in Billing → Credits within ~10 minutes.
#
# ⚠️ aws_bedrock_model_invocation_logging_configuration is a singleton per account/region.
#    If one already exists outside this Terraform state, import it first:
#    terraform import aws_bedrock_model_invocation_logging_configuration.main["this"] .

resource "aws_bedrock_model_invocation_logging_configuration" "main" {
  for_each = var.features.bedrock_logging ? { this = {} } : {}

  logging_config {
    cloudwatch_config {
      log_group_name = aws_cloudwatch_log_group.bedrock["this"].name
      role_arn       = aws_iam_role.bedrock_logging["this"].arn
    }

    text_data_delivery_enabled      = true  # Log text model invocations
    image_data_delivery_enabled     = false # Skip image model logs
    embedding_data_delivery_enabled = false # Skip embedding logs
  }
}

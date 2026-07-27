# State migration for v1.1.0 — resources that gained for_each in v1.1.0.
# These moved blocks let existing deployments upgrade without destroy/recreate.
# Safe to remove in a future major version once users have upgraded past v1.1.0.

# ─── Compute (features.compute) ──────────────────────────────────────────────

moved {
  from = aws_instance.web
  to   = aws_instance.web["this"]
}

moved {
  from = aws_security_group.ec2
  to   = aws_security_group.ec2["this"]
}

moved {
  from = aws_iam_role.ec2
  to   = aws_iam_role.ec2["this"]
}

moved {
  from = aws_iam_policy.s3_access
  to   = aws_iam_policy.s3_access["this"]
}

moved {
  from = aws_iam_role_policy_attachment.ec2_s3
  to   = aws_iam_role_policy_attachment.ec2_s3["this"]
}

moved {
  from = aws_iam_role_policy_attachment.ec2_ssm
  to   = aws_iam_role_policy_attachment.ec2_ssm["this"]
}

moved {
  from = aws_iam_instance_profile.ec2
  to   = aws_iam_instance_profile.ec2["this"]
}

moved {
  from = aws_cloudwatch_metric_alarm.ec2_cpu_high
  to   = aws_cloudwatch_metric_alarm.ec2_cpu_high["this"]
}

# ─── Storage (features.storage) ──────────────────────────────────────────────

moved {
  from = aws_s3_bucket.assets
  to   = aws_s3_bucket.assets["this"]
}

moved {
  from = aws_s3_bucket_public_access_block.assets
  to   = aws_s3_bucket_public_access_block.assets["this"]
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.assets
  to   = aws_s3_bucket_server_side_encryption_configuration.assets["this"]
}

moved {
  from = aws_s3_bucket_versioning.assets
  to   = aws_s3_bucket_versioning.assets["this"]
}

moved {
  from = aws_dynamodb_table.main
  to   = aws_dynamodb_table.main["this"]
}

# ─── Messaging (features.messaging) ──────────────────────────────────────────

moved {
  from = aws_sns_topic.alerts
  to   = aws_sns_topic.alerts["this"]
}

moved {
  from = aws_sqs_queue.dlq
  to   = aws_sqs_queue.dlq["this"]
}

moved {
  from = aws_sqs_queue.main
  to   = aws_sqs_queue.main["this"]
}

moved {
  from = aws_sqs_queue_redrive_policy.main
  to   = aws_sqs_queue_redrive_policy.main["this"]
}

# ─── Serverless (features.serverless) ────────────────────────────────────────

moved {
  from = aws_lambda_function.handler
  to   = aws_lambda_function.handler["this"]
}

moved {
  from = aws_lambda_function_url.handler
  to   = aws_lambda_function_url.handler["this"]
}

moved {
  from = aws_lambda_permission.function_url_public
  to   = aws_lambda_permission.function_url_public["this"]
}

moved {
  from = aws_lambda_permission.api_gateway
  to   = aws_lambda_permission.api_gateway["this"]
}

moved {
  from = aws_apigatewayv2_api.main
  to   = aws_apigatewayv2_api.main["this"]
}

moved {
  from = aws_apigatewayv2_stage.default
  to   = aws_apigatewayv2_stage.default["this"]
}

moved {
  from = aws_apigatewayv2_integration.lambda
  to   = aws_apigatewayv2_integration.lambda["this"]
}

moved {
  from = aws_apigatewayv2_route.default
  to   = aws_apigatewayv2_route.default["this"]
}

moved {
  from = aws_scheduler_schedule.lambda_ping
  to   = aws_scheduler_schedule.lambda_ping["this"]
}

moved {
  from = aws_iam_role.lambda
  to   = aws_iam_role.lambda["this"]
}

moved {
  from = aws_iam_role_policy_attachment.lambda_basic
  to   = aws_iam_role_policy_attachment.lambda_basic["this"]
}

moved {
  from = aws_iam_role.scheduler
  to   = aws_iam_role.scheduler["this"]
}

moved {
  from = aws_iam_policy.scheduler_invoke_lambda
  to   = aws_iam_policy.scheduler_invoke_lambda["this"]
}

moved {
  from = aws_iam_role_policy_attachment.scheduler_lambda
  to   = aws_iam_role_policy_attachment.scheduler_lambda["this"]
}

moved {
  from = aws_cloudwatch_log_group.lambda
  to   = aws_cloudwatch_log_group.lambda["this"]
}

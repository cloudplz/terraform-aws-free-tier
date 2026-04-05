# ─── Compute ───

output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS hostname of the EC2 instance"
  value       = aws_instance.web.public_dns
}

# ─── Database ───

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint (host:port)"
  value       = "${aws_db_instance.postgres.address}:${aws_db_instance.postgres.port}"
}

output "rds_db_name" {
  description = "Name of the RDS database"
  value       = aws_db_instance.postgres.db_name
}

output "elasticache_endpoint" {
  description = "ElastiCache Redis endpoint (host:port)"
  value       = "${aws_elasticache_cluster.redis.cache_nodes[0].address}:${aws_elasticache_cluster.redis.cache_nodes[0].port}"
}

# ─── Storage ───

output "s3_bucket_name" {
  description = "Name of the S3 assets bucket"
  value       = aws_s3_bucket.assets.id
}

output "cloudfront_domain" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.assets.domain_name
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.main.id
}

# ─── Serverless ───

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.handler.function_name
}

output "lambda_function_url" {
  description = "Lambda Function URL — public HTTPS endpoint (credit activity)"
  value       = aws_lambda_function_url.handler.function_url
}

output "api_gateway_url" {
  description = "API Gateway HTTP API invoke URL"
  value       = aws_apigatewayv2_stage.default.invoke_url
}

# ─── Messaging / Events ───

output "sqs_queue_url" {
  description = "URL of the SQS main queue"
  value       = aws_sqs_queue.main.url
}

output "sns_topic_arn" {
  description = "ARN of the SNS alerts topic"
  value       = aws_sns_topic.alerts.arn
}

output "step_functions_arn" {
  description = "ARN of the Step Functions state machine"
  value       = aws_sfn_state_machine.main.arn
}

# ─── Auth ───

output "cognito_user_pool_id" {
  description = "ID of the Cognito User Pool"
  value       = aws_cognito_user_pool.main.id
}

output "cognito_client_id" {
  description = "ID of the Cognito App Client"
  value       = aws_cognito_user_pool_client.main.id
}

output "cognito_hosted_ui_url" {
  description = "Cognito hosted sign-in UI URL"
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${var.aws_region}.amazoncognito.com"
}

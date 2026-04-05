# ─── Compute (always created) ─────────────────────────────────────────────────

output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS hostname of the EC2 instance"
  value       = aws_instance.web.public_dns
}

# ─── Database ─────────────────────────────────────────────────────────────────

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint (host:port), or null when features.rds is false"
  value = nonsensitive(try(
    "${one(values(aws_db_instance.postgres)).address}:${one(values(aws_db_instance.postgres)).port}",
    null
  ))
}

output "rds_db_name" {
  description = "Name of the RDS database, or null when features.rds is false"
  value       = nonsensitive(try(one(values(aws_db_instance.postgres)).db_name, null))
}

output "rds_secret_arn" {
  description = "ARN of the RDS Secrets Manager secret, or null when features.rds is false"
  value       = nonsensitive(try(one(values(aws_secretsmanager_secret.rds)).arn, null))
}

output "aurora_endpoint" {
  description = "Aurora PostgreSQL cluster writer endpoint, or null when features.aurora is false"
  value       = nonsensitive(try(one(values(aws_rds_cluster.aurora)).endpoint, null))
}

output "aurora_reader_endpoint" {
  description = "Aurora PostgreSQL cluster reader endpoint, or null when features.aurora is false"
  value       = nonsensitive(try(one(values(aws_rds_cluster.aurora)).reader_endpoint, null))
}

output "aurora_secret_arn" {
  description = "ARN of the Aurora Secrets Manager secret, or null when features.aurora is false"
  value       = nonsensitive(try(one(values(aws_secretsmanager_secret.aurora)).arn, null))
}

output "elasticache_endpoint" {
  description = "ElastiCache Valkey endpoint (host:port), or null when features.elasticache is false"
  value = nonsensitive(try(
    "${one(values(aws_elasticache_cluster.valkey)).cache_nodes[0].address}:${one(values(aws_elasticache_cluster.valkey)).cache_nodes[0].port}",
    null
  ))
}

output "elasticache_secret_arn" {
  description = "ARN of the ElastiCache Secrets Manager secret, or null when features.elasticache is false"
  value       = nonsensitive(try(one(values(aws_secretsmanager_secret.elasticache)).arn, null))
}

output "valkey_engine_version" {
  description = "Valkey engine version deployed to ElastiCache, or null when features.elasticache is false"
  value       = nonsensitive(try(one(values(aws_elasticache_cluster.valkey)).engine_version, null))
}

# ─── Storage (always created) ─────────────────────────────────────────────────

output "s3_bucket_name" {
  description = "Name of the S3 assets bucket"
  value       = aws_s3_bucket.assets.id
}

output "cloudfront_domain" {
  description = "CloudFront distribution domain name, or null when features.cloudfront is false"
  value       = try(one(values(aws_cloudfront_distribution.assets)).domain_name, null)
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.main.id
}

# ─── Serverless (always created) ──────────────────────────────────────────────

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

# ─── Messaging / Events (always created) ──────────────────────────────────────

output "sqs_queue_url" {
  description = "URL of the SQS main queue"
  value       = aws_sqs_queue.main.url
}

output "sns_topic_arn" {
  description = "ARN of the SNS alerts topic"
  value       = aws_sns_topic.alerts.arn
}

output "step_functions_arn" {
  description = "ARN of the Step Functions state machine, or null when features.step_functions is false"
  value       = try(one(values(aws_sfn_state_machine.main)).arn, null)
}

# ─── Auth ─────────────────────────────────────────────────────────────────────

output "cognito_user_pool_id" {
  description = "ID of the Cognito User Pool, or null when features.cognito is false"
  value       = try(one(values(aws_cognito_user_pool.main)).id, null)
}

output "cognito_client_id" {
  description = "ID of the Cognito App Client, or null when features.cognito is false"
  value       = try(one(values(aws_cognito_user_pool_client.main)).id, null)
}

output "cognito_domain" {
  description = "Cognito hosted domain URL, or null when features.cognito is false"
  value = try(
    "https://${one(values(aws_cognito_user_pool_domain.main)).domain}.auth.${var.aws_region}.amazoncognito.com",
    null
  )
}

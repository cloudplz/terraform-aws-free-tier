output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = module.free_tier.ec2_public_ip
}

output "lambda_function_url" {
  description = "Lambda Function URL (credit activity)"
  value       = module.free_tier.lambda_function_url
}

output "api_gateway_url" {
  description = "API Gateway HTTP API invoke URL"
  value       = module.free_tier.api_gateway_url
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = module.free_tier.rds_endpoint
}

output "aurora_endpoint" {
  description = "Aurora PostgreSQL endpoint"
  value       = module.free_tier.aurora_endpoint
}

output "elasticache_endpoint" {
  description = "ElastiCache Valkey endpoint"
  value       = module.free_tier.elasticache_endpoint
}

output "s3_bucket_name" {
  description = "S3 assets bucket name"
  value       = module.free_tier.s3_bucket_name
}

output "cloudfront_domain" {
  description = "CloudFront distribution domain"
  value       = module.free_tier.cloudfront_domain
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = module.free_tier.dynamodb_table_name
}

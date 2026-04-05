output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = module.ec2.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS hostname of the EC2 instance"
  value       = module.ec2.public_dns
}

output "rds_endpoint" {
  description = "RDS endpoint in host:port format"
  value       = "${module.rds.db_instance_address}:${module.rds.db_instance_port}"
}

output "rds_db_name" {
  description = "Name of the RDS database"
  value       = module.rds.db_instance_name
}

output "s3_bucket_name" {
  description = "Name of the S3 assets bucket"
  value       = module.s3_bucket.s3_bucket_id
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.lambda.lambda_function_name
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = module.dynamodb_table.dynamodb_table_id
}

output "sqs_queue_url" {
  description = "URL of the SQS main queue"
  value       = module.sqs.queue_url
}

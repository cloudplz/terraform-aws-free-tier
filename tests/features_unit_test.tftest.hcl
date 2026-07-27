# Feature toggle tests — plan mode, mock providers.
# Verifies that feature flags correctly control resource creation.

mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = {
      names    = ["us-east-1a", "us-east-1b", "us-east-1c"]
      zone_ids = ["use1-az1", "use1-az2", "use1-az3"]
    }
  }
}
mock_provider "archive" {}

variables {
  name               = "test"
  my_ip_cidr         = "203.0.113.42/32"
  notification_email = "test@example.com"
}

# ─── Disable RDS ─────────────────────────────────────────────────────────────

run "rds_disabled_removes_resources" {
  command = plan

  variables {
    features = {
      rds = false
    }
  }

  assert {
    condition     = length(aws_db_instance.postgres) == 0
    error_message = "RDS instance should not be created when features.rds is false"
  }

  assert {
    condition     = length(aws_secretsmanager_secret.rds) == 0
    error_message = "RDS secret should not be created when features.rds is false"
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.rds_low_storage) == 0
    error_message = "RDS storage alarm should not be created when features.rds is false"
  }
}

# ─── Disable Aurora ──────────────────────────────────────────────────────────

run "aurora_disabled_removes_resources" {
  command = plan

  variables {
    features = {
      aurora = false
    }
  }

  assert {
    condition     = length(aws_rds_cluster.aurora) == 0
    error_message = "Aurora cluster should not be created when features.aurora is false"
  }

  assert {
    condition     = length(aws_rds_cluster_instance.aurora) == 0
    error_message = "Aurora instance should not be created when features.aurora is false"
  }

  assert {
    condition     = length(aws_secretsmanager_secret.aurora) == 0
    error_message = "Aurora secret should not be created when features.aurora is false"
  }
}

# ─── Disable ElastiCache ─────────────────────────────────────────────────────

run "elasticache_disabled_removes_resources" {
  command = plan

  variables {
    features = {
      elasticache = false
    }
  }

  assert {
    condition     = length(aws_elasticache_replication_group.valkey) == 0
    error_message = "ElastiCache replication group should not be created when features.elasticache is false"
  }

  assert {
    condition     = length(aws_elasticache_subnet_group.main) == 0
    error_message = "ElastiCache subnet group should not be created when features.elasticache is false"
  }

  assert {
    condition     = length(aws_security_group.elasticache) == 0
    error_message = "ElastiCache security group should not be created when features.elasticache is false"
  }
}

# ─── Disable CloudFront ──────────────────────────────────────────────────────

run "cloudfront_disabled_removes_resources" {
  command = plan

  variables {
    features = {
      cloudfront = false
    }
  }

  assert {
    condition     = length(aws_cloudfront_distribution.assets) == 0
    error_message = "CloudFront distribution should not be created when features.cloudfront is false"
  }

  assert {
    condition     = length(aws_cloudfront_origin_access_control.assets) == 0
    error_message = "CloudFront OAC should not be created when features.cloudfront is false"
  }

  assert {
    condition     = length(aws_s3_bucket_policy.cloudfront_access) == 0
    error_message = "CloudFront S3 bucket policy should not be created when features.cloudfront is false"
  }
}

# ─── Disable Cognito ─────────────────────────────────────────────────────────

run "cognito_disabled_removes_resources" {
  command = plan

  variables {
    features = {
      cognito = false
    }
  }

  assert {
    condition     = length(aws_cognito_user_pool.main) == 0
    error_message = "Cognito user pool should not be created when features.cognito is false"
  }

  assert {
    condition     = length(aws_cognito_user_pool_client.main) == 0
    error_message = "Cognito client should not be created when features.cognito is false"
  }

  assert {
    condition     = length(aws_cognito_user_pool_domain.main) == 0
    error_message = "Cognito domain should not be created when features.cognito is false"
  }
}

# ─── Disable Step Functions ──────────────────────────────────────────────────

run "step_functions_disabled_removes_resources" {
  command = plan

  variables {
    features = {
      step_functions = false
    }
  }

  assert {
    condition     = length(aws_sfn_state_machine.main) == 0
    error_message = "Step Functions state machine should not be created when features.step_functions is false"
  }

  assert {
    condition     = length(aws_iam_role.sfn) == 0
    error_message = "Step Functions IAM role should not be created when features.step_functions is false"
  }
}

# ─── Disable Bedrock Logging ─────────────────────────────────────────────────

run "bedrock_logging_disabled_removes_resources" {
  command = plan

  variables {
    features = {
      bedrock_logging = false
    }
  }

  assert {
    condition     = length(aws_bedrock_model_invocation_logging_configuration.main) == 0
    error_message = "Bedrock logging config should not be created when features.bedrock_logging is false"
  }

  assert {
    condition     = length(aws_iam_role.bedrock_logging) == 0
    error_message = "Bedrock IAM role should not be created when features.bedrock_logging is false"
  }

  assert {
    condition     = length(aws_cloudwatch_log_group.bedrock) == 0
    error_message = "Bedrock log group should not be created when features.bedrock_logging is false"
  }
}

# ─── All features disabled ───────────────────────────────────────────────────

run "all_optional_features_disabled" {
  command = plan

  variables {
    features = {
      rds             = false
      aurora          = false
      elasticache     = false
      cloudfront      = false
      cognito         = false
      step_functions  = false
      bedrock_logging = false
    }
  }

  # Core resources should still be planned
  assert {
    condition     = aws_vpc.main.cidr_block == "10.0.0.0/16"
    error_message = "VPC should still be created with all optional features disabled"
  }

  assert {
    condition     = aws_lambda_function.handler["this"].runtime == "nodejs22.x"
    error_message = "Lambda should still be created with all optional features disabled"
  }

  assert {
    condition     = aws_dynamodb_table.main["this"].billing_mode == "PROVISIONED"
    error_message = "DynamoDB should still be created with all optional features disabled"
  }

  assert {
    condition     = aws_s3_bucket.assets["this"].bucket != ""
    error_message = "S3 bucket should still be created with all optional features disabled"
  }

  # No optional resources
  assert {
    condition     = length(aws_db_instance.postgres) == 0
    error_message = "No RDS should exist when all optional features are disabled"
  }

  assert {
    condition     = length(aws_rds_cluster.aurora) == 0
    error_message = "No Aurora should exist when all optional features are disabled"
  }

  assert {
    condition     = length(aws_elasticache_replication_group.valkey) == 0
    error_message = "No ElastiCache should exist when all optional features are disabled"
  }
}

# ─── Disable Compute ─────────────────────────────────────────────────────────

run "compute_disabled_removes_resources" {
  command = plan

  variables {
    features = {
      compute = false
    }
  }

  assert {
    condition     = length(aws_instance.web) == 0
    error_message = "EC2 instance should not be created when features.compute is false"
  }

  assert {
    condition     = length(aws_security_group.ec2) == 0
    error_message = "EC2 security group should not be created when features.compute is false"
  }

  assert {
    condition     = length(aws_iam_role.ec2) == 0
    error_message = "EC2 IAM role should not be created when features.compute is false"
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.ec2_cpu_high) == 0
    error_message = "EC2 CPU alarm should not be created when features.compute is false"
  }
}

# ─── Disable Storage ─────────────────────────────────────────────────────────

run "storage_disabled_removes_resources" {
  command = plan

  variables {
    features = {
      storage    = false
      cloudfront = false # CloudFront requires storage
    }
  }

  assert {
    condition     = length(aws_s3_bucket.assets) == 0
    error_message = "S3 bucket should not be created when features.storage is false"
  }

  assert {
    condition     = length(aws_dynamodb_table.main) == 0
    error_message = "DynamoDB table should not be created when features.storage is false"
  }

  assert {
    condition     = length(aws_iam_policy.s3_access) == 0
    error_message = "S3 access policy should not be created when features.storage is false"
  }
}

# ─── Disable Messaging ───────────────────────────────────────────────────────

run "messaging_disabled_removes_resources" {
  command = plan

  variables {
    features = {
      messaging = false
    }
  }

  assert {
    condition     = length(aws_sns_topic.alerts) == 0
    error_message = "SNS topic should not be created when features.messaging is false"
  }

  assert {
    condition     = length(aws_sqs_queue.main) == 0
    error_message = "SQS main queue should not be created when features.messaging is false"
  }

  assert {
    condition     = length(aws_sqs_queue.dlq) == 0
    error_message = "SQS DLQ should not be created when features.messaging is false"
  }

  # Budget still plans; notifications fall back to email only
  assert {
    condition     = aws_budgets_budget.zero_spend.budget_type == "COST"
    error_message = "Zero-spend budget should still be created when features.messaging is false"
  }
}

# ─── Disable Serverless ──────────────────────────────────────────────────────

run "serverless_disabled_removes_resources" {
  command = plan

  variables {
    features = {
      serverless     = false
      step_functions = false # Step Functions requires serverless
    }
  }

  assert {
    condition     = length(aws_lambda_function.handler) == 0
    error_message = "Lambda function should not be created when features.serverless is false"
  }

  assert {
    condition     = length(aws_apigatewayv2_api.main) == 0
    error_message = "API Gateway should not be created when features.serverless is false"
  }

  assert {
    condition     = length(aws_scheduler_schedule.lambda_ping) == 0
    error_message = "EventBridge schedule should not be created when features.serverless is false"
  }

  assert {
    condition     = length(aws_iam_role.lambda) == 0
    error_message = "Lambda IAM role should not be created when features.serverless is false"
  }

  assert {
    condition     = length(aws_cloudwatch_log_group.lambda) == 0
    error_message = "Lambda log group should not be created when features.serverless is false"
  }
}

# ─── Cross-feature validation ────────────────────────────────────────────────

run "step_functions_requires_serverless" {
  command = plan

  variables {
    features = {
      serverless     = false
      step_functions = true
    }
  }

  expect_failures = [var.features]
}

run "cloudfront_requires_storage" {
  command = plan

  variables {
    features = {
      storage    = false
      cloudfront = true
    }
  }

  expect_failures = [var.features]
}

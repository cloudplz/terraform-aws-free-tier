# Free-tier defaults tests — plan mode, mock providers.
# Verifies that default variable values produce free-tier-compliant resources.

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

# ─── EC2 defaults ────────────────────────────────────────────────────────────

run "ec2_defaults_are_free_tier" {
  command = plan

  assert {
    condition     = aws_instance.web.instance_type == "t4g.micro"
    error_message = "Default EC2 instance type should be t4g.micro"
  }

  assert {
    condition     = aws_instance.web.root_block_device[0].volume_size == 30
    error_message = "Default EBS volume should be 30 GB (free-tier max)"
  }

  assert {
    condition     = aws_instance.web.root_block_device[0].volume_type == "gp3"
    error_message = "EBS volume type should be gp3"
  }

  assert {
    condition     = aws_instance.web.credit_specification[0].cpu_credits == "standard"
    error_message = "CPU credits should be 'standard' to prevent surplus charges"
  }
}

# ─── RDS defaults ────────────────────────────────────────────────────────────

run "rds_defaults_are_free_tier" {
  command = plan

  assert {
    condition     = aws_db_instance.postgres["this"].instance_class == "db.t4g.micro"
    error_message = "Default RDS instance class should be db.t4g.micro"
  }

  assert {
    condition     = aws_db_instance.postgres["this"].allocated_storage == 20
    error_message = "Default RDS storage should be 20 GB (free-tier max)"
  }

  assert {
    condition     = aws_db_instance.postgres["this"].max_allocated_storage == 20
    error_message = "Max allocated storage should equal allocated storage to prevent auto-scaling"
  }

  assert {
    condition     = aws_db_instance.postgres["this"].multi_az == false
    error_message = "RDS multi_az should be false (doubles cost)"
  }

  assert {
    condition     = aws_db_instance.postgres["this"].publicly_accessible == false
    error_message = "RDS should not be publicly accessible"
  }
}

# ─── Lambda defaults ────────────────────────────────────────────────────────

run "lambda_defaults_are_free_tier" {
  command = plan

  assert {
    condition     = aws_lambda_function.handler.memory_size == 128
    error_message = "Default Lambda memory should be 128 MB to maximize free GB-seconds"
  }

  assert {
    condition     = aws_lambda_function.handler.runtime == "nodejs22.x"
    error_message = "Lambda runtime should be nodejs22.x"
  }

  assert {
    condition     = aws_lambda_function.handler.timeout == 10
    error_message = "Lambda timeout should be 10 seconds"
  }
}

# ─── DynamoDB defaults ───────────────────────────────────────────────────────

run "dynamodb_defaults_are_free_tier" {
  command = plan

  assert {
    condition     = aws_dynamodb_table.main.billing_mode == "PROVISIONED"
    error_message = "DynamoDB billing mode should be PROVISIONED (on-demand is NOT free-tier)"
  }

  assert {
    condition     = aws_dynamodb_table.main.read_capacity == 25
    error_message = "DynamoDB read capacity should be 25 (always-free max)"
  }

  assert {
    condition     = aws_dynamodb_table.main.write_capacity == 25
    error_message = "DynamoDB write capacity should be 25 (always-free max)"
  }
}

# ─── CloudFront defaults ────────────────────────────────────────────────────

run "cloudfront_defaults_are_free_tier" {
  command = plan

  assert {
    condition     = aws_cloudfront_distribution.assets["this"].price_class == "PriceClass_100"
    error_message = "CloudFront price class should be PriceClass_100"
  }

  assert {
    condition     = aws_cloudfront_distribution.assets["this"].viewer_certificate[0].cloudfront_default_certificate == true
    error_message = "CloudFront should use the default certificate (no ACM cost)"
  }
}

# ─── ElastiCache defaults ───────────────────────────────────────────────────

run "elasticache_defaults_are_free_tier" {
  command = plan

  assert {
    condition     = aws_elasticache_replication_group.valkey["this"].node_type == "cache.t3.micro"
    error_message = "ElastiCache node type should be cache.t3.micro (only free-tier eligible)"
  }

  assert {
    condition     = aws_elasticache_replication_group.valkey["this"].num_cache_clusters == 1
    error_message = "ElastiCache should have exactly 1 node"
  }
}

# ─── Step Functions defaults ─────────────────────────────────────────────────

run "step_functions_defaults_are_free_tier" {
  command = plan

  assert {
    condition     = aws_sfn_state_machine.main["this"].type == "STANDARD"
    error_message = "Step Functions should use STANDARD type (EXPRESS is not free-tier)"
  }
}

# ─── Budget defaults ────────────────────────────────────────────────────────

run "budget_defaults_detect_spend" {
  command = plan

  assert {
    condition     = aws_budgets_budget.zero_spend.budget_type == "COST"
    error_message = "Budget type should be COST"
  }

  assert {
    condition     = aws_budgets_budget.zero_spend.limit_amount == "0.01"
    error_message = "Budget limit should be $0.01 for zero-spend detection"
  }
}

# ─── Minimum required variables ─────────────────────────────────────────────

run "plans_with_only_required_variables" {
  command = plan

  variables {
    my_ip_cidr = null
  }

  assert {
    condition     = aws_instance.web.instance_type == "t4g.micro"
    error_message = "Module should plan successfully with only name provided"
  }
}

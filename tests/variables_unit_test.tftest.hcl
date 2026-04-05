# Variable validation tests — plan mode, no real resources.
# Verifies that validation rules reject invalid inputs.

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

# ─── name ────────────────────────────────────────────────────────────────────

run "reject_invalid_name_uppercase" {
  command = plan

  variables {
    name = "MyProject"
  }

  expect_failures = [var.name]
}

# ─── my_ip_cidr ──────────────────────────────────────────────────────────────

run "reject_invalid_cidr" {
  command = plan

  variables {
    my_ip_cidr = "not-a-cidr"
  }

  expect_failures = [var.my_ip_cidr]
}

# ─── vpc_cidr ───────────────────────────────────────────────────────────────

run "reject_too_small_vpc_cidr" {
  command = plan

  variables {
    vpc_cidr = "10.0.0.0/24"
  }

  expect_failures = [var.vpc_cidr]
}

# ─── notification_email ──────────────────────────────────────────────────────

run "reject_invalid_email" {
  command = plan

  variables {
    notification_email = "not-an-email"
  }

  expect_failures = [var.notification_email]
}

run "accept_null_notification_email" {
  command = plan

  variables {
    notification_email = null
  }

  assert {
    condition     = aws_budgets_budget.zero_spend.budget_type == "COST"
    error_message = "Module should plan successfully with notification_email = null"
  }
}

# ─── ec2_instance_type ───────────────────────────────────────────────────────

run "reject_non_t_family_instance" {
  command = plan

  variables {
    ec2_instance_type = "m5.large"
  }

  expect_failures = [var.ec2_instance_type]
}

# ─── ec2_volume_size_gb ─────────────────────────────────────────────────────

run "reject_oversized_ebs_volume" {
  command = plan

  variables {
    ec2_volume_size_gb = 50
  }

  expect_failures = [var.ec2_volume_size_gb]
}

# ─── rds_instance_class ─────────────────────────────────────────────────────

run "reject_non_free_tier_rds_class" {
  command = plan

  variables {
    rds_instance_class = "db.r5.large"
  }

  expect_failures = [var.rds_instance_class]
}

# ─── rds_allocated_storage ───────────────────────────────────────────────────

run "reject_oversized_rds_storage" {
  command = plan

  variables {
    rds_allocated_storage = 100
  }

  expect_failures = [var.rds_allocated_storage]
}

# ─── aurora_min_capacity ─────────────────────────────────────────────────────

run "reject_aurora_min_below_platform_minimum" {
  command = plan

  variables {
    aurora_min_capacity = 0.1
  }

  expect_failures = [var.aurora_min_capacity]
}

# ─── aurora_max_capacity ─────────────────────────────────────────────────────

run "reject_aurora_max_above_free_cap" {
  command = plan

  variables {
    aurora_max_capacity = 8.0
  }

  expect_failures = [var.aurora_max_capacity]
}

# ─── lambda_memory_mb ────────────────────────────────────────────────────────

run "reject_oversized_lambda_memory" {
  command = plan

  variables {
    lambda_memory_mb = 512
  }

  expect_failures = [var.lambda_memory_mb]
}

# ─── elasticache_node_type ───────────────────────────────────────────────────

run "reject_non_free_tier_elasticache_type" {
  command = plan

  variables {
    elasticache_node_type = "cache.t4g.micro"
  }

  expect_failures = [var.elasticache_node_type]
}

# ─── log_retention_days ──────────────────────────────────────────────────────

run "reject_invalid_log_retention" {
  command = plan

  variables {
    log_retention_days = 10
  }

  expect_failures = [var.log_retention_days]
}

# ─── az_count ───────────────────────────────────────────────────────────────

run "reject_too_many_azs" {
  command = plan

  variables {
    az_count = 5
  }

  expect_failures = [var.az_count]
}

# ─── features (cross-field validation) ───────────────────────────────────────

run "reject_elasticache_without_db" {
  command = plan

  variables {
    features = {
      rds         = false
      aurora      = false
      elasticache = true
    }
  }

  expect_failures = [var.features]
}

# Security tests — plan mode, mock providers.
# Verifies security hardening: IMDSv2, encryption, access controls.

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

# ─── EC2 security ────────────────────────────────────────────────────────────

run "ec2_enforces_imdsv2" {
  command = plan

  assert {
    condition     = aws_instance.web.metadata_options[0].http_tokens == "required"
    error_message = "EC2 must enforce IMDSv2 (http_tokens = required)"
  }
}

run "ec2_ebs_is_encrypted" {
  command = plan

  assert {
    condition     = aws_instance.web.root_block_device[0].encrypted == true
    error_message = "EC2 root EBS volume must be encrypted"
  }
}

run "ec2_no_ssh_without_key" {
  command = plan

  variables {
    key_name = null
  }

  assert {
    condition     = length([for rule in aws_security_group.ec2.ingress : rule if rule.from_port == 22 && rule.to_port == 22]) == 0
    error_message = "EC2 security group should not expose SSH when key_name is null"
  }
}

run "ec2_no_ssh_without_ip" {
  command = plan

  variables {
    key_name   = "test-key"
    my_ip_cidr = null
  }

  assert {
    condition     = length([for rule in aws_security_group.ec2.ingress : rule if rule.from_port == 22 && rule.to_port == 22]) == 0
    error_message = "EC2 security group should not expose SSH when my_ip_cidr is null"
  }
}

# ─── S3 security ─────────────────────────────────────────────────────────────

run "s3_blocks_all_public_access" {
  command = plan

  assert {
    condition     = aws_s3_bucket_public_access_block.assets.block_public_acls == true
    error_message = "S3 must block public ACLs"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.assets.block_public_policy == true
    error_message = "S3 must block public policies"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.assets.ignore_public_acls == true
    error_message = "S3 must ignore public ACLs"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.assets.restrict_public_buckets == true
    error_message = "S3 must restrict public buckets"
  }
}

run "s3_encryption_is_sse_s3" {
  command = plan

  assert {
    condition = alltrue([
      for rule in aws_s3_bucket_server_side_encryption_configuration.assets.rule : alltrue([
        for default in rule.apply_server_side_encryption_by_default : default.sse_algorithm == "AES256"
      ])
    ])
    error_message = "S3 encryption should use AES256 (SSE-S3, free) — not KMS"
  }
}

# ─── RDS security ────────────────────────────────────────────────────────────

run "rds_not_publicly_accessible" {
  command = plan

  assert {
    condition     = aws_db_instance.postgres["this"].publicly_accessible == false
    error_message = "RDS must not be publicly accessible"
  }

  assert {
    condition     = aws_db_instance.postgres["this"].storage_encrypted == true
    error_message = "RDS storage must be encrypted"
  }
}

# ─── Aurora security ────────────────────────────────────────────────────────

run "aurora_storage_encrypted" {
  command = plan

  assert {
    condition     = aws_rds_cluster.aurora["this"].storage_encrypted == true
    error_message = "Aurora storage must be encrypted"
  }

  assert {
    condition     = aws_rds_cluster_instance.aurora["this"].publicly_accessible == false
    error_message = "Aurora instance must not be publicly accessible"
  }
}

# ─── SQS security ────────────────────────────────────────────────────────────

run "sqs_queues_are_encrypted" {
  command = plan

  assert {
    condition     = aws_sqs_queue.main.sqs_managed_sse_enabled == true
    error_message = "Main SQS queue must have SSE enabled"
  }

  assert {
    condition     = aws_sqs_queue.dlq.sqs_managed_sse_enabled == true
    error_message = "DLQ must have SSE enabled"
  }
}

# ─── DynamoDB security ──────────────────────────────────────────────────────

run "dynamodb_encryption_enabled" {
  command = plan

  assert {
    condition     = aws_dynamodb_table.main.server_side_encryption[0].enabled == true
    error_message = "DynamoDB must have server-side encryption enabled"
  }
}

# ─── Cognito security ───────────────────────────────────────────────────────

run "cognito_advanced_security_off" {
  command = plan

  assert {
    condition     = aws_cognito_user_pool.main["this"].user_pool_add_ons[0].advanced_security_mode == "OFF"
    error_message = "Cognito advanced security should be OFF (incurs charges)"
  }
}

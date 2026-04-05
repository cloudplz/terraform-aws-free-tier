# DynamoDB — always free: 25 RCU + 25 WCU + 25 GB storage
# ⚠️ billing_mode = "PAY_PER_REQUEST" is NOT covered by free tier
# ⚠️ read_capacity or write_capacity > 25 will exceed free tier allowance
# ⚠️ Storing more than 25 GB of data will incur charges

resource "aws_dynamodb_table" "main" {
  name         = "${var.project_name}-table"
  billing_mode = "PROVISIONED"  # ⚠️ PAY_PER_REQUEST (on-demand) is NOT free tier

  read_capacity  = 25  # Free tier max — do not exceed
  write_capacity = 25  # Free tier max — do not exceed

  hash_key  = "pk"
  range_key = "sk"

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }

  # TTL — automatically deletes expired items (reduces storage usage)
  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  # Server-side encryption using AWS-owned key (free)
  # ⚠️ Using a KMS customer-managed key would incur KMS charges
  server_side_encryption {
    enabled = true
  }

  tags = {
    Name = "${var.project_name}-table"
  }
}

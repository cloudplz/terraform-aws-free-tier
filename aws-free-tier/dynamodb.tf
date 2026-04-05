# DynamoDB — terraform-aws-modules/dynamodb-table
# Free tier (always free): 25 RCU + 25 WCU + 25 GB storage.
# ⚠️ billing_mode = "PAY_PER_REQUEST" (on-demand) is NOT covered by free tier
# ⚠️ read_capacity or write_capacity > 25 will exceed free tier allowance
# ⚠️ Storing more than 25 GB of data will incur charges
module "dynamodb_table" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 4.0"

  name         = "${var.project_name}-table"
  billing_mode = "PROVISIONED" # ⚠️ PAY_PER_REQUEST (on-demand) is NOT free tier

  read_capacity  = 25 # Free tier max — do not exceed
  write_capacity = 25 # Free tier max — do not exceed

  hash_key  = "pk"
  range_key = "sk"

  attributes = [
    {
      name = "pk"
      type = "S"
    },
    {
      name = "sk"
      type = "S"
    }
  ]

  # TTL — automatically deletes expired items (reduces storage usage)
  ttl_enabled        = true
  ttl_attribute_name = "expires_at"

  # Server-side encryption using AWS-owned key (free)
  # ⚠️ Using KMS customer-managed key would incur KMS charges
  server_side_encryption_enabled = true

  tags = {
    Name = "${var.project_name}-table"
  }
}

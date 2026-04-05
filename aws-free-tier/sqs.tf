# SQS Dead Letter Queue — receives messages that fail processing 3 times.
# Free tier (always free): 1M requests/month across all SQS queues.
# Standard queue (not FIFO) — FIFO queues consume free tier requests faster
# because each message operation counts as multiple API calls.
module "sqs_dlq" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "~> 4.0"

  name = "${var.project_name}-dlq"

  # Standard queue — not FIFO
  # ⚠️ FIFO queues burn free tier API requests faster (deduplication overhead)
  message_retention_seconds = 1209600 # 14 days — max retention for dead letters

  tags = {
    Name = "${var.project_name}-dlq"
  }
}

# SQS Main Queue — standard queue with dead-letter redrive.
# Free tier (always free): 1M requests/month across all SQS queues.
# ⚠️ Switching to FIFO burns free tier faster due to deduplication API overhead
module "sqs" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "~> 4.0"

  name = "${var.project_name}-queue"

  visibility_timeout_seconds = 30    # Time a consumer has to process a message
  message_retention_seconds  = 86400 # 24 hours — keep messages for 1 day

  # Redrive policy: send to DLQ after 3 failed receive attempts
  redrive_policy = jsonencode({
    deadLetterTargetArn = module.sqs_dlq.queue_arn
    maxReceiveCount     = 3
  })

  tags = {
    Name = "${var.project_name}-queue"
  }
}

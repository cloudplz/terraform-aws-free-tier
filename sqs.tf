# SQS — always free: 1M requests/month across all queues
# Standard queues (not FIFO) — FIFO burns free tier faster (deduplication overhead)
# ⚠️ Switching to FIFO queues consumes free tier requests faster

# Dead Letter Queue — receives messages that fail processing 3 times
resource "aws_sqs_queue" "dlq" {
  name = "${var.project_name}-dlq"

  message_retention_seconds = 1209600  # 14 days — max retention for dead letters

  tags = {
    Name = "${var.project_name}-dlq"
  }
}

# Main queue with DLQ redrive
resource "aws_sqs_queue" "main" {
  name = "${var.project_name}-queue"

  visibility_timeout_seconds = 30     # Time a consumer has to process a message
  message_retention_seconds  = 86400  # 24 hours

  tags = {
    Name = "${var.project_name}-queue"
  }
}

# Redrive policy: send to DLQ after 3 failed receive attempts
resource "aws_sqs_queue_redrive_policy" "main" {
  queue_url = aws_sqs_queue.main.id

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })
}

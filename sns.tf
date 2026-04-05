# SNS — always free: 1M publishes/month, 100K HTTP/S deliveries, 1K email deliveries/month

resource "aws_sns_topic" "alerts" {
  name = "${var.name}-alerts"

  tags = merge(local.common_tags, var.tags, {
    Name = "${var.name}-alerts"
  })
}

# Email subscription — AWS sends a confirmation email; click the link to activate.
# Skipped when notification_email is null.
resource "aws_sns_topic_subscription" "email" {
  count = var.notification_email != null ? 1 : 0

  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

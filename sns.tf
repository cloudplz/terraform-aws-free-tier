# SNS — always free: 1M publishes/month, 100K HTTP/S deliveries, 1K email deliveries/month

resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"

  tags = {
    Name = "${var.project_name}-alerts"
  }
}

# Email subscription — AWS will send a confirmation email to notification_email.
# You must click the confirmation link before the subscription is active.
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

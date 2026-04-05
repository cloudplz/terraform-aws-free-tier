# EventBridge Scheduler — always free: 14M invocations/month
# Invokes the Lambda function on a schedule using an IAM execution role.
# ⚠️ This uses the newer aws_scheduler_schedule (EventBridge Scheduler service),
#    NOT aws_cloudwatch_event_rule (EventBridge Rules) — they are different services.

resource "aws_scheduler_schedule" "lambda_ping" {
  name        = "${var.project_name}-lambda-ping"
  description = "Invokes the Lambda handler every 5 minutes"

  flexible_time_window {
    mode = "OFF"  # No jitter — invoke exactly on schedule
  }

  schedule_expression = "rate(5 minutes)"

  target {
    arn      = aws_lambda_function.handler.arn
    role_arn = aws_iam_role.scheduler.arn

    input = jsonencode({ source = "eventbridge-scheduler" })
  }
}

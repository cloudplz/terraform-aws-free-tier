# CloudWatch — always free: 10 custom metrics, 10 alarms, 5 GB log ingestion/storage, 1M API requests
# ⚠️ More than 10 alarms incur charges
# ⚠️ Long retention + high log volume may exceed the 5 GB free storage limit

# ─── Log Groups ───────────────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/${var.project_name}/app"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name    = "${var.project_name}-app-logs"
    Project = var.project_name
  })
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.project_name}-handler"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name    = "${var.project_name}-lambda-logs"
    Project = var.project_name
  })
}

resource "aws_cloudwatch_log_group" "bedrock" {
  name              = "/aws/${var.project_name}/bedrock"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name    = "${var.project_name}-bedrock-logs"
    Project = var.project_name
  })
}

# ─── Alarms (2 of 10 free slots) ──────────────────────────────────────────────
# ⚠️ More than 10 alarms will incur charges

# EC2 CPU > 80% for 10 minutes — detects runaway processes (always created; EC2 is core)
resource "aws_cloudwatch_metric_alarm" "ec2_cpu_high" {
  alarm_name          = "${var.project_name}-ec2-cpu-high"
  alarm_description   = "EC2 CPU utilization exceeds 80% for 10 minutes"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = aws_instance.web.id
  }

  tags = merge(var.tags, {
    Name    = "${var.project_name}-ec2-cpu-high"
    Project = var.project_name
  })
}

# RDS free storage < 2 GB — warns before hitting the 20 GB free plan ceiling
# Only created when features.rds is enabled
resource "aws_cloudwatch_metric_alarm" "rds_low_storage" {
  for_each = var.features.rds ? { this = {} } : {}

  alarm_name          = "${var.project_name}-rds-low-storage"
  alarm_description   = "RDS free storage below 2 GB — approaching 20 GB free plan limit"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 2147483648  # 2 GB in bytes
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres["this"].identifier
  }

  tags = merge(var.tags, {
    Name    = "${var.project_name}-rds-low-storage"
    Project = var.project_name
  })
}

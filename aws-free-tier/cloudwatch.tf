# CloudWatch — native aws_cloudwatch_* resources (no official module needed)
# Free tier (always free): 10 custom metrics, 10 alarms, 1M API requests,
# 5 GB log data ingestion, 5 GB log data storage.

# Log group for application logs.
# retention = 7 days keeps storage well within the 5 GB free tier limit.
# ⚠️ Longer retention or high log volume may exceed the 5 GB free tier storage
resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/${var.project_name}/app"
  retention_in_days = 7 # Short retention to stay within 5 GB free storage

  tags = {
    Name = "${var.project_name}-app-logs"
  }
}

# Alarm: EC2 CPU utilization exceeds 80%.
# Free tier: 10 alarms are free. This uses 1 of those 10 slots.
# Detects runaway processes or crypto-mining on the free tier instance.
# ⚠️ More than 10 alarms will incur charges
resource "aws_cloudwatch_metric_alarm" "ec2_cpu_high" {
  alarm_name          = "${var.project_name}-ec2-cpu-high"
  alarm_description   = "EC2 CPU utilization exceeds 80% for 10 minutes"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300 # 5-minute periods
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = module.ec2.id
  }

  tags = {
    Name = "${var.project_name}-ec2-cpu-high"
  }
}

# Alarm: RDS free storage drops below 2 GB.
# Warns before hitting the 20 GB free tier storage ceiling.
# If storage fills up, RDS may become read-only or auto-scale (if max_allocated_storage > 20).
# ⚠️ More than 10 alarms will incur charges
resource "aws_cloudwatch_metric_alarm" "rds_low_storage" {
  alarm_name          = "${var.project_name}-rds-low-storage"
  alarm_description   = "RDS free storage below 2 GB — approaching 20 GB free tier limit"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300 # 5-minute periods
  statistic           = "Average"
  threshold           = 2147483648 # 2 GB in bytes
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = module.rds.db_instance_identifier
  }

  tags = {
    Name = "${var.project_name}-rds-low-storage"
  }
}

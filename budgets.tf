# AWS Budgets — always free: 2 action-enabled budgets per account
# Zero-spend budget: alerts the moment any charges appear on the account.
# Credit activity: creating a budget earns $20 in AWS credits (new accounts).
# ⚠️ More than 2 action-enabled budgets incur charges ($0.10/action/day)

resource "aws_budgets_budget" "zero_spend" {
  name         = "${var.project_name}-zero-spend"
  budget_type  = "COST"
  limit_amount = "1"    # Alert at $1 (effectively zero-spend alert)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  # Alert at 80% of $1 (actual spend)
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.notification_email]
  }

  # Alert when forecasted to exceed $1
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.notification_email]
  }
}

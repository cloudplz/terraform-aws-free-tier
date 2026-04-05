# Step Functions — always free: 4,000 state transitions/month (Standard Workflows)
# Simple 2-state machine: invoke Lambda → succeed.
# ⚠️ type = "EXPRESS" is priced differently and NOT covered by free tier
# ⚠️ Each state transition counts — complex state machines exhaust 4K faster

resource "aws_sfn_state_machine" "main" {
  for_each = var.features.step_functions ? { this = {} } : {}

  name     = "${var.project_name}-state-machine"
  role_arn = aws_iam_role.sfn["this"].arn
  type     = "STANDARD" # ⚠️ EXPRESS is NOT free tier

  definition = jsonencode({
    Comment = "Invoke Lambda and succeed — ${var.project_name}"
    StartAt = "InvokeLambda"
    States = {
      InvokeLambda = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = aws_lambda_function.handler.arn
          "Payload.$"  = "$"
        }
        ResultPath = "$.lambdaResult"
        Next       = "Succeed"
      }
      Succeed = {
        Type = "Succeed"
      }
    }
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-state-machine"
  })
}

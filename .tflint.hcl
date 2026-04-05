plugin "aws" {
  enabled = true
  version = "0.47.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

config {
  call_module_type    = "none"
  force               = false
  disabled_by_default = false
}

rule "terraform_naming_convention" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_typed_variables" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_standard_module_structure" {
  enabled = false # per-service files (vpc.tf, rds.tf, etc.) instead of a single main.tf
}

# Default parameter groups are intentional — free-tier project needs no custom parameters
rule "aws_db_instance_default_parameter_group" {
  enabled = false
}

rule "aws_elasticache_replication_group_default_parameter_group" {
  enabled = false
}

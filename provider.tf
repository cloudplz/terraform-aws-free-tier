# AWS provider with default tags applied to every resource.
# All resources inherit Project, ManagedBy, and Tier tags automatically.
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "terraform"
      Tier      = "free"
    }
  }
}

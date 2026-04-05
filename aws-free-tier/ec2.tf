# EC2 — terraform-aws-modules/ec2-instance
# Free tier: 750 hours/month of t2.micro or t3.micro (12-month).
# t4g.micro is also free-tier eligible (Graviton2 ARM, 40% faster).
# ⚠️ Changing instance_type to anything larger (e.g., t3.small) will incur charges.
# ⚠️ Root volume > 30 GB will exceed the free tier EBS allowance.
module "ec2" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.0"

  name = "${var.project_name}-web"

  ami           = data.aws_ssm_parameter.al2023_ami.value
  instance_type = "t4g.micro" # Graviton2 ARM — free tier eligible, 40% faster than t3.micro

  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.ec2.id]

  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.ec2.name

  # 30 GB gp3 root volume — free tier max for EBS
  # ⚠️ Increasing beyond 30 GB will exceed the free tier EBS storage allowance
  root_block_device = [
    {
      volume_type = "gp3"
      volume_size = 30 # Free tier: up to 30 GB of EBS (gp2/gp3)
      encrypted   = true
    }
  ]

  # Bootstrap: install nginx + postgresql17 client
  user_data = <<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y nginx postgresql17
    systemctl enable nginx
    systemctl start nginx
  EOF

  tags = {
    Name = "${var.project_name}-web"
  }
}

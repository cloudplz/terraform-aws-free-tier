# EC2 — free plan: 750 hrs/month of t4g.micro (Graviton2 ARM)
# ⚠️ Changing instance_type to anything larger will incur charges
# ⚠️ Root volume > 30 GB exceeds the free plan EBS allowance (30 GB total)

resource "aws_instance" "web" {
  ami           = data.aws_ssm_parameter.al2023_ami.value
  instance_type = var.ec2_instance_type
  key_name      = var.key_name  # SSH key pair — set to null to disable SSH access

  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  associate_public_ip_address = true

  # Prevent T-family CPU surplus charges — "standard" stops bursting at credit depletion
  # ⚠️ "unlimited" (default) allows sustained bursting and incurs surplus charges
  credit_specification {
    cpu_credits = "standard"
  }

  # Enforce IMDSv2 — blocks SSRF-based credential theft via instance metadata
  metadata_options {
    http_tokens = "required"
  }

  # ⚠️ Increasing beyond 30 GB exceeds the free plan EBS storage allowance
  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.ec2_volume_size_gb
    encrypted             = true
    delete_on_termination = true
  }

  # Bootstrap: install nginx + SSM agent (SSM agent is pre-installed on AL2023)
  user_data = <<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y nginx
    systemctl enable nginx
    systemctl start nginx
  EOF

  tags = merge(var.tags, {
    Name    = "${var.project_name}-web"
    Project = var.project_name
  })
}

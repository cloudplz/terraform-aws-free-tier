# ElastiCache Redis — free tier: 750 hrs/month cache.t3.micro (12-month)
# ⚠️ num_cache_nodes > 1 exceeds free tier
# ⚠️ Changing node_type to anything larger incurs charges

resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_name}-cache-subnet"
  subnet_ids = [for s in aws_subnet.private : s.id]

  tags = {
    Name = "${var.project_name}-cache-subnet"
  }
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.project_name}-redis"
  engine               = "redis"
  engine_version       = "7.1"
  node_type            = "cache.t3.micro"  # ⚠️ Larger type incurs charges
  num_cache_nodes      = 1                 # ⚠️ > 1 node exceeds free tier
  parameter_group_name = "default.redis7"
  port                 = 6379

  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.elasticache.id]

  tags = {
    Name = "${var.project_name}-redis"
  }
}

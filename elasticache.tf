# ElastiCache Valkey — free plan: 750 hrs/month cache.t3.micro
# Valkey is the open-source Redis fork and is 20% cheaper than Redis after credits expire.
# ⚠️ cache.t4g.micro is NOT free-plan eligible — only cache.t3.micro qualifies
# ⚠️ num_cache_nodes > 1 exceeds free plan
# ⚠️ Changing node_type to anything larger incurs charges

resource "aws_elasticache_subnet_group" "main" {
  for_each = var.features.elasticache ? { this = {} } : {}

  name       = "${var.project_name}-cache-subnet"
  subnet_ids = [for s in aws_subnet.private : s.id]

  tags = merge(var.tags, {
    Name    = "${var.project_name}-cache-subnet"
    Project = var.project_name
  })
}

resource "aws_elasticache_cluster" "valkey" {
  for_each = var.features.elasticache ? { this = {} } : {}

  cluster_id           = "${var.project_name}-valkey"
  engine               = "valkey"
  engine_version       = "8.0"
  node_type            = var.elasticache_node_type  # ⚠️ cache.t3.micro is the only free-plan eligible type
  num_cache_nodes      = 1                           # ⚠️ > 1 node exceeds free plan
  parameter_group_name = "default.valkey8"
  port                 = 6379

  subnet_group_name  = aws_elasticache_subnet_group.main["this"].name
  security_group_ids = [aws_security_group.elasticache.id]

  tags = merge(var.tags, {
    Name    = "${var.project_name}-valkey"
    Project = var.project_name
  })
}

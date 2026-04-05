# ElastiCache Valkey — consumes credits: cache.t3.micro @ $0.017/hr (~$12.41/mo)
# Valkey is the open-source Redis fork. cache.t3.micro is the smallest available node type.
# ⚠️ cache.t4g.micro is NOT supported for free plan — only cache.t3.micro qualifies
# ⚠️ num_cache_nodes > 1 doubles the hourly cost
# ⚠️ Changing node_type to anything larger increases credit burn

resource "aws_elasticache_subnet_group" "main" {
  for_each = var.features.elasticache ? { this = {} } : {}

  name       = "${var.name}-cache-subnet"
  subnet_ids = [for s in aws_subnet.private : s.id]

  tags = merge(var.tags, {
    Name = "${var.name}-cache-subnet"
  })
}

resource "aws_elasticache_cluster" "valkey" {
  for_each = var.features.elasticache ? { this = {} } : {}

  cluster_id           = "${var.name}-valkey"
  engine               = "valkey"
  engine_version       = "8.0"
  node_type            = var.elasticache_node_type # ⚠️ cache.t3.micro is the only free-plan eligible type
  num_cache_nodes      = 1                         # ⚠️ > 1 node exceeds free plan
  parameter_group_name = "default.valkey8"
  port                 = 6379

  subnet_group_name  = aws_elasticache_subnet_group.main["this"].name
  security_group_ids = [aws_security_group.elasticache["this"].id]

  tags = merge(var.tags, {
    Name = "${var.name}-valkey"
  })
}

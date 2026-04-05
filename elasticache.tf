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

# ⚠️ aws_elasticache_cluster does NOT support the Valkey engine — use aws_elasticache_replication_group
# (The CreateCacheCluster API rejects Valkey; only CreateReplicationGroup accepts it.)
resource "aws_elasticache_replication_group" "valkey" {
  for_each = var.features.elasticache ? { this = {} } : {}

  replication_group_id = "${var.name}-valkey"
  description          = "Valkey cache for ${var.name}"
  engine               = "valkey"
  engine_version       = "8.0"
  node_type            = var.elasticache_node_type # ⚠️ cache.t3.micro is the only free-plan eligible type
  num_cache_clusters   = 1                         # single primary, no replicas — ⚠️ > 1 exceeds free plan
  parameter_group_name = "default.valkey8"
  port                 = 6379

  # automatic_failover_enabled requires num_cache_clusters >= 2 — leave disabled for free plan
  automatic_failover_enabled = false

  subnet_group_name  = aws_elasticache_subnet_group.main["this"].name
  security_group_ids = [aws_security_group.elasticache["this"].id]

  tags = merge(var.tags, {
    Name = "${var.name}-valkey"
  })
}

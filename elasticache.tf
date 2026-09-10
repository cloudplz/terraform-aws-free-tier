# ElastiCache Valkey — consumes credits: cache.t3.micro @ $0.017/hr (~$12.41/mo)
# Valkey is the open-source Redis fork. cache.t3.micro is the smallest available node type.
# ⚠️ Under the new Free Plan, ALL node types consume credits; t3.micro is pinned as the
#    lowest-burn default (the legacy 12-month tier covered only t3.micro)
# ⚠️ Changing node_type to anything larger increases credit burn

resource "aws_elasticache_subnet_group" "main" {
  for_each = var.features.elasticache ? { this = {} } : {}

  name       = "${var.name}-cache-subnet"
  subnet_ids = [for s in aws_subnet.private : s.id]

  tags = merge(local.common_tags, var.tags, {
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
  node_type            = var.elasticache_node_type # ⚠️ pinned to cache.t3.micro to keep credit burn minimal
  num_cache_clusters   = 1                         # single primary, no replicas — ⚠️ > 1 exceeds free plan
  parameter_group_name = "default.valkey8"
  port                 = 6379

  # automatic_failover_enabled requires num_cache_clusters >= 2 — leave disabled for free plan
  automatic_failover_enabled = false

  subnet_group_name  = aws_elasticache_subnet_group.main["this"].name
  security_group_ids = [aws_security_group.elasticache["this"].id]

  tags = merge(local.common_tags, var.tags, {
    Name = "${var.name}-valkey"
  })
}

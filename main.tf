locals {
  # Use the explicit version when given, else read it from the cluster.
  resolved_kubernetes_version = var.kubernetes_version != null ? var.kubernetes_version : one(data.aws_eks_cluster.this[*].version)
}

# Only read the cluster when we need its Kubernetes version (so examples/tests
# can plan offline by supplying kubernetes_version explicitly).
data "aws_eks_cluster" "this" {
  count = local.enabled && var.kubernetes_version == null ? 1 : 0
  name  = var.cluster_name
}

resource "aws_eks_node_group" "this" {
  count = local.enabled ? 1 : 0

  cluster_name    = var.cluster_name
  node_group_name = local.id
  node_role_arn   = local.node_role_arn
  subnet_ids      = var.subnet_ids
  version         = local.resolved_kubernetes_version

  instance_types       = var.instance_types
  ami_type             = var.ami_type
  capacity_type        = var.capacity_type
  force_update_version = var.force_update_version
  labels               = var.kubernetes_labels

  scaling_config {
    desired_size = var.desired_size
    min_size     = var.min_size
    max_size     = var.max_size
  }

  update_config {
    max_unavailable_percentage = var.max_unavailable_percentage
  }

  launch_template {
    id      = local.effective_lt_id
    version = local.effective_lt_version
  }

  dynamic "taint" {
    for_each = var.kubernetes_taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  tags = local.tags

  # Let the cluster autoscaler own desired_size after creation.
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  depends_on = [
    aws_iam_role_policy_attachment.managed,
    aws_iam_role_policy_attachment.additional,
  ]
}

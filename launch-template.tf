locals {
  create_lt = local.enabled && var.create_launch_template

  # The node group references this launch template (created) or a BYO one.
  effective_lt_id      = local.create_lt ? one(aws_launch_template.node[*].id) : var.launch_template_id
  effective_lt_version = local.create_lt ? one(aws_launch_template.node[*].latest_version) : var.launch_template_version
}

# Hardened launch template. Deliberately omits image_id and instance_type so EKS
# selects the right AMI for `ami_type` + Kubernetes version and merges its
# bootstrap userdata; we only override disk, metadata (IMDSv2), and monitoring.
resource "aws_launch_template" "node" {
  count = local.create_lt ? 1 : 0

  name_prefix            = "${local.id}-"
  update_default_version = true
  ebs_optimized          = var.ebs_optimized

  vpc_security_group_ids = length(var.node_security_group_ids) > 0 ? var.node_security_group_ids : null

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.disk_size
      volume_type           = var.disk_type
      encrypted             = var.disk_encrypted
      kms_key_id            = var.disk_kms_key_id
      delete_on_termination = true
    }
  }

  # IMDSv2 required; hop limit 1 keeps containers off the instance metadata
  # endpoint (use IRSA for pod credentials).
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = var.metadata_http_put_response_hop_limit
    instance_metadata_tags      = "disabled"
  }

  monitoring {
    enabled = var.enable_detailed_monitoring
  }

  tag_specifications {
    resource_type = "instance"
    tags          = local.tags
  }

  tag_specifications {
    resource_type = "volume"
    tags          = local.tags
  }

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

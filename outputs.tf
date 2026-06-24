output "node_group_id" {
  description = "EKS node group ID (cluster_name:node_group_name)."
  value       = one(aws_eks_node_group.this[*].id)
}

output "node_group_arn" {
  description = "EKS node group ARN."
  value       = one(aws_eks_node_group.this[*].arn)
}

output "node_group_status" {
  description = "Status of the node group."
  value       = one(aws_eks_node_group.this[*].status)
}

output "node_group_resources" {
  description = "Underlying resources (autoscaling groups, etc.) of the node group."
  value       = one(aws_eks_node_group.this[*].resources)
}

output "node_role_arn" {
  description = "IAM role ARN used by the worker nodes."
  value       = local.node_role_arn
}

output "node_role_name" {
  description = "IAM role name used by the worker nodes (null when a role ARN is supplied)."
  value       = one(aws_iam_role.node[*].name)
}

output "launch_template_id" {
  description = "ID of the launch template used by the node group."
  value       = local.effective_lt_id
}

output "launch_template_latest_version" {
  description = "Latest version of the created launch template."
  value       = one(aws_launch_template.node[*].latest_version)
}

output "node_group_id" {
  description = "EKS node group ID."
  value       = module.node_group.node_group_id
}

output "node_role_arn" {
  description = "Worker node IAM role ARN."
  value       = module.node_group.node_role_arn
}

output "node_group_id" {
  description = "EKS node group ID."
  value       = module.node_group.node_group_id
}

output "node_group_arn" {
  description = "EKS node group ARN."
  value       = module.node_group.node_group_arn
}

output "node_role_arn" {
  description = "Worker node IAM role ARN."
  value       = module.node_group.node_role_arn
}

output "launch_template_id" {
  description = "Launch template ID used by the node group."
  value       = module.node_group.launch_template_id
}

# ---------------------------------------------------------------------------
# Cluster + placement
# ---------------------------------------------------------------------------
variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster to attach this node group to."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs the worker nodes launch in."
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version for the nodes. Null uses the cluster's version (recommended)."
  default     = null
}

# ---------------------------------------------------------------------------
# Sizing + capacity
# ---------------------------------------------------------------------------
variable "instance_types" {
  type        = list(string)
  description = "Instance types for the node group (up to 20). Defaults to a Graviton type."
  # Devotica fintech default: Graviton (arm64) — cheaper + lower-carbon. Pair with ami_type AL2023_ARM_64_STANDARD.
  default = ["t4g.large"]
}

variable "ami_type" {
  type        = string
  description = "EKS AMI type (e.g. AL2023_ARM_64_STANDARD, AL2023_x86_64_STANDARD, BOTTLEROCKET_ARM_64)."
  # Devotica fintech default: AL2023 on Graviton, matching the default instance type.
  default = "AL2023_ARM_64_STANDARD"
}

variable "capacity_type" {
  type        = string
  description = "ON_DEMAND or SPOT."
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.capacity_type)
    error_message = "capacity_type must be ON_DEMAND or SPOT."
  }
}

variable "desired_size" {
  type        = number
  description = "Desired number of worker nodes. Changes after create are ignored (let the cluster autoscaler manage it)."
  default     = 2
}

variable "min_size" {
  type        = number
  description = "Minimum number of worker nodes."
  default     = 1
}

variable "max_size" {
  type        = number
  description = "Maximum number of worker nodes."
  default     = 3
}

variable "max_unavailable_percentage" {
  type        = number
  description = "Maximum percentage of nodes unavailable during a rolling update."
  default     = 33
}

variable "force_update_version" {
  type        = bool
  description = "Force a version update even if pods with disruption budgets block it."
  default     = false
}

variable "kubernetes_labels" {
  type        = map(string)
  description = "Kubernetes labels applied to the nodes."
  default     = {}
}

variable "kubernetes_taints" {
  type = list(object({
    key    = string
    value  = optional(string)
    effect = string # NO_SCHEDULE, NO_EXECUTE, PREFER_NO_SCHEDULE
  }))
  description = "Kubernetes taints applied to the nodes."
  default     = []

  validation {
    condition     = alltrue([for t in var.kubernetes_taints : contains(["NO_SCHEDULE", "NO_EXECUTE", "PREFER_NO_SCHEDULE"], t.effect)])
    error_message = "taint effect must be NO_SCHEDULE, NO_EXECUTE, or PREFER_NO_SCHEDULE."
  }
}

# ---------------------------------------------------------------------------
# Launch template (disk + metadata hardening)
# ---------------------------------------------------------------------------
variable "create_launch_template" {
  type        = bool
  description = "Create a hardened launch template (encrypted disk, IMDSv2). Set false to bring your own."
  default     = true
}

variable "launch_template_id" {
  type        = string
  description = "Bring-your-own launch template ID (used when create_launch_template = false)."
  default     = null
}

variable "launch_template_version" {
  type        = string
  description = "Launch template version to use with a bring-your-own template."
  default     = "$Latest"
}

variable "disk_size" {
  type        = number
  description = "Root EBS volume size (GiB)."
  default     = 50
}

variable "disk_type" {
  type        = string
  description = "Root EBS volume type."
  default     = "gp3"
}

variable "disk_encrypted" {
  type        = bool
  description = "Encrypt the root EBS volume."
  # Devotica fintech default: always encrypt node disks.
  default = true
}

variable "disk_kms_key_id" {
  type        = string
  description = "KMS key ARN for the root EBS volume. Null uses the account/EBS default key."
  default     = null
}

variable "ebs_optimized" {
  type        = bool
  description = "Launch EBS-optimized instances."
  default     = true
}

variable "enable_detailed_monitoring" {
  type        = bool
  description = "Enable EC2 detailed (1-minute) monitoring."
  default     = true
}

variable "metadata_http_put_response_hop_limit" {
  type        = number
  description = "IMDS hop limit. Devotica defaults to 1 so containers cannot reach IMDS (forcing IRSA); raise to 2 only if a workload genuinely needs node credentials."
  # Devotica fintech default: 1 blocks pod access to IMDS.
  default = 1
}

# ---------------------------------------------------------------------------
# IAM
# ---------------------------------------------------------------------------
variable "node_role_arn" {
  type        = string
  description = "Existing IAM role ARN for the nodes. Null creates one with the standard EKS worker policies + SSM."
  default     = null
}

variable "node_role_additional_policy_arns" {
  type        = list(string)
  description = "Extra IAM policy ARNs to attach to the created node role."
  default     = []
}

variable "node_role_permissions_boundary" {
  type        = string
  description = "Permissions boundary ARN for the created node role."
  default     = null
}

# ---------------------------------------------------------------------------
# Network
# ---------------------------------------------------------------------------
variable "node_security_group_ids" {
  type        = list(string)
  description = "Additional security group IDs to attach to the nodes (via the launch template)."
  default     = []
}

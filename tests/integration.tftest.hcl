# Integration tests — apply + assert + destroy. Requires real AWS credentials
# AND an existing EKS cluster + private subnets. Triggered via integration.yml.
# Provisioning a node group takes several minutes; keep it lean.

provider "aws" {
  region = "ap-south-1"
}

variables {
  namespace    = "dvtca"
  stage        = "integ"
  name         = "ng"
  attributes   = ["workers"]
  cluster_name = ""
  subnet_ids   = []

  instance_types = ["t4g.small"]
  ami_type       = "AL2023_ARM_64_STANDARD"
  desired_size   = 1
  min_size       = 1
  max_size       = 1

  tags = { Environment = "integration-test", Ephemeral = "true" }
}

run "apply_and_assert" {
  command = apply

  assert {
    condition     = aws_eks_node_group.this[0].arn != ""
    error_message = "Node group must be created."
  }
  assert {
    condition     = aws_launch_template.node[0].metadata_options[0].http_tokens == "required"
    error_message = "IMDSv2 must be enforced."
  }
}

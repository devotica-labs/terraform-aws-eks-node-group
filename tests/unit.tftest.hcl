# Plan-only unit tests — no AWS credentials required. kubernetes_version is set
# so the cluster data source is not read.

mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}" }
  }
  mock_data "aws_partition" {
    defaults = { partition = "aws" }
  }
}

variables {
  namespace          = "dvtca"
  stage              = "test"
  name               = "unit"
  attributes         = ["workers"]
  cluster_name       = "dvtca-test-unit-cluster"
  subnet_ids         = ["subnet-aaaaaaaaaaaaaaaaa", "subnet-bbbbbbbbbbbbbbbbb"]
  kubernetes_version = "1.31"
}

run "node_group_created" {
  command = plan
  assert {
    condition     = length(aws_eks_node_group.this) == 1
    error_message = "Exactly one node group must be planned."
  }
}

run "role_created_with_standard_policies" {
  command = plan
  assert {
    condition     = length(aws_iam_role.node) == 1
    error_message = "A node IAM role must be created by default."
  }
  assert {
    condition     = length(aws_iam_role_policy_attachment.managed) == 4
    error_message = "Worker + CNI + ECR + SSM managed policies must be attached."
  }
}

run "byo_role_skips_creation" {
  command = plan
  variables {
    node_role_arn = "arn:aws:iam::111122223333:role/my-nodes"
  }
  assert {
    condition     = length(aws_iam_role.node) == 0
    error_message = "No role should be created when node_role_arn is supplied."
  }
}

run "launch_template_created_and_hardened" {
  command = plan
  assert {
    condition     = length(aws_launch_template.node) == 1
    error_message = "A launch template must be created by default."
  }
  assert {
    condition     = aws_launch_template.node[0].metadata_options[0].http_tokens == "required"
    error_message = "IMDSv2 (http_tokens=required) must be enforced."
  }
  assert {
    condition     = tostring(aws_launch_template.node[0].metadata_options[0].http_put_response_hop_limit) == "1"
    error_message = "IMDS hop limit must default to 1 (containers blocked)."
  }
}

run "byo_launch_template_skips_creation" {
  command = plan
  variables {
    create_launch_template = false
    launch_template_id     = "lt-00000000000000000"
  }
  assert {
    condition     = length(aws_launch_template.node) == 0
    error_message = "No launch template should be created when create_launch_template = false."
  }
}

run "capacity_and_ami_defaults" {
  command = plan
  assert {
    condition     = aws_eks_node_group.this[0].capacity_type == "ON_DEMAND"
    error_message = "Default capacity type must be ON_DEMAND."
  }
  assert {
    condition     = aws_eks_node_group.this[0].ami_type == "AL2023_ARM_64_STANDARD"
    error_message = "Default AMI type must be AL2023 ARM (Graviton)."
  }
}

run "scaling_config_defaults" {
  command = plan
  assert {
    condition     = tostring(aws_eks_node_group.this[0].scaling_config[0].min_size) == "1" && tostring(aws_eks_node_group.this[0].scaling_config[0].max_size) == "3"
    error_message = "Default scaling must be min 1 / max 3."
  }
}

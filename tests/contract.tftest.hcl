# Contract tests — naming + key inputs stay stable across minor/patch versions.

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
  name               = "contract"
  attributes         = ["workers"]
  cluster_name       = "dvtca-test-contract-cluster"
  subnet_ids         = ["subnet-aaaaaaaaaaaaaaaaa", "subnet-bbbbbbbbbbbbbbbbb"]
  kubernetes_version = "1.31"
}

run "node_group_name_from_label" {
  command = plan
  assert {
    condition     = aws_eks_node_group.this[0].node_group_name == "dvtca-test-contract-workers"
    error_message = "Node group name must compose namespace-stage-name-attributes."
  }
}

run "role_name_from_label" {
  command = plan
  assert {
    condition     = aws_iam_role.node[0].name == "dvtca-test-contract-workers-node"
    error_message = "Node role name must be <id>-node."
  }
}

run "default_instance_types_graviton" {
  command = plan
  assert {
    condition     = aws_eks_node_group.this[0].instance_types == tolist(["t4g.large"])
    error_message = "Default instance type must be the Graviton t4g.large."
  }
}

run "version_passed_through" {
  command = plan
  assert {
    condition     = aws_eks_node_group.this[0].version == "1.31"
    error_message = "Explicit kubernetes_version must be used."
  }
}

run "label_value_case_lower_applied" {
  command = plan
  variables {
    name = "Contract"
  }
  assert {
    condition     = aws_eks_node_group.this[0].node_group_name == "dvtca-test-contract-workers"
    error_message = "label_value_case=lower must lowercase the composed id."
  }
}

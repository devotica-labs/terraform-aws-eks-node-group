plugin "aws" {
  enabled = true
  version = "0.30.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# tflint-ruleset-aws 0.30.0 predates the AL2023 EKS AMI types; its ami_type
# enum is stale and wrongly rejects AL2023_ARM_64_STANDARD (a current, valid
# value). Disable the outdated check.
rule "aws_eks_node_group_invalid_ami_type" { enabled = false }

rule "terraform_deprecated_interpolation" { enabled = true }
rule "terraform_documented_outputs"       { enabled = true }
rule "terraform_documented_variables"     { enabled = true }
rule "terraform_naming_convention"        { enabled = true }
rule "terraform_required_providers"       { enabled = true }
rule "terraform_required_version"         { enabled = true }
rule "terraform_typed_variables"          { enabled = true }
rule "terraform_unused_declarations"      { enabled = true }

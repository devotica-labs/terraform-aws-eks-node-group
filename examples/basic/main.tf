# ---------------------------------------------------------------------------
# Provider block — CI-friendly skip flags + non-AWS-shaped placeholder creds.
# ---------------------------------------------------------------------------
provider "aws" {
  region                      = "ap-south-1"
  access_key                  = "not-a-real-aws-key"
  secret_key                  = "not-a-real-aws-secret"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}

# Uses local path during development.
# Change to Registry source after first release:
#   source  = "devotica-labs/eks-node-group/aws"
#   version = "~> 0.1"

module "node_group" {
  source = "../.."

  # Name composes to: dvtca-sandbox-platform-workers
  namespace  = "dvtca"
  stage      = "sandbox"
  name       = "platform"
  attributes = ["workers"]

  cluster_name = "dvtca-sandbox-platform-cluster"
  subnet_ids   = ["subnet-aaaaaaaaaaaaaaaaa", "subnet-bbbbbbbbbbbbbbbbb"]

  # Pin the version explicitly so the example plans without reading the cluster.
  kubernetes_version = "1.31"

  # Fintech defaults cover the rest: Graviton (t4g) on AL2023, 1-3 nodes,
  # encrypted gp3 disk, IMDSv2 required with hop limit 1, SSM (no SSH).

  tags = {
    Environment = "sandbox"
    Project     = "terraform-aws-eks-node-group"
    Owner       = "platform@devotica.com"
    CostCenter  = "PLATFORM-OSS"
    ManagedBy   = "Terraform"
    Repo        = "https://github.com/devotica-labs/terraform-aws-eks-node-group"
  }
}

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

  # Name composes to: dvtca-aps1-prod-payments-app
  namespace   = "dvtca"
  environment = "aps1"
  stage       = "prod"
  name        = "payments"
  attributes  = ["app"]

  cluster_name       = "dvtca-aps1-prod-payments-cluster"
  subnet_ids         = ["subnet-aaaaaaaaaaaaaaaaa", "subnet-bbbbbbbbbbbbbbbbb", "subnet-ccccccccccccccccc"]
  kubernetes_version = "1.31"

  # Larger Graviton nodes, 3-12 range.
  instance_types = ["m7g.large", "m7g.xlarge"]
  ami_type       = "AL2023_ARM_64_STANDARD"
  desired_size   = 3
  min_size       = 3
  max_size       = 12

  # Encrypt node disks with a workload KMS key (a terraform-aws-kms output).
  disk_size       = 100
  disk_encrypted  = true
  disk_kms_key_id = "arn:aws:kms:ap-south-1:111122223333:key/00000000-0000-0000-0000-000000000000"

  # Dedicate this group to the payments workload.
  kubernetes_labels = {
    workload = "payments"
  }
  kubernetes_taints = [
    { key = "dedicated", value = "payments", effect = "NO_SCHEDULE" },
  ]

  # Extra permissions for the nodes (e.g. an app instance policy).
  node_role_additional_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
  ]

  tags = {
    Environment = "production"
    Project     = "payments"
    Owner       = "platform@devotica.com"
    CostCenter  = "PLATFORM"
    ManagedBy   = "Terraform"
    Repo        = "https://github.com/devotica-labs/terraform-aws-eks-node-group"
  }
}

locals {
  create_role   = local.enabled && var.node_role_arn == null
  node_role_arn = local.create_role ? one(aws_iam_role.node[*].arn) : var.node_role_arn

  # Managed policies every EKS worker node needs, plus SSM so operators use
  # Session Manager instead of opening SSH (port 22) to the nodes.
  managed_policy_arns = local.create_role ? toset([
    "arn:${one(data.aws_partition.current[*].partition)}:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:${one(data.aws_partition.current[*].partition)}:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:${one(data.aws_partition.current[*].partition)}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:${one(data.aws_partition.current[*].partition)}:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ]) : toset([])
}

data "aws_partition" "current" {
  count = local.create_role ? 1 : 0
}

data "aws_iam_policy_document" "assume_role" {
  count = local.create_role ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node" {
  count                = local.create_role ? 1 : 0
  name                 = "${local.id}-node"
  assume_role_policy   = one(data.aws_iam_policy_document.assume_role[*].json)
  permissions_boundary = var.node_role_permissions_boundary
  tags                 = local.tags
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each   = local.managed_policy_arns
  policy_arn = each.value
  role       = one(aws_iam_role.node[*].name)
}

resource "aws_iam_role_policy_attachment" "additional" {
  count      = local.create_role ? length(var.node_role_additional_policy_arns) : 0
  policy_arn = var.node_role_additional_policy_arns[count.index]
  role       = one(aws_iam_role.node[*].name)
}

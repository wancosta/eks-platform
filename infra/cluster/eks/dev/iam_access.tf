# ---------------------------------------------------------------------------
# Roles IAM para acesso ao cluster via kubectl (EKS access entries)
#
# IMPORTANTE: as roles NAO podem ter "path". O EKS rejeita com
# "The specified principalArn is invalid: invalid principal" quando o ARN
# tem path ou quando a role ainda nao existe.
# ---------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

locals {
  # Se nenhum principal for informado, qualquer identidade da conta com
  # permissao sts:AssumeRole pode assumir as roles.
  trusted_principals = length(var.iam_role_trusted_arns) > 0 ? var.iam_role_trusted_arns : [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
  ]
}

data "aws_iam_policy_document" "assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = local.trusted_principals
    }
  }
}

resource "aws_iam_role" "eks_admins" {
  name               = var.admin_role_name
  description        = "Acesso admin ao cluster ${var.name} via EKS access entry"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

resource "aws_iam_role" "eks_viewers" {
  name               = var.viewer_role_name
  description        = "Acesso somente leitura ao cluster ${var.name} via EKS access entry"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

# Permite rodar `aws eks update-kubeconfig` com essas roles
data "aws_iam_policy_document" "eks_describe" {
  statement {
    effect    = "Allow"
    actions   = ["eks:DescribeCluster", "eks:ListClusters"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "admins_eks_describe" {
  name   = "eks-describe"
  role   = aws_iam_role.eks_admins.id
  policy = data.aws_iam_policy_document.eks_describe.json
}

resource "aws_iam_role_policy" "viewers_eks_describe" {
  name   = "eks-describe"
  role   = aws_iam_role.eks_viewers.id
  policy = data.aws_iam_policy_document.eks_describe.json
}

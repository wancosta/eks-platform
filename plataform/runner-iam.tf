# Permite que os pods dos runners façam push no ECR sem chaves de acesso (IRSA)
data "aws_iam_openid_connect_provider" "this" {
  url = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
}

data "aws_iam_policy_document" "runner_ecr" {
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = ["arn:aws:ecr:${var.region}:${data.aws_caller_identity.current.account_id}:repository/*"]
  }
}

resource "aws_iam_policy" "runner_ecr" {
  name   = "${var.cluster_name}-gha-runner-ecr"
  policy = data.aws_iam_policy_document.runner_ecr.json
}

module "runner_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.52"

  role_name = "${var.cluster_name}-gha-runner"

  role_policy_arns = {
    ecr = aws_iam_policy.runner_ecr.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = data.aws_iam_openid_connect_provider.this.arn
      namespace_service_accounts = ["arc-runners:gha-runner"]
    }
  }
}

resource "kubernetes_service_account_v1" "runner" {
  metadata {
    name      = "gha-runner"
    namespace = kubernetes_namespace_v1.arc_runners.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = module.runner_irsa.iam_role_arn
    }
  }
}

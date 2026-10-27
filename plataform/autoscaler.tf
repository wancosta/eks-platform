# Opcional: enable_cluster_autoscaler = true
data "aws_iam_role" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0
  name  = "${var.cluster_name}-cluster-autoscaler"
}

resource "helm_release" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  name       = "cluster-autoscaler"
  namespace  = "kube-system"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = lookup(var.chart_versions, "cluster-autoscaler", null)

  values = [yamlencode({
    autoDiscovery = {
      clusterName = var.cluster_name
    }
    awsRegion = var.region
    rbac = {
      serviceAccount = {
        name = "cluster-autoscaler"
        annotations = {
          "eks.amazonaws.com/role-arn" = data.aws_iam_role.cluster_autoscaler[0].arn
        }
      }
    }
    # Use uma tag de imagem compatível com a versão minor do seu cluster
    # image = { tag = "v1.33.x" }
  })]
}

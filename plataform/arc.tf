# ---------------------------------------------------------------------------
# Namespaces
# ---------------------------------------------------------------------------
resource "kubernetes_namespace_v1" "arc_systems" {
  metadata {
    name = "arc-systems"
  }
}

resource "kubernetes_namespace_v1" "arc_runners" {
  metadata {
    name = "arc-runners"
    labels = {
      "app.kubernetes.io/part-of" = "github-runners"
    }
  }
}

# Limite o número de pods de runners no namespace
resource "kubernetes_resource_quota_v1" "runners" {
  metadata {
    name      = "runners-quota"
    namespace = kubernetes_namespace_v1.arc_runners.metadata[0].name
  }

  spec {
    hard = {
      pods = "60"
    }
  }
}

# ---------------------------------------------------------------------------
# Credenciais do GitHub App (usadas pelo controller/listener)
# ---------------------------------------------------------------------------
resource "kubernetes_secret_v1" "github_app" {
  metadata {
    name      = "gh-app-secret"
    namespace = kubernetes_namespace_v1.arc_runners.metadata[0].name
  }

  data = {
    github_app_id              = var.github_app_id
    github_app_installation_id = var.github_app_installation_id
    github_app_private_key     = var.github_app_private_key
  }
}

# ---------------------------------------------------------------------------
# Controller (arc-systems)
# ---------------------------------------------------------------------------
resource "helm_release" "arc_controller" {
  name       = "arc"
  namespace  = kubernetes_namespace_v1.arc_systems.metadata[0].name
  repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart      = "gha-runner-scale-set-controller"
  version    = lookup(var.chart_versions, "arc", null)

  values = [yamlencode({
    replicaCount = 1
  })]
}

# ---------------------------------------------------------------------------
# Runner scale set (arc-runners): o NOME DO RELEASE é o label do runs-on
# ---------------------------------------------------------------------------
resource "helm_release" "arc_runner_set" {
  name       = var.runner_scale_set_name
  namespace  = kubernetes_namespace_v1.arc_runners.metadata[0].name
  repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart      = "gha-runner-scale-set"
  version    = lookup(var.chart_versions, "arc-runner-set", null)

  values = [yamlencode({
    githubConfigUrl    = var.github_config_url
    githubConfigSecret = kubernetes_secret_v1.github_app.metadata[0].name
    minRunners         = var.runner_min
    maxRunners         = var.runner_max

    # dind = sidecar com Docker daemon, permite "docker build" nos workflows
    containerMode = {
      type = "dind"
    }

    template = {
      spec = {
        serviceAccountName = kubernetes_service_account_v1.runner.metadata[0].name
        containers = [{
          name    = "runner"
          image   = var.runner_image # imagem customizada do ECR
          command = ["/home/runner/run.sh"]
          resources = {
            requests = { cpu = "1", memory = "2Gi" }
            limits   = { cpu = "4", memory = "8Gi" }
          }
        }]
      }
    }
  })]

  depends_on = [helm_release.arc_controller]
}

resource "helm_release" "sonarqube" {
  name             = "sonarqube"
  namespace        = "sonarqube"
  create_namespace = true
  repository       = "https://SonarSource.github.io/helm-chart-sonarqube"
  chart            = "sonarqube"
  version          = lookup(var.chart_versions, "sonarqube", null)
  timeout          = 1200

  # Confira os nomes exatos dos valores da versão escolhida: helm show values sonarqube/sonarqube
  values = [yamlencode({
    community = {
      enabled = true # SonarQube Community Build
    }
    ingress = {
      enabled          = true
      ingressClassName = "traefik"
      hosts = [{
        name = var.sonar_hostname
        path = "/"
      }]
    }
    persistence = {
      enabled      = true
      storageClass = "gp3"
      size         = "20Gi"
    }
    resources = {
      requests = { cpu = "500m", memory = "2Gi" }
      limits   = { cpu = "2", memory = "6Gi" }
    }
  })]

  set_sensitive {
    name  = "monitoringPasscode"
    value = var.sonar_monitoring_passcode
  }

  depends_on = [helm_release.traefik, kubernetes_storage_class_v1.gp3]
}

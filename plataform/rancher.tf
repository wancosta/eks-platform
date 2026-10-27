resource "helm_release" "rancher" {
  name             = "rancher"
  namespace        = "cattle-system"
  create_namespace = true
  repository       = "https://releases.rancher.com/server-charts/stable"
  chart            = "rancher"
  version          = lookup(var.chart_versions, "rancher", null)
  timeout          = 1200

  values = [yamlencode({
    hostname = var.rancher_hostname
    replicas = 2
    ingress = {
      ingressClassName = "traefik"
      tls = {
        source = "external" # TLS termina no ALB (ACM): não precisa de cert-manager
      }
    }
  })]

  set_sensitive {
    name  = "bootstrapPassword"
    value = var.rancher_bootstrap_password
  }

  depends_on = [helm_release.traefik, kubernetes_storage_class_v1.gp3]
}

# Ingress controller exposto como NodePort fixo -> é o destino do Target Group do ALB.
resource "helm_release" "traefik" {
  name             = "traefik"
  namespace        = "traefik"
  create_namespace = true
  repository       = "https://traefik.github.io/charts"
  chart            = "traefik"
  version          = lookup(var.chart_versions, "traefik", null)
  timeout          = 600

  values = [yamlencode({
    deployment = {
      replicas = 2
    }
    service = {
      type = "NodePort"
      spec = {
        externalTrafficPolicy = "Cluster"
      }
    }
    ports = {
      web = {
        nodePort = var.ingress_node_port
        # O ALB (dentro da VPC) envia X-Forwarded-Proto/For: precisamos confiar neles,
        # senão o Rancher acha que a conexão é HTTP e entra em loop de redirect.
        forwardedHeaders = {
          trustedIPs = [var.vpc_cidr]
        }
      }
    }
    ingressClass = {
      enabled        = true
      isDefaultClass = true
    }
  })]
}

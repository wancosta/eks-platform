region             = "us-east-2"
name               = "eks-platform"
kubernetes_version = "1.33" # confira a matriz de suporte do Rancher

# Nós (ASG)
node_instance_type = "m6i.large"
node_min_size      = 1
node_desired_size  = 2
node_max_size      = 3

# ALB / DNS
acm_certificate_arn = "arn:aws:acm:us-east-2:167871570924:certificate/0afdaaf2-e257-4ed6-8cc0-d977d489c66b"
route53_zone_id     = "Z0786676RK6RPZ6GQ5H8"
hostnames           = ["rancher.wvscosta.com.br", "sonar.wvscosta.com.br"]

# Restrinja em produção (seu IP / VPN)
alb_allowed_cidrs = ["0.0.0.0/0"]
api_allowed_cidrs = ["0.0.0.0/0"]

# Acesso kubectl via IAM
# As roles "Admins" e "Viewers" agora são CRIADAS pelo Terraform (iam_access.tf)
# e ligadas ao cluster automaticamente. NÃO as repita nas listas abaixo.
admin_role_name  = "Admins"
viewer_role_name = "Viewers"

# Quem pode assumir essas roles (vazio = qualquer identidade da conta com sts:AssumeRole).
# Recomendado restringir, por exemplo:
# iam_role_trusted_arns = ["arn:aws:iam::167871570924:user/seu-usuario"]
iam_role_trusted_arns = []

# Apenas para principals EXTERNOS que já existem (ARN sem path). Normalmente vazio.
admin_iam_arns    = []
readonly_iam_arns = []

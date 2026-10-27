variable "region" {
  type    = string
  default = "us-east-2"
}

variable "name" {
  description = "Nome do cluster e prefixo dos recursos"
  type        = string
  default     = "eks-platform"
}

variable "kubernetes_version" {
  description = "Versão do Kubernetes. Confira a matriz de suporte do Rancher antes de subir."
  type        = string
  default     = "1.33"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "single_nat_gateway" {
  description = "true = 1 NAT (barato); false = 1 NAT por AZ (alta disponibilidade)"
  type        = bool
  default     = true
}

# --- Nós (ASG) ---
variable "node_instance_type" {
  type    = string
  default = "m6i.xlarge"
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 6
}

variable "node_desired_size" {
  type    = number
  default = 3
}

variable "node_disk_size" {
  type    = number
  default = 80
}

# --- Load balancer ---
variable "ingress_node_port" {
  description = "NodePort fixo do Traefik que o Target Group usa"
  type        = number
  default     = 30080
}

variable "acm_certificate_arn" {
  description = "ARN do certificado ACM. Vazio = ALB só com HTTP (não recomendado)."
  type        = string
  default     = ""
}

variable "alb_allowed_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "api_allowed_cidrs" {
  description = "CIDRs com acesso ao endpoint público da API do EKS"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# --- DNS opcional ---
variable "route53_zone_id" {
  type    = string
  default = ""
}

variable "hostnames" {
  description = "Hostnames que apontam para o ALB (ex.: rancher.exemplo.com, sonar.exemplo.com)"
  type        = list(string)
  default     = []
}

# --- Acesso ao cluster via kubectl (EKS access entries) ---
variable "admin_role_name" {
  description = "Nome da role IAM (criada aqui) com acesso admin ao cluster. Sem path."
  type        = string
  default     = "Admins"
}

variable "viewer_role_name" {
  description = "Nome da role IAM (criada aqui) com acesso somente leitura ao cluster. Sem path."
  type        = string
  default     = "Viewers"
}

variable "iam_role_trusted_arns" {
  description = "ARNs (usuários/roles) autorizados a assumir as roles Admins/Viewers. Vazio = root da conta (qualquer identidade com sts:AssumeRole)."
  type        = list(string)
  default     = []
}

variable "admin_iam_arns" {
  description = "Principals IAM EXTERNOS ja existentes com acesso admin ao cluster (ARN sem path). Não inclua aqui as roles criadas por este projeto."
  type        = list(string)
  default     = []
}

variable "readonly_iam_arns" {
  description = "Principals IAM EXTERNOS ja existentes com acesso somente leitura ao cluster (ARN sem path). Não inclua aqui as roles criadas por este projeto."
  type        = list(string)
  default     = []
}

# --- ECR / imagem do runner ---
variable "ecr_repositories" {
  type    = list(string)
  default = ["gha-runner"]
}

variable "runner_image_tag" {
  type    = string
  default = "v1"
}

variable "build_runner_image" {
  description = "Faz build + push da imagem do runner durante o apply (exige Docker local)"
  type        = bool
  default     = false
}

variable "tags" {
  type = map(string)
  default = {
    Project   = "eks-platform"
    ManagedBy = "terraform"
  }
}

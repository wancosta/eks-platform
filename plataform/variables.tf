variable "region" {
  type    = string
  default = "us-east-2"
}

variable "cluster_name" {
  type    = string
  default = "eks-platform"
}

variable "vpc_cidr" {
  description = "CIDR da VPC (Traefik confia nos headers X-Forwarded-* vindos do ALB)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "ingress_node_port" {
  type    = number
  default = 30080
}

variable "chart_versions" {
  description = "Fixe as versões dos charts (traefik, rancher, sonarqube, arc, arc-runner-set, cluster-autoscaler). Vazio = última."
  type        = map(string)
  default     = {}
}

# --- Rancher ---
variable "rancher_hostname" {
  type = string
}

variable "rancher_bootstrap_password" {
  type      = string
  sensitive = true
}

# --- SonarQube ---
variable "sonar_hostname" {
  type = string
}

variable "sonar_monitoring_passcode" {
  type      = string
  sensitive = true
}

# --- GitHub Actions Runner Controller ---
variable "github_config_url" {
  description = "https://github.com/wancosta/eks-platform (ou https://github.com/wancosta/eks-platform)"
  type        = string
}

variable "github_app_id" {
  type      = string
  sensitive = true
}

variable "github_app_installation_id" {
  type      = string
  sensitive = true
}

variable "github_app_private_key" {
  type      = string
  sensitive = true
}

variable "runner_scale_set_name" {
  description = "Vira o label usado em runs-on nos workflows"
  type        = string
  default     = "eks-runners"
}

variable "runner_image" {
  description = "URL completa da imagem no ECR (output runner_image do stack 01)"
  type        = string
}

variable "runner_min" {
  type    = number
  default = 1
}

variable "runner_max" {
  type    = number
  default = 10
}

variable "enable_cluster_autoscaler" {
  type    = bool
  default = false
}

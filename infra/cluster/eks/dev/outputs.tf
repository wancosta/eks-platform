output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "vpc_cidr" {
  value = module.vpc.vpc_cidr_block
}

output "alb_dns_name" {
  description = "Aponte seus hostnames (CNAME/ALIAS) para este endereço"
  value       = aws_lb.this.dns_name
}

output "target_group_arn" {
  value = aws_lb_target_group.ingress.arn
}

output "asg_name" {
  description = "Nome do ASG dos nós"
  value       = module.eks.self_managed_node_groups["default"].autoscaling_group_name
}

output "ecr_repository_urls" {
  value = { for k, v in aws_ecr_repository.this : k => v.repository_url }
}

output "runner_image" {
  value = local.runner_image
}

output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region}"
}

output "admin_role_arn" {
  description = "Role com acesso admin ao cluster"
  value       = aws_iam_role.eks_admins.arn
}

output "viewer_role_arn" {
  description = "Role com acesso somente leitura ao cluster"
  value       = aws_iam_role.eks_viewers.arn
}

output "kubeconfig_command_admin" {
  description = "Gera o kubeconfig assumindo a role Admins"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region} --role-arn ${aws_iam_role.eks_admins.arn}"
}

output "kubeconfig_command_viewer" {
  description = "Gera o kubeconfig assumindo a role Viewers"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region} --role-arn ${aws_iam_role.eks_viewers.arn}"
}

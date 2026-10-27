locals {
  admin_policy_associations = {
    admin = {
      policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
      access_scope = { type = "cluster" }
    }
  }

  view_policy_associations = {
    view = {
      policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
      access_scope = { type = "cluster" }
    }
  }

  access_entries = merge(
    # Roles criadas neste projeto: chaves ESTATICAS.
    # (O ARN so é conhecido no apply; se a chave dependesse dele, o Terraform
    # falharia com "for_each keys cannot be determined until apply".)
    {
      admins = {
        principal_arn       = aws_iam_role.eks_admins.arn
        policy_associations = local.admin_policy_associations
      }
      viewers = {
        principal_arn       = aws_iam_role.eks_viewers.arn
        policy_associations = local.view_policy_associations
      }
    },

    # Principals EXTERNOS ja existentes (strings conhecidas no plan).
    # Use ARN sem path. Nao repita aqui as roles Admins/Viewers acima.
    {
      for arn in var.admin_iam_arns : "admin-${substr(md5(arn), 0, 8)}" => {
        principal_arn       = arn
        policy_associations = local.admin_policy_associations
      }
    },
    {
      for arn in var.readonly_iam_arns : "view-${substr(md5(arn), 0, 8)}" => {
        principal_arn       = arn
        policy_associations = local.view_policy_associations
      }
    },
  )
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.37"

  cluster_name    = var.name
  cluster_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = var.api_allowed_cidrs
  cluster_endpoint_private_access      = true

  enable_irsa                              = true
  authentication_mode                      = "API_AND_CONFIG_MAP"
  enable_cluster_creator_admin_permissions = true
  access_entries                           = local.access_entries

  cluster_enabled_log_types = ["api", "audit", "authenticator"]

  # O addon do EBS CSI é criado fora do módulo (evita dependência circular com o IRSA)
  cluster_addons = {
    coredns                = { most_recent = true }
    kube-proxy             = { most_recent = true }
    eks-pod-identity-agent = { most_recent = true, before_compute = true }
    vpc-cni                = { most_recent = true, before_compute = true }
  }

  # -------------------------------------------------------------------------
  # Nós EC2 em um ASG SEU (self-managed): você controla min/max/desired,
  # instance refresh, warm pool, políticas de scaling etc. direto no ASG.
  # -------------------------------------------------------------------------
  self_managed_node_groups = {
    default = {
      name          = "${var.name}-nodes"
      ami_type      = "AL2023_x86_64_STANDARD"
      instance_type = var.node_instance_type

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      # Registra automaticamente as instâncias no Target Group do ALB
      target_group_arns = [aws_lb_target_group.ingress.arn]

      # Mantenha health check "EC2". Com "ELB", nós novos seriam derrubados
      # enquanto o Traefik ainda não existe.
      health_check_type = "EC2"

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = var.node_disk_size
            volume_type           = "gp3"
            encrypted             = true
            delete_on_termination = true
          }
        }
      }

      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
      }

      instance_refresh = {
        strategy = "Rolling"
        preferences = {
          min_healthy_percentage = 66
        }
      }

      # Tags de auto-discovery do cluster-autoscaler (opcional)
      autoscaling_group_tags = {
        "k8s.io/cluster-autoscaler/enabled"     = "true"
        "k8s.io/cluster-autoscaler/${var.name}" = "owned"
      }

      iam_role_additional_policies = {
        ecr_read = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
        ssm      = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }
    }
  }
}

# ---------------------------------------------------------------------------
# IRSA: EBS CSI (volumes do SonarQube) e cluster-autoscaler (opcional)
# ---------------------------------------------------------------------------
module "ebs_csi_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.52"

  role_name             = "${var.name}-ebs-csi"
  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name                = module.eks.cluster_name
  addon_name                  = "aws-ebs-csi-driver"
  service_account_role_arn    = module.ebs_csi_irsa.iam_role_arn
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [module.eks]
}

module "cluster_autoscaler_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.52"

  role_name                        = "${var.name}-cluster-autoscaler"
  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = [module.eks.cluster_name]

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:cluster-autoscaler"]
    }
  }
}

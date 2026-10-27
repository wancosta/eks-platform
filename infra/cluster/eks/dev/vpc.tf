data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.21"

  name = "${var.name}-vpc"
  cidr = var.vpc_cidr
  azs  = local.azs

  # privadas /20 (nós) e públicas /24 (ALB, NAT)
  private_subnets = [for k, _ in local.azs : cidrsubnet(var.vpc_cidr, 4, k)]
  public_subnets  = [for k, _ in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 48)]

  enable_nat_gateway   = true
  single_nat_gateway   = var.single_nat_gateway
  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

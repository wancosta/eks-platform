locals {
  has_tls = var.acm_certificate_arn != ""
}

# ---------------------------------------------------------------------------
# Security Group do ALB
# ---------------------------------------------------------------------------
resource "aws_security_group" "alb" {
  name_prefix = "${var.name}-alb-"
  description = "ALB publico de ${var.name}"
  vpc_id      = module.vpc.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.name}-alb"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  for_each = toset(var.alb_allowed_cidrs)

  security_group_id = aws_security_group.alb.id
  description       = "HTTP"
  cidr_ipv4         = each.value
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  for_each = toset(var.alb_allowed_cidrs)

  security_group_id = aws_security_group.alb.id
  description       = "HTTPS"
  cidr_ipv4         = each.value
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

# O ALB só fala com os nós na porta do NodePort
resource "aws_vpc_security_group_egress_rule" "alb_to_nodes" {
  security_group_id            = aws_security_group.alb.id
  description                  = "ALB para NodePort dos nos"
  referenced_security_group_id = module.eks.node_security_group_id
  from_port                    = var.ingress_node_port
  to_port                      = var.ingress_node_port
  ip_protocol                  = "tcp"
}

# Os nós aceitam tráfego do ALB somente nessa porta
resource "aws_vpc_security_group_ingress_rule" "nodes_from_alb" {
  security_group_id            = module.eks.node_security_group_id
  description                  = "ALB para NodePort do Traefik"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.ingress_node_port
  to_port                      = var.ingress_node_port
  ip_protocol                  = "tcp"
}

# ---------------------------------------------------------------------------
# ALB + Target Group + Listeners
# ---------------------------------------------------------------------------
resource "aws_lb" "this" {
  name                       = "${var.name}-alb"
  load_balancer_type         = "application"
  internal                   = false
  subnets                    = module.vpc.public_subnets
  security_groups            = [aws_security_group.alb.id]
  drop_invalid_header_fields = true
  idle_timeout               = 120
}

resource "aws_lb_target_group" "ingress" {
  name                 = "${var.name}-ingress"
  port                 = var.ingress_node_port
  protocol             = "HTTP"
  target_type          = "instance"
  vpc_id               = module.vpc.vpc_id
  deregistration_delay = 30

  # O Traefik responde 404 para hosts desconhecidos: isso já indica "vivo".
  health_check {
    enabled             = true
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200-404"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = local.has_tls ? "redirect" : "forward"
    target_group_arn = local.has_tls ? null : aws_lb_target_group.ingress.arn

    dynamic "redirect" {
      for_each = local.has_tls ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }
}

resource "aws_lb_listener" "https" {
  count = local.has_tls ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ingress.arn
  }
}

# ---------------------------------------------------------------------------
# DNS opcional (Route 53) apontando os hostnames para o ALB
# ---------------------------------------------------------------------------
resource "aws_route53_record" "apps" {
  for_each = var.route53_zone_id == "" ? toset([]) : toset(var.hostnames)

  zone_id = var.route53_zone_id
  name    = each.value
  type    = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}

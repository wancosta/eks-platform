resource "aws_ecr_repository" "this" {
  for_each = toset(var.ecr_repositories)

  name                 = each.value
  image_tag_mutability = "MUTABLE"
  force_delete         = false # mude para true se quiser que o destroy apague imagens

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each   = aws_ecr_repository.this
  repository = each.value.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Manter as ultimas 20 imagens"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 20
      }
      action = { type = "expire" }
    }]
  })
}

locals {
  runner_repo_url = aws_ecr_repository.this["gha-runner"].repository_url
  runner_image    = "${local.runner_repo_url}:${var.runner_image_tag}"
}

# Build + push da imagem do runner. Reexecuta quando o Dockerfile ou a tag mudam.
resource "null_resource" "runner_image" {
  count = var.build_runner_image ? 1 : 0

  triggers = {
    dockerfile = filesha256("${path.module}/../runner-image/Dockerfile")
    image      = local.runner_image
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail
      aws ecr get-login-password --region ${var.region} \
        | docker login --username AWS --password-stdin ${split("/", local.runner_repo_url)[0]}
      docker build --platform linux/amd64 -t ${local.runner_image} ${path.module}/../runner-image
      docker push ${local.runner_image}
    EOT
  }
}

region       = "us-east-2"
cluster_name = "eks-platform"
vpc_cidr     = "10.0.0.0/16"

rancher_hostname = "rancher.wvscosta.com.br"
sonar_hostname   = "sonar.wvscosta.com.br"

github_config_url     = "https://github.com/wancosta"
runner_scale_set_name = "eks-runners"
runner_image          = "167871570924.dkr.ecr.us-east-2.amazonaws.com/gha-runner:v1"

# Segredos NÃO ficam aqui: use variáveis de ambiente TF_VAR_* (veja o passo a passo).

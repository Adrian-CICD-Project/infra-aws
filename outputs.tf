output "region" {
  value = var.region
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "eks_test_name" {
  value = module.eks_test.cluster_name
}

output "eks_prod_name" {
  value = module.eks_prod.cluster_name
}

output "eks_test_endpoint" {
  value = module.eks_test.cluster_endpoint
}

output "eks_prod_endpoint" {
  value = module.eks_prod.cluster_endpoint
}

output "github_app_secret_arn" {
  value = module.secrets.github_app_secret_arn
}

output "eso_role_arn" {
  value = module.secrets.eso_role_arn
}

data "aws_availability_zones" "available" {
  state = "available"
}

########################
# NETWORK (VPC) – odpowiednik Azure VNet
########################
module "network" {
  source      = "./modules/network"
  name_prefix = var.name_prefix
  vpc_cidr    = var.vpc_cidr
  azs         = slice(data.aws_availability_zones.available.names, 0, 2)
}

########################
# ECR – odpowiednik ACR
########################
module "ecr" {
  source   = "./modules/ecr"
  ecr_name = var.ecr_name
}

########################
# EKS TEST – odpowiednik AKS test
########################
module "eks_test" {
  source             = "./modules/eks"
  cluster_name       = var.eks_test_name
  eks_version        = var.eks_version
  subnet_ids         = concat(module.network.public_subnet_ids, module.network.private_subnet_ids)
  node_subnet_ids    = module.network.private_subnet_ids
  node_instance_type = var.node_instance_type
  node_count         = var.node_count
  capacity_type      = var.capacity_type
}

########################
# EKS PROD – odpowiednik AKS prod
########################
module "eks_prod" {
  source             = "./modules/eks"
  cluster_name       = var.eks_prod_name
  eks_version        = var.eks_version
  subnet_ids         = concat(module.network.public_subnet_ids, module.network.private_subnet_ids)
  node_subnet_ids    = module.network.private_subnet_ids
  node_instance_type = var.node_instance_type
  node_count         = var.node_count
  capacity_type      = var.capacity_type
}

########################
# SECRETS – odpowiednik Key Vault
########################
module "secrets" {
  source      = "./modules/secrets"
  name_prefix = var.name_prefix

  oidc_provider_arns = [
    module.eks_test.oidc_provider_arn,
    module.eks_prod.oidc_provider_arn,
  ]
  oidc_provider_urls = [
    module.eks_test.oidc_provider_url,
    module.eks_prod.oidc_provider_url,
  ]
}

########################
# AUTO-SHUTDOWN – scale-to-zero 18:00 (odpowiednik Azure Automation)
########################
module "auto_shutdown" {
  source            = "./modules/auto-shutdown"
  name_prefix       = var.name_prefix
  region            = var.region
  cluster_names     = [var.eks_test_name, var.eks_prod_name]
  shutdown_cron     = var.shutdown_cron
  schedule_timezone = var.schedule_timezone
}

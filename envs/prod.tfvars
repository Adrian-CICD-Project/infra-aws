######################################
# ENV PROD – AWS
######################################

region      = "eu-west-1"
name_prefix = "devops-poc01"

# --- ECR (odpowiednik ACR) ---
ecr_name = "adrian-java-app"

# --- Klastry EKS ---
eks_test_name = "devops-poc01-test"
eks_prod_name = "devops-poc01-prod"
eks_version   = "1.30"

# --- Węzły EC2 ---
node_instance_type = "t3.large"
node_count         = 1
capacity_type      = "ON_DEMAND"

# --- Auto-shutdown 18:00 ---
shutdown_cron     = "cron(0 18 * * ? *)"
schedule_timezone = "Europe/Warsaw"

tags = {
  project = "devops-final"
  env     = "prod"
  owner   = "adrian-dmytryk"
}

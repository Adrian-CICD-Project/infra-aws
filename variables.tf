# Minimalny, kosztooszczędny zestaw zmiennych – odpowiednik infra-azure
# Region tani i blisko westeurope: eu-west-1 (Irlandia)
variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "name_prefix" {
  type        = string
  description = "Prefix nazw zasobów"
  default     = "devops-poc01"
}

# --- Sieć ---
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

# --- ECR (odpowiednik ACR) ---
variable "ecr_name" {
  type    = string
  default = "adrian-java-app"
}

# --- Klastry EKS (parytet z AKS) ---
variable "eks_test_name" {
  type    = string
  default = "devops-poc01-test"
}

variable "eks_prod_name" {
  type    = string
  default = "devops-poc01-prod"
}

variable "eks_version" {
  type    = string
  default = "1.30"
}

# --- Węzły (EC2) ---
# t3.large (~odpowiednik B4ms): 2 vCPU / 8 GB. 1 węzeł na klaster.
variable "node_instance_type" {
  type    = string
  default = "t3.large"
}

variable "node_count" {
  type    = number
  default = 1
}

# ON_DEMAND domyślnie; przełącz na "SPOT" dla maksymalnej oszczędności.
variable "capacity_type" {
  type    = string
  default = "ON_DEMAND"
}

# --- Auto-shutdown ---
# Codzienne skalowanie węzłów do 0 (jak Azure auto-shutdown 18:00).
variable "shutdown_cron" {
  type        = string
  description = "Wyrażenie cron EventBridge Scheduler (UTC-aware via timezone)"
  default     = "cron(0 18 * * ? *)"
}

variable "schedule_timezone" {
  type    = string
  default = "Europe/Warsaw"
}

# --- Tagi governance ---
variable "tags" {
  type = map(string)
  default = {
    project = "devops-final"
    owner   = "adrian-dmytryk"
  }
}

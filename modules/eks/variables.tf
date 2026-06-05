variable "cluster_name" {
  type = string
}

variable "eks_version" {
  type = string
}

variable "subnet_ids" {
  type        = list(string)
  description = "Podsieci dla control plane (prywatne + publiczne)"
}

variable "node_subnet_ids" {
  type        = list(string)
  description = "Podsieci prywatne dla węzłów EC2"
}

variable "node_instance_type" {
  type = string
}

variable "node_count" {
  type = number
}

variable "capacity_type" {
  type        = string
  description = "ON_DEMAND lub SPOT"
}

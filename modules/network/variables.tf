variable "name_prefix" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "azs" {
  type        = list(string)
  description = "Dwie strefy dostępności – EKS wymaga min. 2 AZ"
}

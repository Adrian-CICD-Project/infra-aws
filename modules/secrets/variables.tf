variable "name_prefix" {
  type = string
}

variable "oidc_provider_arns" {
  type        = list(string)
  description = "ARN-y dostawców OIDC obu klastrów EKS (test + prod)"
}

variable "oidc_provider_urls" {
  type        = list(string)
  description = "URL-e dostawców OIDC (bez https://) obu klastrów"
}

variable "eso_namespace" {
  type    = string
  default = "external-secrets"
}

variable "eso_service_account" {
  type    = string
  default = "external-secrets"
}

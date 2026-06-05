variable "name_prefix" {
  type = string
}

variable "region" {
  type = string
}

variable "cluster_names" {
  type        = list(string)
  description = "Nazwy klastrów EKS do wygaszenia (test + prod)"
}

variable "node_group_name" {
  type        = string
  description = "Nazwa node group do skalowania (systempool)"
  default     = "systempool"
}

variable "shutdown_cron" {
  type        = string
  description = "Wyrażenie cron EventBridge Scheduler"
}

variable "schedule_timezone" {
  type = string
}

variable "role_name" {
  description = "Nombre del rol de IAM."
  type        = string
}

variable "oidc_provider_arn" {
  description = "Proveedor OIDC del cluster. Cambia en cada recreacion."
  type        = string
}

variable "oidc_provider_url" {
  description = "URL del proveedor OIDC sin el esquema, que es el formato en el que se escriben las condiciones."
  type        = string
}

variable "namespace" {
  description = "Namespace del ServiceAccount autorizado."
  type        = string
}

variable "service_account" {
  description = "Nombre del ServiceAccount autorizado."
  type        = string
}

variable "policy_name" {
  description = "Nombre de la politica en linea del rol."
  type        = string
}

variable "policy_json" {
  description = "Politica de permisos del rol, en JSON."
  type        = string
}
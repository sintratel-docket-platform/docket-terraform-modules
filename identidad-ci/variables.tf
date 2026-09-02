variable "github_org" {
  description = "Organización de GitHub que aloja los repositorios del proyecto."
  type        = string
}

variable "build_repositories" {
  description = "Repositorios cuyo job de build puede asumir el rol limitado a ECR."
  type        = list(string)
}

variable "infra_repository" {
  description = "Repositorio de infraestructura, único autorizado a asumir el rol que ejecuta Terraform."
  type        = string
}

variable "allowed_branches" {
  description = "Ramas desde las que se admite asumir los roles. Un rol asumible desde cualquier rama equivale a una credencial compartida."
  type        = list(string)
  default     = ["main"]
}

variable "ecr_repository_arns" {
  description = "Repositorios de ECR sobre los que el rol de build tiene permisos."
  type        = list(string)
}

variable "state_bucket_arn" {
  description = "Bucket del estado de Terraform, al que el rol de infraestructura necesita acceso de lectura y escritura."
  type        = string
}

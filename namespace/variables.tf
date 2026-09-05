variable "environment" {
  description = "Nombre del ambiente. Es tambien el nombre del namespace."
  type        = string
}

variable "pod_security_enforce" {
  description = "Nivel de Pod Security Admission que se rechaza."
  type        = string
  default     = "baseline"
}

variable "quota" {
  description = "Techo de consumo del namespace."
  type = object({
    requests_cpu    = string
    requests_memory = string
    limits_cpu      = string
    limits_memory   = string
    pods            = string
    load_balancers  = string
    volume_claims   = string
  })
  default = {
    requests_cpu    = "1000m"
    requests_memory = "1.5Gi"
    limits_cpu      = "2000m"
    limits_memory   = "3Gi"
    pods            = "15"
    load_balancers  = "1"
    volume_claims   = "4"
  }
}

variable "container_defaults" {
  description = "Valores que recibe un contenedor que no declara resources."
  type = object({
    default_cpu    = string
    default_memory = string
    request_cpu    = string
    request_memory = string
    max_cpu        = string
    max_memory     = string
  })
  default = {
    default_cpu    = "200m"
    default_memory = "256Mi"
    request_cpu    = "50m"
    request_memory = "128Mi"
    max_cpu        = "1"
    max_memory     = "1Gi"
  }
}

variable "allow_exec" {
  description = "Permite al operador abrir una shell dentro de un pod."
  type        = bool
  default     = true
}

variable "operator_group" {
  description = "Grupo de Kubernetes al que se concede el rol de operador."
  type        = string
  default     = ""
}

variable "irsa_role_arn" {
  description = "ARN del rol de IAM que puede asumir el ServiceAccount del ambiente. Vacio lo deja sin acceso a AWS."
  type        = string
  default     = ""
}

variable "load_balancer_cidrs" {
  description = "Rangos desde los que se admite trafico entrante ademas del propio namespace."
  type        = list(string)
  default     = []
}

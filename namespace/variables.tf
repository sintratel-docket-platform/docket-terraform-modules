variable "environment" {
  description = "Environment name. It is also the namespace name."
  type        = string
}

variable "pod_security_enforce" {
  description = "Pod Security Admission level that is rejected."
  type        = string
  default     = "baseline"
}

variable "quota" {
  description = "Consumption ceiling of the namespace."
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
  description = "Values a container receives when it declares no resources."
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
  description = "Allows the operator to open a shell inside a pod."
  type        = bool
  default     = true
}

variable "operator_group" {
  description = "Kubernetes group granted the operator role."
  type        = string
  default     = ""
}

variable "irsa_role_arn" {
  description = "ARN of the IAM role the environment ServiceAccount may assume. Empty leaves it with no AWS access."
  type        = string
  default     = ""
}

variable "load_balancer_cidrs" {
  description = "Ranges allowed to send ingress traffic in addition to the namespace itself."
  type        = list(string)
  default     = []
}

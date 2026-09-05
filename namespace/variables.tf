variable "environment" {
  description = "Nombre del ambiente. Es tambien el nombre del namespace."
  type        = string
}

variable "pod_security_enforce" {
  description = "Nivel de Pod Security Admission que se rechaza."
  type        = string
  default     = "baseline"
}
variable "domain_name" {
  description = "Domain registered with the external registrar."
  type        = string
}

variable "subdomain" {
  description = "Subdomain the environments hang from."
  type        = string
  default     = "docket"
}

variable "validate_certificate" {
  description = "Wait for ACM to validate the certificate. Requires the nameservers to be delegated already."
  type        = bool
  default     = false
}

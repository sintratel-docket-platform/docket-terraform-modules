variable "name_prefix" {
  description = "Prefix for every resource name this module creates. Keeps the module reusable: it names nothing after a particular project."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*$", var.name_prefix))
    error_message = "The prefix must be lowercase alphanumeric, optionally hyphen separated."
  }
}

variable "domain_name" {
  description = "Domain registered with the external registrar."
  type        = string
}

variable "subdomain" {
  description = "Subdomain the environments hang from."
  type        = string
}

variable "validate_certificate" {
  description = "Wait for ACM to validate the certificate. Requires the nameservers to be delegated already."
  type        = bool
  default     = false
}

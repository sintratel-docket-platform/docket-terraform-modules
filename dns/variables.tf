variable "domain_name" {
  description = "Dominio registrado en el registrador externo."
  type        = string
}

variable "subdomain" {
  description = "Subdominio bajo el que cuelgan los ambientes."
  type        = string
  default     = "docket"
}

variable "validate_certificate" {
  description = "Esperar a que ACM valide el certificado. Requiere que los nameservers ya esten delegados."
  type        = bool
  default     = false
}

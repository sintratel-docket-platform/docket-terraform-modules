variable "environment" {
  description = "Nombre del ambiente. Determina el prefijo del árbol de parámetros."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "El ambiente debe ser dev, staging o prod."
  }
}

variable "parameter_names" {
  description = "Parameter names created under the environment prefix."
  type        = list(string)
}

variable "parameter_value_versions" {
  description = "Rotation version indexed by parameter name; increment a value to write that parameter again."
  type        = map(number)
}

variable "parameter_values" {
  description = "Write-only values indexed by parameter name."
  type        = map(string)
  sensitive   = true
  ephemeral   = true
}

variable "kms_key_id" {
  description = "Clave de KMS con la que se cifran los parámetros. Si se deja vacío, SSM usa la clave gestionada por AWS, que no tiene costo."
  type        = string
  default     = ""
}

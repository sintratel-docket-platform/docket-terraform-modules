variable "environment" {
  description = "Nombre del ambiente. Determina el prefijo del árbol de parámetros."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "El ambiente debe ser dev, staging o prod."
  }
}

variable "parameter_names" {
  description = "Nombres de los parámetros que se crean bajo el prefijo del ambiente. El módulo crea la estructura con un valor de marcador, y los valores reales se cargan aparte para que no queden versionados."
  type        = list(string)
}

variable "kms_key_id" {
  description = "Clave de KMS con la que se cifran los parámetros. Si se deja vacío, SSM usa la clave gestionada por AWS, que no tiene costo."
  type        = string
  default     = ""
}

variable "service_names" {
  description = "Nombres de los microservicios. Se crea un repositorio de ECR por cada uno."
  type        = list(string)
}

variable "max_image_count" {
  description = "Número de imágenes que se conservan por repositorio. La capa gratuita de ECR cubre 500 MB al mes, así que la poda no es opcional."
  type        = number
  default     = 10
}

variable "scan_on_push" {
  description = "Si es cierto, ECR escanea cada imagen publicada en busca de vulnerabilidades conocidas."
  type        = bool
  default     = true
}

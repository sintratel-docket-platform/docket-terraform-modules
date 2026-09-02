variable "vpc_cidr" {
  description = "Rango de direcciones de la VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Zonas de disponibilidad donde se reparten las subredes. EKS exige al menos dos."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "EKS requiere subredes en al menos dos zonas de disponibilidad."
  }
}

variable "public_subnet_cidrs" {
  description = "Rangos de las subredes públicas, una por zona. Alojan el balanceador y el NAT Gateway."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "Rangos de las subredes privadas, una por zona. Alojan los nodos del clúster."
  type        = list(string)
}

variable "cluster_name" {
  description = "Nombre del clúster de EKS. Las subredes se etiquetan con él para que el AWS Load Balancer Controller pueda descubrirlas."
  type        = string
}

variable "single_nat_gateway" {
  description = "Si es cierto, despliega un único NAT Gateway compartido por todas las zonas. Ahorra costo a cambio de perder la salida a internet de una zona si cae la zona del NAT."
  type        = bool
  default     = true
}

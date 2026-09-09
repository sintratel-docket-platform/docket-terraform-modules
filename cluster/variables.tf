variable "cluster_name" {
  description = "Nombre del clúster de EKS."
  type        = string
}

variable "kubernetes_version" {
  description = "Versión de Kubernetes del plano de control."
  type        = string
}

variable "private_subnet_ids" {
  description = "Subredes privadas donde se colocan los nodos."
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Subredes públicas donde el AWS Load Balancer Controller crea el balanceador."
  type        = list(string)
}

variable "node_instance_type" {
  description = "Tipo de instancia de los nodos. El límite de pods por nodo depende de este valor, y t3.small no alcanza para los tres ambientes."
  type        = string
  default     = "t3.medium"
}

variable "node_desired_size" {
  description = "Número de nodos con los que arranca el node group."
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Número mínimo de nodos del node group."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Número máximo de nodos del node group."
  type        = number
  default     = 3
}

variable "node_disk_size" {
  description = "Tamaño en GB del volumen de cada nodo."
  type        = number
  default     = 20
}

variable "public_access_cidrs" {
  description = "CIDR ranges allowed to reach the public EKS API endpoint."
  type        = list(string)

  validation {
    condition     = length(var.public_access_cidrs) > 0 && !contains(var.public_access_cidrs, "0.0.0.0/0")
    error_message = "Provide at least one explicit CIDR; 0.0.0.0/0 is not allowed."
  }
}

variable "enabled_log_types" {
  description = "EKS control-plane log types sent to CloudWatch."
  type        = list(string)
  default     = ["audit", "authenticator"]
}

variable "oidc_thumbprints" {
  description = "Huellas del certificado del emisor OIDC del cluster."
  type        = list(string)
  default     = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]
}

variable "node_security_group_id" {
  description = "Security group de los nodos, creado por el modulo de red."
  type        = string
}

variable "node_capacity_type" {
  description = "ON_DEMAND o SPOT. El tipo de capacidad de los nodos."
  type        = string
  default     = "ON_DEMAND"
}

variable "cluster_admin_principals" {
  description = "ARNs de IAM que reciben administracion del cluster."
  type        = list(string)
}

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

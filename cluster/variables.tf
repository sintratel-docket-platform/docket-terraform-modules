variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version of the control plane."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets where the nodes are placed."
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnets where the AWS Load Balancer Controller creates the load balancer."
  type        = list(string)
}

variable "node_instance_type" {
  description = "Node instance type. The pod limit per node derives from this value, and t3.small is not enough for the three environments."
  type        = string
  default     = "t3.medium"
}

variable "node_desired_size" {
  description = "Number of nodes the node group starts with."
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of nodes in the node group."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of nodes in the node group."
  type        = number
  default     = 3
}

variable "node_disk_size" {
  description = "Size in GB of each node volume."
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
  description = "Certificate thumbprints of the cluster OIDC issuer."
  type        = list(string)
  default     = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]
}

variable "node_security_group_id" {
  description = "Node security group, created by the network module."
  type        = string
}

variable "node_capacity_type" {
  description = "ON_DEMAND or SPOT. Capacity type of the nodes."
  type        = string
  default     = "ON_DEMAND"
}

variable "cluster_admin_principals" {
  description = "IAM ARNs granted administrative access to the cluster."
  type        = list(string)
}

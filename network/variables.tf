variable "vpc_cidr" {
  description = "Address range of the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones the subnets are spread across. EKS requires at least two."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "EKS requires subnets in at least two availability zones."
  }
}

variable "public_subnet_cidrs" {
  description = "Ranges of the public subnets, one per zone. They host the load balancer and the NAT Gateway."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "Ranges of the private subnets, one per zone. They host the cluster nodes."
  type        = list(string)
}

variable "cluster_name" {
  description = "Name of the EKS cluster. Subnets are tagged with it so the AWS Load Balancer Controller can discover them."
  type        = string
}

variable "single_nat_gateway" {
  description = "When true, deploys a single NAT Gateway shared by every zone. Saves cost at the price of losing internet egress for one zone if the NAT zone fails."
  type        = bool
  default     = true
}

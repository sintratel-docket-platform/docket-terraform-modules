output "vpc_id" {
  description = "VPC identifier."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Public subnets, where the controller creates the load balancer."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnets, where the cluster nodes are placed."
  value       = aws_subnet.private[*].id
}

output "alb_security_group_id" {
  description = "Load balancer security group."
  value       = aws_security_group.alb.id
}

output "node_security_group_id" {
  description = "Node security group, to attach to the node group."
  value       = aws_security_group.nodes.id
}

output "vpc_id" {
  description = "Identificador de la VPC."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Subredes publicas, donde el controller crea el balanceador."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Subredes privadas, donde se colocan los nodos del cluster."
  value       = aws_subnet.private[*].id
}

output "alb_security_group_id" {
  description = "Security group del balanceador."
  value       = aws_security_group.alb.id
}

output "node_security_group_id" {
  description = "Security group de los nodos, para asociarlo al node group."
  value       = aws_security_group.nodes.id
}

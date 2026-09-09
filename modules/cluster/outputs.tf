output "cluster_name" {
  description = "Cluster name. Consumed by the teardown and the operations scripts."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "API endpoint. Consumed by the kubernetes provider of the platform stack."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Control plane certificate, base64 encoded. Consumed by the kubernetes provider to verify the endpoint."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "Security group EKS creates for the cluster. It is what routes the control plane to the kubelet."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "oidc_provider_arn" {
  description = "Cluster OIDC provider. Consumed by the trust policies of the IRSA roles."
  value       = aws_iam_openid_connect_provider.cluster.arn
}

output "oidc_provider_url" {
  description = "OIDC provider URL without the scheme. Trust policy conditions are written in that format."
  value       = replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")
}
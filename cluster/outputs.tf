output "cluster_name" {
  description = "Nombre del cluster. Lo consumen el teardown y los scripts de operacion."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "Endpoint de la API. Lo consume el proveedor kubernetes del stack plataforma."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Certificado del plano de control, en base64. Lo consume el proveedor kubernetes para verificar el endpoint."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "Security group que EKS crea para el cluster. Es el que da ruta al plano de control hacia el kubelet."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "oidc_provider_arn" {
  description = "Proveedor OIDC del cluster. Lo consumen las politicas de confianza de los roles de IRSA."
  value       = aws_iam_openid_connect_provider.cluster.arn
}

output "oidc_provider_url" {
  description = "URL del proveedor OIDC sin el esquema. Las condiciones de las politicas de confianza se escriben en ese formato."
  value       = replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")
}
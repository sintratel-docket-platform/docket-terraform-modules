output "name" {
  description = "Nombre del namespace."
  value       = kubernetes_namespace.this.metadata[0].name
}
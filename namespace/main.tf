resource "kubernetes_namespace" "this" {
  metadata {
    name = var.environment

    labels = {
      "app.kubernetes.io/part-of" = "docket"

      # enforce rechaza el pod; warn lo admite y avisa de lo que le falta.
      "pod-security.kubernetes.io/enforce" = var.pod_security_enforce
      "pod-security.kubernetes.io/warn"    = "restricted"
    }
  }
}
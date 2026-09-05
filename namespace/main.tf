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

resource "kubernetes_resource_quota" "this" {
  metadata {
    name      = "cuota"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  spec {
    hard = {
      "requests.cpu"           = var.quota.requests_cpu
      "requests.memory"        = var.quota.requests_memory
      "limits.cpu"             = var.quota.limits_cpu
      "limits.memory"          = var.quota.limits_memory
      "pods"                   = var.quota.pods
      "services.loadbalancers" = var.quota.load_balancers
      "persistentvolumeclaims" = var.quota.volume_claims
    }
  }
}

resource "kubernetes_limit_range" "this" {
  metadata {
    name      = "limites-por-defecto"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  spec {
    limit {
      type = "Container"

      default = {
        cpu    = var.container_defaults.default_cpu
        memory = var.container_defaults.default_memory
      }

      default_request = {
        cpu    = var.container_defaults.request_cpu
        memory = var.container_defaults.request_memory
      }

      max = {
        cpu    = var.container_defaults.max_cpu
        memory = var.container_defaults.max_memory
      }
    }
  }
}
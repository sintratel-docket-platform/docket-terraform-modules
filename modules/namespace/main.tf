resource "kubernetes_namespace" "this" {
  metadata {
    name = var.environment

    labels = {
      "app.kubernetes.io/part-of" = var.part_of

      # enforce rejects the pod; warn admits it and reports what it lacks.
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

locals {
  operator_group = var.operator_group != "" ? var.operator_group : "${var.part_of}:${var.environment}"
}

resource "kubernetes_service_account" "aplicacion" {
  metadata {
    name      = var.service_account_name
    namespace = kubernetes_namespace.this.metadata[0].name

    annotations = var.irsa_role_arn != "" ? {
      "eks.amazonaws.com/role-arn" = var.irsa_role_arn
    } : {}
  }

  automount_service_account_token = false
}

resource "kubernetes_role" "operador" {
  metadata {
    name      = "operador"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "pods/log", "services", "configmaps", "events", "persistentvolumeclaims", "resourcequotas"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "replicasets", "statefulsets", "daemonsets"]
    verbs      = ["get", "list", "watch", "patch", "update"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["jobs", "cronjobs"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses", "networkpolicies"]
    verbs      = ["get", "list", "watch"]
  }

  dynamic "rule" {
    for_each = var.allow_exec ? [1] : []

    content {
      api_groups = [""]
      resources  = ["pods/exec", "pods/portforward"]
      verbs      = ["create"]
    }
  }
}

resource "kubernetes_role_binding" "operador" {
  metadata {
    name      = "operador"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.operador.metadata[0].name
  }

  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = local.operator_group
  }
}

resource "kubernetes_network_policy" "aislamiento" {
  metadata {
    name      = "aislamiento-por-ambiente"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  spec {
    pod_selector {}

    policy_types = ["Ingress"]

    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = kubernetes_namespace.this.metadata[0].name
          }
        }
      }

      # The load balancer subnets. There are no pods in them, so the
      # separation between environments still holds.
      dynamic "from" {
        for_each = toset(var.load_balancer_cidrs)

        content {
          ip_block {
            cidr = from.value
          }
        }
      }
    }
  }
}
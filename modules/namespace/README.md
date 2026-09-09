# `namespace` module

One environment inside the shared cluster: its namespace and the four layers that separate it from the other two.



## Why a namespace is not enough

A namespace separates names. **On its own it isolates nothing:** a pod in `dev` can open a connection to a pod in `prod`, and a credential with cluster permissions operates in all three alike.

What it provides is the unit the other layers are applied to. The module creates all four, and none is sufficient alone:

| Layer | Object | What it prevents |
|---|---|---|
| Names | `Namespace` | Two environments colliding on a resource name |
| Consumption | `ResourceQuota` and `LimitRange` | One environment exhausting the nodes and taking down the others |
| Permissions | `Role` and `RoleBinding` | A credential from one environment operating in another |
| Network | `NetworkPolicy` | A pod in one environment reaching a pod in another |

The fifth layer lives outside the cluster: each IRSA role reads only its own SSM prefix. The `irsa` module creates it, and here the `ServiceAccount` is merely annotated with its ARN.

---

**The namespace labels are functional.** `pod-security.kubernetes.io/enforce` activates a built-in Kubernetes control that rejects pods based on what they request, with nothing to install. The module sets `baseline` on `enforce` and `restricted` on `warn`: `enforce` rejects the pod, `warn` admits it and enumerates what it lacks. The application manifests declare that `securityContext` from card `14` onward, and `enforce` can then move up to `restricted`.

**Without a `LimitRange`, the quota would break every deployment.** With a CPU or memory `ResourceQuota` active, a pod that declares no `resources` is **rejected**: the quota system cannot account for something whose request is unknown. The `LimitRange` acts first, fills in the defaults, and the pod reaches the quota with numbers attached.

**The quota includes `services.loadbalancers` and `persistentvolumeclaims`.** These are cost controls. A controller inside the cluster creates them and Terraform never sees them, which is the definition of the orphans `scripts/check-orphans.sh` looks for. A ceiling is the only barrier against a manifest that raises twenty load balancers.

**The `Role` does not grant `secrets`.** An operator who can read secrets holds the environment `JWT_SECRET`, and from there the rest of the RBAC stops mattering. Secrets are read from SSM, where IAM controls the permission.

**`allow_exec` is closed in production.** Opening a shell inside a pod exposes its environment variables and its mounted secrets, granting through the back door exactly what omitting `secrets` denies at the front.

**The `RoleBinding` points at a group.** The group is where IAM meets Kubernetes: `aws_eks_access_entry` accepts `kubernetes_groups`, and an entry with `docket:dev` and no attached policy leaves that person with this `Role` and nothing else.

**The `ServiceAccount` holds no Kubernetes permission at all**, and carries `automountServiceAccountToken: false`. The application services do not call the cluster API, so that token would only be useful to steal. IRSA does not depend on it: a separate webhook injects the AWS token, in another volume and with another audience.

**The `NetworkPolicy` restricts `Ingress` only.** Closing `Egress` breaks name resolution, access to ECR and SSM, and the STS credential request IRSA depends on. With ingress closed the isolation still holds, because it is the destination that refuses the connection.

The policy selector uses `kubernetes.io/metadata.name`, a label Kubernetes maintains on every namespace by itself. That is why the module declares no label of its own for it.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.14 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | ~> 2.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubernetes_limit_range.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/limit_range) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_network_policy.aislamiento](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/network_policy) | resource |
| [kubernetes_resource_quota.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/resource_quota) | resource |
| [kubernetes_role.operador](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role) | resource |
| [kubernetes_role_binding.operador](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role_binding) | resource |
| [kubernetes_service_account.aplicacion](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allow_exec"></a> [allow\_exec](#input\_allow\_exec) | Allows the operator to open a shell inside a pod. | `bool` | `true` | no |
| <a name="input_container_defaults"></a> [container\_defaults](#input\_container\_defaults) | Values a container receives when it declares no resources. | <pre>object({<br/>    default_cpu    = string<br/>    default_memory = string<br/>    request_cpu    = string<br/>    request_memory = string<br/>    max_cpu        = string<br/>    max_memory     = string<br/>  })</pre> | <pre>{<br/>  "default_cpu": "200m",<br/>  "default_memory": "256Mi",<br/>  "max_cpu": "1",<br/>  "max_memory": "1Gi",<br/>  "request_cpu": "50m",<br/>  "request_memory": "128Mi"<br/>}</pre> | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name. It is also the namespace name. | `string` | n/a | yes |
| <a name="input_irsa_role_arn"></a> [irsa\_role\_arn](#input\_irsa\_role\_arn) | ARN of the IAM role the environment ServiceAccount may assume. Empty leaves it with no AWS access. | `string` | `""` | no |
| <a name="input_load_balancer_cidrs"></a> [load\_balancer\_cidrs](#input\_load\_balancer\_cidrs) | Ranges allowed to send ingress traffic in addition to the namespace itself. | `list(string)` | `[]` | no |
| <a name="input_operator_group"></a> [operator\_group](#input\_operator\_group) | Kubernetes group granted the operator role. | `string` | `""` | no |
| <a name="input_part_of"></a> [part\_of](#input\_part\_of) | Value of the app.kubernetes.io/part-of label, and the prefix of the operator group. | `string` | `"docket"` | no |
| <a name="input_pod_security_enforce"></a> [pod\_security\_enforce](#input\_pod\_security\_enforce) | Pod Security Admission level that is rejected. | `string` | `"baseline"` | no |
| <a name="input_quota"></a> [quota](#input\_quota) | Consumption ceiling of the namespace. | <pre>object({<br/>    requests_cpu    = string<br/>    requests_memory = string<br/>    limits_cpu      = string<br/>    limits_memory   = string<br/>    pods            = string<br/>    load_balancers  = string<br/>    volume_claims   = string<br/>  })</pre> | <pre>{<br/>  "limits_cpu": "2000m",<br/>  "limits_memory": "3Gi",<br/>  "load_balancers": "1",<br/>  "pods": "15",<br/>  "requests_cpu": "1000m",<br/>  "requests_memory": "1.5Gi",<br/>  "volume_claims": "4"<br/>}</pre> | no |
| <a name="input_service_account_name"></a> [service\_account\_name](#input\_service\_account\_name) | Name of the workload ServiceAccount. Deployments reference it by this name. | `string` | `"docket"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_name"></a> [name](#output\_name) | Namespace name. |
<!-- END_TF_DOCS -->

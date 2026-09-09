# `namespace` module

One environment inside the shared cluster: its namespace and the four layers that separate it from the other two.

## Inputs

| Variable | Type | Required | Purpose |
|---|---|---|---|
| `environment` | string | Yes | Name of the environment and of the namespace |
| `pod_security_enforce` | string | No, `baseline` | Pod Security Admission level that is rejected |
| `quota` | object | No | Consumption ceiling of the namespace |
| `container_defaults` | object | No | Values a container receives when it declares no `resources` |
| `allow_exec` | bool | No, `true` | Lets the operator open a shell inside a pod |
| `operator_group` | string | No, `docket:<environment>` | Kubernetes group granted the operator role |
| `irsa_role_arn` | string | No, empty | IAM role the environment `ServiceAccount` may assume |

## Outputs

| Output | What it returns |
|---|---|
| `name` | Namespace name |

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

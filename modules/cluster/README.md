# `cluster` module

EKS cluster with a managed node group, its add-ons and its OIDC provider. Nodes sit in private subnets.

## Inputs

| Variable | Type | Required | Purpose |
|---|---|---|---|
| `cluster_name` | string | Yes | Cluster name |
| `kubernetes_version` | string | Yes | Control plane version |
| `private_subnet_ids` | list(string) | Yes | Where the nodes go |
| `public_subnet_ids` | list(string) | Yes | Where the load balancer will be created |
| `node_security_group_id` | string | Yes | Node security group, from the `network` module |
| `cluster_admin_principals` | list(string) | Yes | IAM ARNs granted cluster administration |
| `public_access_cidrs` | list(string) | **Yes** | Ranges allowed to reach the public endpoint. A validation block rejects `0.0.0.0/0` |
| `node_instance_type` | string | No, `t3.medium` | Node instance type |
| `node_capacity_type` | string | No, `ON_DEMAND` | `ON_DEMAND` or `SPOT` |
| `node_desired_size` | number | No, `2` | Nodes it starts with |
| `node_min_size` | number | No, `2` | Node group minimum |
| `node_max_size` | number | No, `3` | Node group maximum |
| `node_disk_size` | number | No, `20` | Volume per node, in GB |
| `enabled_log_types` | list(string) | No, `["audit", "authenticator"]` | Control plane logs sent to CloudWatch |
| `oidc_thumbprints` | list(string) | No | OIDC issuer certificate thumbprints |

The default `node_instance_type` **does not work in this account**. See the instance type section below. The ephemeral stack passes `m7i-flex.large`.

## Outputs

| Output | What it returns | Who consumes it |
|---|---|---|
| `cluster_name` | Cluster name | The teardown and the operations scripts |
| `cluster_endpoint` | API endpoint | The `kubernetes` provider of the `platform` stack |
| `cluster_certificate_authority_data` | Control plane certificate | The same provider |
| `cluster_security_group_id` | Security group EKS creates | Rules towards the kubelet |
| `oidc_provider_arn` | Cluster OIDC provider | The IRSA roles |
| `oidc_provider_url` | Its URL without the scheme | The conditions in those trust policies |

`oidc_provider_url` is published without `https://` because that is the format IRSA trust policy conditions are written in.

## Instance types allowed in this account

The account is on the AWS free plan, which **only allows launching instance types eligible for the free tier**. A type outside that list makes `RunInstances` fail in a loop with the node group reporting no `health.issue`: the symptom is an indefinite `Still creating...`, and the error only appears in CloudTrail.

| Type | RAM | Pods per node | USD/hour |
|---|---|---|---|
| `t3.small` | 2 GiB | 11 | 0.0208 |
| `c7i-flex.large` | 4 GiB | 29 | 0.0848 |
| `m7i-flex.large` | 8 GiB | 29 | 0.0958 |

EKS caps pods per node by the network interfaces of the instance type, and the ceiling of 11 on `t3.small` is not enough for three environments.

## Decisions that live inside the module

**`authentication_mode = "API"`.** Retires the `aws-auth` ConfigMap. Who enters the cluster is declared with `aws_eks_access_entry`, an AWS resource versioned in state, rather than an object edited by hand inside the cluster itself.

**`bootstrap_cluster_creator_admin_permissions = false`.** No access is implicit for whoever ran the `apply`. Without at least one ARN in `cluster_admin_principals`, nobody gets in.

`aws_eks_node_group` does not accept security groups directly, and without a launch template EKS attaches only its own, so the rule that lets the load balancer in would never apply. And the moment the launch template declares any, **EKS stops adding its own**, so both must be set: the one from the `network` module and the one the cluster creates. Without the second, the control plane loses its route to the kubelet and `kubectl logs`, `kubectl exec`, metrics and webhooks all break.

**IMDSv2 required, hop limit 1.** Only the host reaches the metadata service; pods do not. A compromised pod cannot request the node credentials, which include read access to the whole registry. Pods needing AWS permissions get them through IRSA, scoped by namespace.

**Tags propagate through `tag_specifications`.** The provider `default_tags` does not reach the instances, because the autoscaling group creates them, not Terraform. The module collects the tags with the `aws_default_tags` data source rather than repeating them, and applies them to instances and volumes.

**`vpc-cni` carries `enableNetworkPolicy`.** Without that key the CNI accepts `NetworkPolicy` without any error and never enforces it. It is a silent failure: isolation between environments would appear to be in place without being so.

**Add-on ordering.** `coredns`, `kube-proxy` and `eks-pod-identity-agent` depend on the node group, because they need a node to run on. `vpc-cni` cannot depend on it: without the CNI no node reaches `Ready`, and the `depends_on` would be a circular block.

**Add-on versions.** The `aws_eks_addon_version` data source returns the version AWS marks as default for the cluster Kubernetes version.

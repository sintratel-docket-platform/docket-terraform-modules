# `cluster` module

EKS cluster with a managed node group, its add-ons and its OIDC provider. Nodes sit in private subnets.



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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.14 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 6.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_eks_access_entry.admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_entry) | resource |
| [aws_eks_access_policy_association.admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_policy_association) | resource |
| [aws_eks_addon.others](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_addon.vpc_cni](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster) | resource |
| [aws_eks_node_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group) | resource |
| [aws_iam_openid_connect_provider.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_role.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_launch_template.nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_default_tags.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/default_tags) | data source |
| [aws_eks_addon_version.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_addon_version) | data source |
| [aws_iam_policy_document.cluster_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.nodes_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_admin_principals"></a> [cluster\_admin\_principals](#input\_cluster\_admin\_principals) | IAM ARNs granted administrative access to the cluster. | `list(string)` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the EKS cluster. | `string` | n/a | yes |
| <a name="input_enabled_log_types"></a> [enabled\_log\_types](#input\_enabled\_log\_types) | EKS control-plane log types sent to CloudWatch. | `list(string)` | <pre>[<br/>  "audit",<br/>  "authenticator"<br/>]</pre> | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | Kubernetes version of the control plane. | `string` | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for every resource name this module creates. Keeps the module reusable: it names nothing after a particular project. | `string` | n/a | yes |
| <a name="input_node_capacity_type"></a> [node\_capacity\_type](#input\_node\_capacity\_type) | ON\_DEMAND or SPOT. Capacity type of the nodes. | `string` | `"ON_DEMAND"` | no |
| <a name="input_node_desired_size"></a> [node\_desired\_size](#input\_node\_desired\_size) | Number of nodes the node group starts with. | `number` | `2` | no |
| <a name="input_node_disk_size"></a> [node\_disk\_size](#input\_node\_disk\_size) | Size in GB of each node volume. | `number` | `20` | no |
| <a name="input_node_instance_type"></a> [node\_instance\_type](#input\_node\_instance\_type) | Node instance type. The pod limit per node derives from this value, and t3.small is not enough for the three environments. | `string` | `"t3.medium"` | no |
| <a name="input_node_max_size"></a> [node\_max\_size](#input\_node\_max\_size) | Maximum number of nodes in the node group. | `number` | `3` | no |
| <a name="input_node_min_size"></a> [node\_min\_size](#input\_node\_min\_size) | Minimum number of nodes in the node group. | `number` | `2` | no |
| <a name="input_node_security_group_id"></a> [node\_security\_group\_id](#input\_node\_security\_group\_id) | Node security group, created by the network module. | `string` | n/a | yes |
| <a name="input_oidc_thumbprints"></a> [oidc\_thumbprints](#input\_oidc\_thumbprints) | Certificate thumbprints of the cluster OIDC issuer. | `list(string)` | <pre>[<br/>  "9e99a48a9960b14926bb7f3b02e22da2b0ab7280"<br/>]</pre> | no |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | Private subnets where the nodes are placed. | `list(string)` | n/a | yes |
| <a name="input_public_access_cidrs"></a> [public\_access\_cidrs](#input\_public\_access\_cidrs) | CIDR ranges allowed to reach the public EKS API endpoint. | `list(string)` | n/a | yes |
| <a name="input_public_subnet_ids"></a> [public\_subnet\_ids](#input\_public\_subnet\_ids) | Public subnets where the AWS Load Balancer Controller creates the load balancer. | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_certificate_authority_data"></a> [cluster\_certificate\_authority\_data](#output\_cluster\_certificate\_authority\_data) | Control plane certificate, base64 encoded. Consumed by the kubernetes provider to verify the endpoint. |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | API endpoint. Consumed by the kubernetes provider of the platform stack. |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Cluster name. Consumed by the teardown and the operations scripts. |
| <a name="output_cluster_security_group_id"></a> [cluster\_security\_group\_id](#output\_cluster\_security\_group\_id) | Security group EKS creates for the cluster. It is what routes the control plane to the kubelet. |
| <a name="output_oidc_provider_arn"></a> [oidc\_provider\_arn](#output\_oidc\_provider\_arn) | Cluster OIDC provider. Consumed by the trust policies of the IRSA roles. |
| <a name="output_oidc_provider_url"></a> [oidc\_provider\_url](#output\_oidc\_provider\_url) | OIDC provider URL without the scheme. Trust policy conditions are written in that format. |
<!-- END_TF_DOCS -->

# `irsa` module

An IAM role assumable only by one specific `ServiceAccount` in one specific namespace, through the cluster OIDC provider.

## Inputs

| Variable | Purpose |
|---|---|
| `role_name` | Role name |
| `oidc_provider_arn` | Cluster OIDC provider |
| `oidc_provider_url` | Its URL without the scheme, for the conditions |
| `namespace` | Namespace of the authorised `ServiceAccount` |
| `service_account` | Name of the authorised `ServiceAccount` |
| `policy_name` | Name of the inline policy |
| `policy_json` | Role permissions. Empty when it only carries managed policies |
| `managed_policy_arns` | AWS managed policies attached to the role |

## Outputs

| Output | What it returns |
|---|---|
| `role_arn` | ARN, to annotate the `ServiceAccount` |
| `role_name` | Role name |

## Why it lives in the ephemeral stack

The trust policy points at the cluster OIDC provider, whose URL contains an identifier that changes on every recreation. A persistent role would be left with broken trust after the first shutdown cycle. See `CONVENTIONS.md`.

---

The condition on `sub` requires the exact value `system:serviceaccount:<namespace>:<service_account>`. Without it, any `ServiceAccount` in the cluster could assume the role, and the separation between environments would disappear with nothing to signal it.

## Inline policy and managed policy

A role may carry either, or both. The inline policy is written in `policy_json` and is created only when that arrives with content. Managed policies are passed by ARN in `managed_policy_arns`.

The EBS driver is the managed-policy case. It uses `AmazonEBSCSIDriverPolicy`, which AWS maintains, and copying its JSON into the repository would leave a copy that ages without warning.

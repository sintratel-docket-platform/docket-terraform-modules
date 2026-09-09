# Modules

Reusable code. A module describes **which** resources make up one piece of the platform; the stacks decide **with which values** it is instantiated.

No module declares `provider` or `backend`. Both are the responsibility of the stack that consumes it.

| Module | Responsibility |
|---|---|
| `network/` | VPC, subnets, Internet Gateway, NAT Gateway, route tables and security groups |
| `cluster/` | EKS cluster, node group, add-ons, OIDC provider and access entries |
| `namespace/` | One environment inside the cluster: namespace, quotas, RBAC and network policies |
| `irsa/` | IAM role assumable by one specific `ServiceAccount` in one specific namespace |
| `registry/` | ECR repositories and their lifecycle policy |
| `ci-identity/` | GitHub OIDC provider and the roles the pipeline assumes |
| `environment/` | SSM parameter tree for one environment |

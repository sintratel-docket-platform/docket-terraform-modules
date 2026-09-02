# Módulo `identidad-ci`

Proveedor OIDC de GitHub y los dos roles que asume la pipeline:

| Rol | Lo asume | Alcance |
|---|---|---|
| `GitHubActionsBuildRole` | El job que construye y publica imágenes | Solo ECR |
| `GitHubActionsDeployRole` | El job que ejecuta Terraform | EC2, VPC, IAM, S3, EKS y Route 53 |

La política de confianza de cada rol se restringe al repositorio y la rama concretos. Un rol asumible por cualquier repositorio de la organización equivale a una credencial compartida.

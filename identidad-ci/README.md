# Módulo `identidad-ci`

Proveedor OIDC de GitHub y los dos roles que asume la pipeline.

| Rol | Lo asume | Alcance |
|---|---|---|
| `GitHubActionsBuildRole` | El job que construye y publica imágenes | Solo ECR |
| `GitHubActionsDeployRole` | El job que ejecuta Terraform | EC2, VPC, IAM, S3, EKS y Route 53 |

La separación responde al criterio de accesos limitados según necesidad de la historia `18`. El job de build no tiene por qué poder crear clústeres.

## Entradas

| Variable | Tipo | Obligatoria | Para qué |
|---|---|---|---|
| `github_org` | string | Sí | Organización de los repositorios |
| `build_repositories` | list(string) | Sí | Repositorios que pueden asumir el rol de build |
| `infra_repository` | string | Sí | Único repositorio que puede asumir el rol de Terraform |
| `allowed_branches` | list(string) | No, `["main"]` | Ramas admitidas en la política de confianza |
| `ecr_repository_arns` | list(string) | Sí | Repositorios sobre los que actúa el rol de build |
| `state_bucket_arn` | string | Sí | Bucket que el rol de Terraform necesita leer y escribir |

La política de confianza se construye con una condición sobre `sub` del tipo `repo:<org>/<repo>:ref:refs/heads/<rama>`. Sin acotar repositorio y rama, el rol queda asumible por cualquier repositorio de la organización.

## Salidas previstas

| Output | Qué devuelve | Quién lo consume |
|---|---|---|
| `build_role_arn` | ARN del rol de build | El workflow de construcción de imágenes |
| `deploy_role_arn` | ARN del rol de Terraform | El workflow de infraestructura |
| `oidc_provider_arn` | Proveedor OIDC de GitHub | Referencia para políticas adicionales |

# Módulo `cluster`

Clúster EKS con un node group gestionado, sus add-ons y su proveedor OIDC. Los nodos van en subredes privadas.

## Entradas

| Variable | Tipo | Obligatoria | Para qué |
|---|---|---|---|
| `cluster_name` | string | Sí | Nombre del clúster |
| `kubernetes_version` | string | Sí | Versión del plano de control |
| `private_subnet_ids` | list(string) | Sí | Dónde van los nodos |
| `public_subnet_ids` | list(string) | Sí | Dónde se creará el balanceador |
| `node_security_group_id` | string | Sí | Security group de los nodos, del módulo `red` |
| `cluster_admin_principals` | list(string) | Sí | ARNs de IAM que reciben administración del clúster |
| `node_instance_type` | string | No, `t3.medium` | Tipo de instancia de los nodos |
| `node_capacity_type` | string | No, `ON_DEMAND` | `ON_DEMAND` o `SPOT` |
| `node_desired_size` | number | No, `2` | Nodos con los que arranca |
| `node_min_size` | number | No, `2` | Mínimo del node group |
| `node_max_size` | number | No, `3` | Máximo del node group |
| `node_disk_size` | number | No, `20` | Volumen de cada nodo, en GB |
| `public_access_cidrs` | list(string) | No, `0.0.0.0/0` | Desde dónde se admite llegar al endpoint público |
| `enabled_log_types` | list(string) | No, vacío | Registros del plano de control enviados a CloudWatch |
| `oidc_thumbprints` | list(string) | No | Huellas del certificado del emisor OIDC |

El valor por defecto de `node_instance_type` **no sirve en esta cuenta**. Ver la sección de tipos de instancia más abajo.

## Salidas

| Output | Qué devuelve | Quién lo consume |
|---|---|---|
| `cluster_name` | Nombre del clúster | El teardown y los scripts de operación |
| `cluster_endpoint` | Endpoint de la API | El proveedor `kubernetes` del stack `plataforma` |
| `cluster_certificate_authority_data` | Certificado del plano de control | El mismo proveedor |
| `cluster_security_group_id` | Security group que crea EKS | Reglas hacia el kubelet |
| `oidc_provider_arn` | Proveedor OIDC del clúster | Los roles de IRSA |
| `oidc_provider_url` | Su URL sin el esquema | Las condiciones de esas políticas de confianza |

`oidc_provider_url` se publica sin `https://` porque ese es el formato en el que se escriben las condiciones de una política de confianza de IRSA.

## Tipos de instancia admitidos en esta cuenta

La cuenta está en el plan gratuito de AWS, que **solo permite lanzar tipos de instancia elegibles para la capa gratuita**. Un tipo fuera de esa lista hace que `RunInstances` falle en bucle sin que el node group reporte ningún `health.issue`: el síntoma es un `Still creating...` indefinido, y el error solo aparece en CloudTrail.

| Tipo | RAM | Pods por nodo | USD/hora |
|---|---|---|---|
| `t3.small` | 2 GiB | 11 | 0,0208 |
| `c7i-flex.large` | 4 GiB | 29 | 0,0848 |
| `m7i-flex.large` | 8 GiB | 29 | 0,0958 |

El proyecto usa `c7i-flex.large`. EKS limita los pods por nodo según las interfaces de red del tipo de instancia, y el techo de 11 de `t3.small` no alcanza.

## Decisiones que van dentro del módulo

**`authentication_mode = "API"`.** Retira el ConfigMap `aws-auth`. Quién entra al clúster se declara con `aws_eks_access_entry`, que es un recurso de AWS versionado en el estado, en vez de un objeto editable a mano dentro del propio clúster.

**`bootstrap_cluster_creator_admin_permissions = false`.** Ningún acceso queda implícito en quien ejecutó el `apply`. Sin al menos un ARN en `cluster_admin_principals`, nadie puede entrar.

`aws_eks_node_group` no admite security groups directamente, y sin launch template EKS asocia solo el suyo, con lo que la regla que deja entrar al balanceador no se aplicaría. Y en cuanto el launch template declara alguno, **EKS deja de añadir el suyo**, así que hay que poner los dos: el del módulo `red` y el que crea el clúster. Sin el segundo, el plano de control pierde la ruta hacia el kubelet y se rompen `kubectl logs`, `kubectl exec`, las métricas y los webhooks.

**IMDSv2 obligatorio con límite de saltos en 1.** Solo el host llega al servicio de metadatos, los pods no. Un pod comprometido no puede pedir las credenciales del nodo, que incluyen lectura de todo el registro. Los pods que necesitan permisos de AWS los obtienen por IRSA, acotados por namespace.

**Las etiquetas se propagan por `tag_specifications`.** `default_tags` del proveedor no alcanza a las instancias, porque las crea el grupo de autoescalado y no Terraform. El módulo recoge las etiquetas con el origen de datos `aws_default_tags` en vez de repetirlas, y las aplica a instancias y volúmenes.

**`vpc-cni` lleva `enableNetworkPolicy`.** Sin esa clave el CNI acepta las `NetworkPolicy` sin dar ningún error y no las aplica nunca. Es un fallo silencioso: el aislamiento entre ambientes parecería estar puesto sin estarlo.

**El orden de los add-ons.** `coredns`, `kube-proxy` y `eks-pod-identity-agent` dependen del node group, porque necesitan un nodo donde correr. `vpc-cni` no puede depender de él: sin CNI ningún nodo llega a `Ready`, y el `depends_on` sería un bloqueo circular.

**La versión de los add-ons.** El origen de datos `aws_eks_addon_version` devuelve la versión que AWS marca como predeterminada para la versión de Kubernetes del clúster.

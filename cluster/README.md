# Módulo `cluster`

Clúster EKS con un node group gestionado, con los nodos en subredes privadas.

## Entradas

| Variable | Tipo | Obligatoria | Para qué |
|---|---|---|---|
| `cluster_name` | string | Sí | Nombre del clúster |
| `kubernetes_version` | string | Sí | Versión del plano de control |
| `private_subnet_ids` | list(string) | Sí | Dónde van los nodos |
| `public_subnet_ids` | list(string) | Sí | Dónde se crea el balanceador |
| `node_instance_type` | string | No, `t3.medium` | Tipo de instancia de los nodos |
| `node_desired_size` | number | No, `2` | Nodos con los que arranca |
| `node_min_size` | number | No, `2` | Mínimo del node group |
| `node_max_size` | number | No, `3` | Máximo del node group |
| `node_disk_size` | number | No, `20` | Volumen de cada nodo, en GB |

El tipo de instancia no es una preferencia de holgura. EKS limita los pods por nodo según las interfaces de red disponibles, y `t3.small` admite 11 pods mientras que `t3.medium` admite 17. Con 18 pods de aplicación más los add-ons, dos `t3.small` no alcanzan.

## Salidas previstas

| Output | Qué devuelve | Quién lo consume |
|---|---|---|
| `cluster_name` | Nombre del clúster | El teardown y los scripts de operación |
| `cluster_endpoint` | Endpoint de la API | La configuración de `kubectl` |
| `cluster_certificate_authority_data` | Certificado del plano de control | La configuración de `kubectl` |
| `oidc_provider_arn` | Proveedor OIDC del clúster | **Los roles de IRSA del stack efímero** |
| `oidc_provider_url` | URL del proveedor OIDC | Las políticas de confianza de esos roles |
| `node_security_group_id` | Security group de los nodos | Reglas de entrada desde el balanceador |

El output del proveedor OIDC es el que obliga a que los roles de IRSA vivan en el stack efímero. Su identificador cambia en cada recreación del clúster, y un rol persistente quedaría con la política de confianza rota. Ver `CONVENCIONES.md`.

Los outputs llegan junto con los recursos, en la historia `05`.

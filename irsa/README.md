# Módulo `irsa`

Un rol de IAM que solo puede asumir un `ServiceAccount` concreto de un namespace concreto, mediante el proveedor OIDC del clúster.

## Entradas

| Variable | Para qué |
|---|---|
| `role_name` | Nombre del rol |
| `oidc_provider_arn` | Proveedor OIDC del clúster |
| `oidc_provider_url` | Su URL sin esquema, para las condiciones |
| `namespace` | Namespace del `ServiceAccount` autorizado |
| `service_account` | Nombre del `ServiceAccount` autorizado |
| `policy_name` | Nombre de la política en línea |
| `policy_json` | Permisos del rol |

## Salidas

| Output | Qué devuelve |
|---|---|
| `role_arn` | ARN, para anotar el `ServiceAccount` |
| `role_name` | Nombre del rol |

## Por qué vive en el stack efímero

La política de confianza apunta al proveedor OIDC del clúster, cuya URL contiene un identificador que cambia en cada recreación. Un rol persistente quedaría con la confianza rota tras el primer ciclo de apagado. Ver `CONVENCIONES.md`.

---

La condición sobre `sub` exige el valor exacto `system:serviceaccount:<namespace>:<service_account>`. Sin ella, cualquier `ServiceAccount` del clúster podría asumir el rol, y la separación entre ambientes desaparecería sin que nada lo indicara.
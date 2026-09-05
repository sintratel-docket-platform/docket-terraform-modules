# Módulo `namespace`

Un ambiente dentro del clúster compartido. Namespace y las políticas que lo separan de los otros dos.

## Entradas

| Variable | Tipo | Obligatoria | Para qué |
|---|---|---|---|
| `environment` | string | Sí | Nombre del ambiente y del namespace |
| `pod_security_enforce` | string | No, `baseline` | Nivel de Pod Security Admission que se rechaza |

## Salidas

| Output | Qué devuelve |
|---|---|
| `name` | Nombre del namespace |

---

Un namespace separa nombres. No impide que un pod de un ambiente abra una conexión a otro, ni que una credencial opere en los tres. El aislamiento se construye encima, con cuotas, RBAC y políticas de red, y este módulo las va agrupando conforme avanzan las tareas de la historia `05`.
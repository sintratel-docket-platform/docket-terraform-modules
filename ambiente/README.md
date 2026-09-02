# Módulo `ambiente`

Árbol de parámetros en SSM Parameter Store de un ambiente, bajo el prefijo `/docket/<ambiente>/`.

## Entradas

| Variable | Tipo | Obligatoria | Para qué |
|---|---|---|---|
| `environment` | string | Sí | Determina el prefijo. Valida que sea `dev`, `staging` o `prod` |
| `parameter_names` | list(string) | Sí | Parámetros que se crean bajo el prefijo |
| `kms_key_id` | string | No, vacío | Clave de cifrado. Vacío usa la clave gestionada por AWS, sin costo |

## Sobre los valores

El módulo crea la **estructura** de parámetros con un valor de marcador, y los valores reales se cargan aparte, fuera de Terraform. Los parámetros llevarán `ignore_changes` sobre el valor, de modo que un `apply` posterior no pise un secreto cargado a mano.

Esto mantiene los secretos fuera del repositorio y fuera del estado en texto plano.

## Salidas previstas

| Output | Qué devuelve | Quién lo consume |
|---|---|---|
| `parameter_prefix` | Prefijo del árbol, `/docket/<ambiente>/` | La política del rol de IRSA del ambiente |
| `parameter_arns` | ARN de los parámetros creados | Esa misma política, para acotarla al prefijo |

Los outputs llegan junto con los recursos, en la historia `04`.

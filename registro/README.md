# Módulo `registro`

Un repositorio de ECR por microservicio, con política de ciclo de vida para podar imágenes antiguas.

## Entradas

| Variable | Tipo | Obligatoria | Para qué |
|---|---|---|---|
| `service_names` | list(string) | Sí | Un repositorio por cada nombre |
| `max_image_count` | number | No, `10` | Imágenes que se conservan por repositorio |
| `scan_on_push` | bool | No, `true` | Escaneo de vulnerabilidades al publicar |

La capa gratuita de ECR cubre 500 MB al mes, así que la poda no es opcional. El escaneo al publicar aporta evidencia para el área de seguridad y no tiene costo en su modalidad básica.

## Salidas previstas

| Output | Qué devuelve | Quién lo consume |
|---|---|---|
| `repository_urls` | Mapa de servicio a URL del repositorio | Los manifiestos de despliegue y la pipeline |
| `repository_arns` | Lista de ARN | El módulo `identidad-ci`, para acotar el rol de build |

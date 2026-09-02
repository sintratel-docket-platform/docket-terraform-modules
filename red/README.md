# Módulo `red`

VPC con subredes públicas y privadas repartidas en dos zonas de disponibilidad, requisito de EKS.

Incluye un único NAT Gateway compartido por ambas zonas, decisión de costo registrada en el ADR-005 de la arquitectura. Si cae la zona donde vive el NAT, los nodos de la otra zona pierden la salida a internet.

## Entradas

| Variable | Tipo | Obligatoria | Para qué |
|---|---|---|---|
| `vpc_cidr` | string | No, `10.0.0.0/16` | Rango de la VPC |
| `availability_zones` | list(string) | Sí | Zonas donde se reparten las subredes. Valida que sean al menos dos |
| `public_subnet_cidrs` | list(string) | Sí | Subredes del balanceador y del NAT |
| `private_subnet_cidrs` | list(string) | Sí | Subredes de los nodos |
| `cluster_name` | string | Sí | Etiqueta las subredes para que el AWS Load Balancer Controller las descubra |
| `single_nat_gateway` | bool | No, `true` | Un NAT compartido en vez de uno por zona |

## Salidas previstas

| Output | Qué devuelve | Quién lo consume |
|---|---|---|
| `vpc_id` | Identificador de la VPC | El módulo `cluster` |
| `public_subnet_ids` | Subredes públicas | El módulo `cluster`, para el balanceador |
| `private_subnet_ids` | Subredes privadas | El módulo `cluster`, para los nodos |

Los outputs llegan junto con los recursos, en la historia `04`.

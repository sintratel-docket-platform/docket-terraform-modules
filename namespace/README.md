# Módulo `namespace`

Un ambiente dentro del clúster compartido: su namespace y las cuatro capas que lo separan de los otros dos.

## Entradas

| Variable | Tipo | Obligatoria | Para qué |
|---|---|---|---|
| `environment` | string | Sí | Nombre del ambiente y del namespace |
| `pod_security_enforce` | string | No, `baseline` | Nivel de Pod Security Admission que se rechaza |
| `quota` | object | No | Techo de consumo del namespace |
| `container_defaults` | object | No | Valores que recibe un contenedor que no declara `resources` |
| `allow_exec` | bool | No, `true` | Permite al operador abrir una shell dentro de un pod |
| `operator_group` | string | No, `docket:<ambiente>` | Grupo de Kubernetes al que se concede el rol de operador |
| `irsa_role_arn` | string | No, vacío | Rol de IAM que puede asumir el `ServiceAccount` del ambiente |

## Salidas

| Output | Qué devuelve |
|---|---|
| `name` | Nombre del namespace |

## Por qué un namespace no basta

Un namespace separa nombres. **No aísla nada por sí solo:** un pod en `dev` puede abrir una conexión a un pod en `prod`, y una credencial con permisos de clúster opera en los tres igual.

Lo que aporta es ser la unidad sobre la que se aplican las demás capas. El módulo crea las cuatro, y ninguna basta sola:

| Capa | Objeto | Qué impide |
|---|---|---|
| Nombres | `Namespace` | Que dos ambientes colisionen en el nombre de un recurso |
| Consumo | `ResourceQuota` y `LimitRange` | Que un ambiente agote los nodos y tumbe a los otros |
| Permisos | `Role` y `RoleBinding` | Que una credencial de un ambiente opere en otro |
| Red | `NetworkPolicy` | Que un pod de un ambiente alcance a un pod de otro |

La quinta capa vive fuera del clúster: cada rol de IRSA solo lee su prefijo de SSM. La crea el módulo `irsa`, y aquí solo se anota el `ServiceAccount` con su ARN.

---

**Las etiquetas del namespace son funcionales.** `pod-security.kubernetes.io/enforce` activa un control incorporado de Kubernetes que rechaza pods según lo que pidan, sin instalar nada. El módulo pone `baseline` en `enforce` y `restricted` en `warn`: `enforce` rechaza el pod, `warn` lo admite y enumera lo que le falta. Los manifiestos de la aplicación declaran ese `securityContext` a partir de la historia `14`, y entonces `enforce` puede subir a `restricted`.

**Sin `LimitRange`, la cuota rompería todo despliegue.** Con una `ResourceQuota` de CPU o memoria activa, un pod que no declare `resources` es **rechazado**. : el sistema de cuotas no puede contabilizar lo que no sabe cuánto pide. El `LimitRange` actúa antes, rellena los valores por defecto, y el pod llega a la cuota con números.

**La cuota incluye `services.loadbalancers` y `persistentvolumeclaims`.** Son control de coste. Los crea un controlador dentro del clúster y Terraform no los ve, que es la definición de los huérfanos que busca `scripts/verificar-huerfanos.sh`. Un tope es la única barrera contra un manifiesto
que levante veinte balanceadores.

**El `Role` no concede `secrets`.** Un operador que puede leer secretos tiene el `JWT_SECRET` del ambiente, y a partir de ahí el resto del RBAC deja de importar. Los secretos se consultan en SSM, donde el permiso lo controla IAM.

**`allow_exec` va cerrado en producción.** Abrir una shell dentro de un pod da sus variables de entorno y sus secretos montados, así que concede por la puerta de atrás lo que la omisión de `secrets` niega por delante.

**El `RoleBinding` apunta a un grupo.** El grupo es el punto donde
IAM se engancha con Kubernetes: `aws_eks_access_entry` admite `kubernetes_groups`, y una entry con `docket:dev` y sin política asociada deja a esa persona con este `Role` y con nada más.

**El `ServiceAccount` no tiene ningún permiso de Kubernetes**, y lleva `automountServiceAccountToken: false`. Los servicios de la aplicación no llaman a la API del clúster, así que ese token solo serviría para ser robado. IRSA no depende de él: el token de AWS lo inyecta un webhook aparte, en otro volumen y con otra audiencia.

**La `NetworkPolicy` solo restringe `Ingress`.** Cerrar `Egress` rompe la resolución de nombres, el acceso a ECR y a SSM, y la petición de credenciales a STS de la que depende IRSA. Con la entrada cerrada el aislamiento se cumple igual, porque quien rechaza la conexión es el destino.

El selector de la política usa `kubernetes.io/metadata.name`, una etiqueta que Kubernetes mantiene solo en cada namespace. Por eso el módulo no declara ninguna etiqueta propia para eso.

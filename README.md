# Módulos

Código reutilizable. Un módulo describe **qué** recursos componen una pieza de la plataforma, y los stacks deciden **con qué valores** se instancia.

Ningún módulo declara `provider` ni `backend`. Ambas cosas son responsabilidad del stack que lo consume.

| Módulo | Responsabilidad |
|---|---|
| `red/` | VPC, subredes, Internet Gateway, NAT Gateway, tablas de ruta y security groups |
| `cluster/` | Clúster EKS, node group y los add-ons del clúster |
| `registro/` | Repositorios de ECR y su política de ciclo de vida |
| `identidad-ci/` | Proveedor OIDC de GitHub y los roles que asume la pipeline |
| `ambiente/` | Árbol de parámetros en SSM de un ambiente |

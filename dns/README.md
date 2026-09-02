# Módulo `dns`

Zona alojada de Route 53 y certificado de ACM para los tres ambientes.

El certificado cubre el host de producción más un comodín que abarca `staging` y `dev`, y cualquier ambiente que se añada después.

## Activación en dos pasos

La validación del certificado exige que los nameservers ya estén delegados en el registrador, y esa delegación es un paso manual con latencia de propagación. Por eso `validate_certificate` está separada:

1. `apply` con `validate_certificate = false`. Crea la zona y el certificado, que queda en estado pendiente.
2. Delegar en el registrador los nameservers del output `name_servers`.
3. `apply` con `validate_certificate = true`. Espera a que ACM complete la validación.

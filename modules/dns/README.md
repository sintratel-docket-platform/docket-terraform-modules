# `dns` module

Route 53 hosted zone and ACM certificate for the three environments.

The certificate covers the production host plus a wildcard that spans `staging` and `dev`, and any environment added later.

## Two-step activation

Certificate validation requires the nameservers to be delegated at the registrar already, and that delegation is a manual step with propagation latency. That is why `validate_certificate` is separate:

1. `apply` with `validate_certificate = false`. Creates the zone and the certificate, which stays pending.
2. Delegate the nameservers from the `name_servers` output at the registrar.
3. `apply` with `validate_certificate = true`. Waits for ACM to complete validation.

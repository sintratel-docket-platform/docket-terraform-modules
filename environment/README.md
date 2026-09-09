# `environment` module

SSM Parameter Store tree for one environment, under the `/docket/<environment>/` prefix.

## Inputs

| Variable | Type | Required | Purpose |
|---|---|---|---|
| `environment` | string | Yes | Determines the prefix. Validates that it is `dev`, `staging` or `prod` |
| `parameter_names` | list(string) | Yes | Parameters created under the prefix |
| `parameter_values` | map(string) | Yes | Write-only values indexed by parameter name. `sensitive` and `ephemeral` |
| `parameter_value_versions` | map(number) | Yes | Rotation version per parameter. Increment one to write that parameter again |
| `kms_key_id` | string | No, empty | Encryption key. Empty uses the AWS-managed key, at no cost |

## How values are handled

Parameters are written with the **write-only** argument `value_wo`, paired with `value_wo_version`. Terraform sends the value to the API and never persists it: not to state, not to the plan file.

Because Terraform cannot read a write-only value back, it cannot detect a change either. Rotating a secret means incrementing its entry in `parameter_value_versions`; without that, a new value in `parameter_values` is not written. That is the intended behaviour, not a defect.

`parameter_values` is declared `ephemeral`, so the value does not survive the run in any Terraform artifact.

This replaced an earlier pattern that wrote a placeholder and used `lifecycle { ignore_changes = [value] }`. The placeholder still reached state, and the real content lived entirely outside Terraform's model.

## Outputs

| Output | What it returns | Who consumes it |
|---|---|---|
| `parameter_prefix` | Tree prefix, `/docket/<environment>/` | The environment IRSA role policy |
| `parameter_arns` | ARNs of the created parameters | That same policy, to scope it to the prefix |

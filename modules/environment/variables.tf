variable "name_prefix" {
  description = "Prefix for every resource name this module creates. Keeps the module reusable: it names nothing after a particular project."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*$", var.name_prefix))
    error_message = "The prefix must be lowercase alphanumeric, optionally hyphen separated."
  }
}

variable "environment" {
  description = "Environment name. Determines the prefix of the parameter tree."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "The environment must be dev, staging or prod."
  }
}

variable "parameter_names" {
  description = "Parameter names created under the environment prefix."
  type        = list(string)
}

variable "parameter_value_versions" {
  description = "Rotation version indexed by parameter name; increment a value to write that parameter again."
  type        = map(number)
}

variable "parameter_values" {
  description = "Write-only values indexed by parameter name."
  type        = map(string)
  sensitive   = true
  ephemeral   = true
}

variable "kms_key_id" {
  description = "KMS key used to encrypt the parameters. Left empty, SSM uses the AWS-managed key, which has no cost."
  type        = string
  default     = ""
}

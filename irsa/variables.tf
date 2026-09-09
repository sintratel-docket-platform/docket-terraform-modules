variable "role_name" {
  description = "IAM role name."
  type        = string
}

variable "oidc_provider_arn" {
  description = "Cluster OIDC provider. It changes on every recreation."
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC provider URL without the scheme, which is the format the conditions are written in."
  type        = string
}

variable "namespace" {
  description = "Namespace of the authorised ServiceAccount."
  type        = string
}

variable "service_account" {
  description = "Name of the authorised ServiceAccount."
  type        = string
}

variable "policy_name" {
  description = "Name of the inline role policy."
  type        = string
  default     = ""
}

variable "policy_json" {
  description = "Role permission policy, as JSON. Empty when the role only carries managed policies."
  type        = string
  default     = ""
}

variable "managed_policy_arns" {
  description = "AWS managed policies attached to the role."
  type        = list(string)
  default     = []
}
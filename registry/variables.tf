variable "name_prefix" {
  description = "Prefix for every resource name this module creates. Keeps the module reusable: it names nothing after a particular project."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*$", var.name_prefix))
    error_message = "The prefix must be lowercase alphanumeric, optionally hyphen separated."
  }
}

variable "service_names" {
  description = "Microservice names. One ECR repository is created per name."
  type        = list(string)
}

variable "max_image_count" {
  description = "Number of images retained per repository. The ECR free tier covers 500 MB per month, so pruning is not optional."
  type        = number
  default     = 10
}

variable "scan_on_push" {
  description = "When true, ECR scans every published image for known vulnerabilities."
  type        = bool
  default     = true
}

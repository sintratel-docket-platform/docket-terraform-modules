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
  description = "Number of images retained per repository, among those no promotion has tagged. The ECR free tier covers 500 MB per month, so pruning is not optional."
  type        = number
  default     = 10
}

variable "max_promoted_image_count" {
  description = "Number of promoted images retained per repository. An environment's current version is always among its most recent promotions, so this bounds history, not what is deployed."
  type        = number
  default     = 20

  validation {
    condition     = var.max_promoted_image_count >= 1
    error_message = "At least one promoted image must be kept, or an environment can lose the image it declares."
  }
}

variable "promoted_tag_prefix" {
  description = "Tag prefix a promotion adds to the image it moves. Images carrying it are kept by max_promoted_image_count instead of max_image_count."
  type        = string
  default     = "promoted-"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9._-]*$", var.promoted_tag_prefix))
    error_message = "The prefix must be a valid start of an image tag."
  }
}

variable "scan_on_push" {
  description = "When true, ECR scans every published image for known vulnerabilities."
  type        = bool
  default     = true
}

variable "image_tag_mutability" {
  description = "Whether published tags can be overwritten. IMMUTABLE is what a GitOps promotion flow requires."
  type        = string
  default     = "IMMUTABLE"

  validation {
    condition     = contains(["IMMUTABLE", "MUTABLE"], var.image_tag_mutability)
    error_message = "Must be IMMUTABLE or MUTABLE."
  }
}

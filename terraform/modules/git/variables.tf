variable "name" {
  description = "Repository name"
  type        = string
}

variable "description" {
  description = "Repository description"
  type        = string
}

variable "visibility" {
  description = "Repository visibility: private or public"
  type        = string
  default     = "private"

  validation {
    condition     = contains(["private", "public"], var.visibility)
    error_message = "Visibility must be either 'private' or 'public'."
  }
}

variable "github_token" {
  description = "GitHub personal access token"
  type        = string
  sensitive   = true
}

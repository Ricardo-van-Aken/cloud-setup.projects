###############################
##   Remote State Bucket     ##
###############################

variable "region" {
  description = "DigitalOcean remote state bucket region."
  type        = string
  default     = "nyc1"
}

variable "bucket_name" {
  description = "DigitalOcean remote state bucket name."
  type        = string
}

################################
##   Provider Authorization   ##
################################

variable "github_repo_token" {
  description = "GitHub Personal Access Token for creating the github repository"
  type        = string
  sensitive   = true
}

variable "github_organization" {
  description = "Name of the GitHub organization"
  type        = string
}

###############################
##     Repository Inputs     ##
###############################

variable "repository_name" {
  description = "Name of the repository"
  type        = string
  default     = "example-project-1"
}

variable "repository_description" {
  description = "Description of the repository"
  type        = string
  default     = "Example project 1 repository managed via reusable module"
}

variable "repository_visibility" {
  description = "Repository visibility (public, private, internal)"
  type        = string
  default     = "private"
}

variable "template_owner" {
  description = "Owner of the template repository"
  type        = string
  default     = ""
}

variable "template_repository" {
  description = "Name of the template repository"
  type        = string
  default     = ""
}

variable "is_template" {
  description = "Whether to make this repository a template repository"
  type        = bool
  default     = false
}

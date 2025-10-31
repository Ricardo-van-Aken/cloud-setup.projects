variable "repository_name" {
  description = "Name of the GitHub repository to create"
  type        = string
}

variable "repository_description" {
  description = "Description of the repository"
  type        = string
  default     = ""
}

variable "repository_visibility" {
  description = "Repository visibility: public, private, or internal"
  type        = string
  default     = "private"
}

variable "is_template" {
  description = "Whether the repository is a template"
  type        = bool
  default     = false
}

variable "auto_init" {
  description = "Initialize the repository with a README so the default branch exists"
  type        = bool
  default     = true
}

variable "template_owner" {
  description = "Template repository owner"
  type        = string
  default     = ""
}

variable "template_repository" {
  description = "Template repository name"
  type        = string
  default     = ""
}

variable "repository_teams" {
  description = "Map of team bindings with permissions for the repository"
  type = map(object({
    team_id    = string
    permission = string # pull, triage, push, maintain, admin
  }))
  default = {}
}

variable "environment_review_teams" {
  description = "Map of environment name to list of team IDs that can approve deployments"
  type        = map(list(string))
  default = {
    staging    = []
    production = []
  }
}


output "repository_name" {
  description = "The name of the created repository"
  value       = github_repository.this.name
}

output "repository_full_name" {
  description = "The full name (owner/name) of the repository"
  value       = github_repository.this.full_name
}

output "environment_names" {
  description = "List of environments created"
  value       = keys(github_repository_environment.this)
}


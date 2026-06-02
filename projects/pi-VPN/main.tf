terraform {
  required_version = ">= 1.0"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.7.3"
    }
  }
  backend "s3" {}
}

provider "github" {
  token = var.github_repo_token
  owner = var.github_organization
}

data "terraform_remote_state" "github-org-config" {
  backend = "s3"
  config = {
    endpoints = {
      s3 = "https://${var.region}.digitaloceanspaces.com"
    }
    bucket                      = "${var.bucket_name}"
    key                         = "foundation/github-org-config/terraform.tfstate"
    region                      = "us-east-1"
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_s3_checksum            = true
    use_lockfile                = true
  }
}

resource "github_repository" "this" {
  name        = "pi-VPN"
  description = "Raspberry Pi VPN setup and configuration"
  visibility  = "private"
  is_template = false
  auto_init   = false
}

resource "github_team_repository" "devops_gouda" {
  team_id    = data.terraform_remote_state.github-org-config.outputs.devops_gouda_team_id
  repository = github_repository.this.name
  permission = "push"
}

resource "github_team_repository" "development_brie" {
  team_id    = data.terraform_remote_state.github-org-config.outputs.development_brie_team_id
  repository = github_repository.this.name
  permission = "push"
}

resource "github_team_repository" "qa_parmesan" {
  team_id    = data.terraform_remote_state.github-org-config.outputs.qa_parmesan_team_id
  repository = github_repository.this.name
  permission = "pull"
}

resource "github_branch_protection" "main" {
  repository_id = github_repository.this.name
  pattern       = "main"

  required_pull_request_reviews {
    required_approving_review_count = 1
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = true
  }

  required_status_checks {
    strict = true
  }

  enforce_admins = false
}

# Migrate state from the previous module-based layout. Resources not listed here
# (staging/production branches, their protections, environments) are intentionally
# absent from the config and will be destroyed on the next apply.
moved {
  from = module.github_repo.github_repository.this
  to   = github_repository.this
}

moved {
  from = module.github_repo.github_team_repository.this["devops_gouda"]
  to   = github_team_repository.devops_gouda
}

moved {
  from = module.github_repo.github_team_repository.this["development_brie"]
  to   = github_team_repository.development_brie
}

moved {
  from = module.github_repo.github_team_repository.this["qa_parmesan"]
  to   = github_team_repository.qa_parmesan
}

moved {
  from = module.github_repo.github_branch_protection.main
  to   = github_branch_protection.main
}

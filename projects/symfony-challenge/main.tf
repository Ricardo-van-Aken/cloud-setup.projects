terraform {
  required_version = ">= 1.0"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.8"
    }
  }
  backend "s3" {}
}

provider "github" {
  token = var.github_repo_token
  owner = var.github_organization
}


data "terraform_remote_state" "do-remote-state" {
  backend = "s3"
  config = {
    endpoints = {
      s3 = "https://${var.region}.digitaloceanspaces.com"
    }
    bucket                      = "${var.bucket_name}"
    key                         = "foundation/digitalocean-remote-state/terraform.tfstate"
    region                      = "us-east-1"
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_s3_checksum            = true
    use_lockfile                = true
  }
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
  name        = "symfony-challenge"
  description = "A small coding challenge in the Symfony PHP framework, part of my application for API Engineer at NEP Group Netherlands"
  visibility  = "private"
  is_template = false
  auto_init   = true
}

resource "github_team_repository" "development_brie" {
  team_id    = data.terraform_remote_state.github-org-config.outputs.development_brie_team_id
  repository = github_repository.this.name
  permission = "push"
}

# Mirror the organization-level secrets and variables onto the repository, in case the github plan does not support
# the use of organisation secrets/variables in private repositories. You can remove this part if you are using a
# github plan that does support this feature.
resource "github_actions_secret" "spaces_secret_key_ci" {
  repository      = github_repository.this.name
  secret_name     = "DO_STATE_BUCKET_SECRET_KEY"
  plaintext_value = data.terraform_remote_state.do-remote-state.outputs.bucket_spaces_secret_key_ci
}

resource "github_actions_variable" "spaces_access_key_ci" {
  repository    = github_repository.this.name
  variable_name = "DO_STATE_BUCKET_ACCESS_KEY"
  value         = data.terraform_remote_state.do-remote-state.outputs.bucket_spaces_access_key_ci
}

resource "github_actions_variable" "organization_name" {
  repository    = github_repository.this.name
  variable_name = "_GITHUB_ORGANIZATION_NAME"
  value         = var.github_organization
}

resource "github_actions_variable" "do_bucket_name" {
  repository    = github_repository.this.name
  variable_name = "DO_STATE_BUCKET_NAME"
  value         = data.terraform_remote_state.do-remote-state.outputs.bucket_name
}

resource "github_actions_variable" "do_bucket_region" {
  repository    = github_repository.this.name
  variable_name = "DO_STATE_BUCKET_REGION"
  value         = data.terraform_remote_state.do-remote-state.outputs.region
}

# Migrate state from the previous module-based layout. Resources not listed here
# (staging/production branches, all branch protections, environments, devops/qa teams)
# are intentionally absent from the config and will be destroyed on the next apply.
moved {
  from = module.github_repo.github_repository.this
  to   = github_repository.this
}

moved {
  from = module.github_repo.github_team_repository.this["development_brie"]
  to   = github_team_repository.development_brie
}

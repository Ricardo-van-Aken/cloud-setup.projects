terraform {
  required_version = ">= 1.0"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
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

module "github_repo" {
  source = "../../modules/github-repo"

  repository_name        = "starterkit.laravel-react-docker"
  repository_description = "Starterkit repository for Laravel, Inertia and React with Docker"
  repository_visibility  = "public"
  is_template            = true
  template_owner         = "Ricardo-van-Aken"
  template_repository    = "starterkit.laravel-react-docker"
  auto_init              = false

  # Grant teams repository access
  repository_teams = {
    # Team responsible for the projects infrastructure.
    devops_gouda = {
      team_id    = data.terraform_remote_state.github-org-config.outputs.devops_gouda_team_id
      permission = "push"
    }
    # Team responsible for the projects development.
    development_brie = {
      team_id    = data.terraform_remote_state.github-org-config.outputs.development_brie_team_id
      permission = "push"
    }
    # Team responsible for the projects QA(does not have push access).
    qa_parmesan = {
      team_id    = data.terraform_remote_state.github-org-config.outputs.qa_parmesan_team_id
      permission = "pull"
    }
  }

  # Require approvals from DevOps (production) and none for staging
  environment_review_teams = {
    staging    = []
    production = [
      data.terraform_remote_state.github-org-config.outputs.devops_gouda_team_id,
      data.terraform_remote_state.github-org-config.outputs.development_brie_team_id
    ]
  }
}

# Overwrite some private variables from the organization secrets by placing them in the repository secrets, in case
# the github plan does not support the use of organisation secrets in private repositories. You can remove this part
# if you are using a github plan that does support this feature.
resource "github_actions_secret" "spaces_secret_key_ci" {
  repository      = module.github_repo.repository_name
  secret_name     = "DO_STATE_BUCKET_SECRET_KEY"
  plaintext_value = data.terraform_remote_state.do-remote-state.outputs.bucket_spaces_secret_key_ci
}

# State recovery: the original state file was lost. These blocks re-adopt the
# existing GitHub resources into a fresh state. Remove after a successful apply.
import {
  to = module.github_repo.github_repository.this
  id = "starterkit.laravel-react-docker"
}

import {
  to = module.github_repo.github_branch.staging
  id = "starterkit.laravel-react-docker:staging:main"
}

import {
  to = module.github_repo.github_branch.production
  id = "starterkit.laravel-react-docker:production:staging"
}

import {
  to = module.github_repo.github_team_repository.this["devops_gouda"]
  id = "${data.terraform_remote_state.github-org-config.outputs.devops_gouda_team_id}:starterkit.laravel-react-docker"
}

import {
  to = module.github_repo.github_team_repository.this["development_brie"]
  id = "${data.terraform_remote_state.github-org-config.outputs.development_brie_team_id}:starterkit.laravel-react-docker"
}

import {
  to = module.github_repo.github_team_repository.this["qa_parmesan"]
  id = "${data.terraform_remote_state.github-org-config.outputs.qa_parmesan_team_id}:starterkit.laravel-react-docker"
}

import {
  to = module.github_repo.github_repository_environment.this["staging"]
  id = "starterkit.laravel-react-docker:staging"
}

import {
  to = module.github_repo.github_repository_environment.this["production"]
  id = "starterkit.laravel-react-docker:production"
}

import {
  to = module.github_repo.github_branch_protection.main
  id = "starterkit.laravel-react-docker:main"
}

import {
  to = module.github_repo.github_branch_protection.staging
  id = "starterkit.laravel-react-docker:staging"
}


import {
  to = github_actions_secret.spaces_secret_key_ci
  id = "starterkit.laravel-react-docker:DO_STATE_BUCKET_SECRET_KEY"
}
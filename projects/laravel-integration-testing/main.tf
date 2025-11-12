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

  repository_name        = "pest-plugin-integration-tests"
  repository_description = "Integration testing package for Laravel using Pest. This package makes requests with the X-TESTING header use a different database connection specifically for testing purposes.."
  repository_visibility  = "public"
  is_template            = true
  template_owner         = "pestphp"
  template_repository    = "pest-plugin-template"
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
      data.terraform_remote_state.github-org-config.outputs.devops_gouda_team_id
    ]
  }
}

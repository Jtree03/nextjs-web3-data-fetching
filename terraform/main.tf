terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
}

provider "cloudflare" {
  api_token = var.api_token
}

resource "cloudflare_pages_project" "next_project" {
  account_id        = var.account_id
  name              = var.project_name
  production_branch = var.production_branch

  build_config {
    build_command   = "next build \u0026\u0026 next export"
    destination_dir = "out"
    root_dir        = ""
  }

  source {
    type = var.repo_type
    config {
      owner                         = var.repo_owner
      repo_name                     = var.repo_name
      pr_comments_enabled           = true
      deployments_enabled           = true
      production_deployment_enabled = true
      production_branch             = var.production_branch
      preview_deployment_setting    = "all"
      preview_branch_excludes       = ["main"]
      preview_branch_includes = [
        "*"
      ]
    }
  }

  deployment_configs {
    preview {
      environment_variables = {
        "NODE_VERSION" : "16.18.0"
      }
    }
    production {
      environment_variables = {
        "NODE_VERSION" : "16.18.0"
      }
    }
  }

  lifecycle {
    ignore_changes = [
      build_config[0].web_analytics_tag,
      build_config[0].web_analytics_token
    ]
  }
}

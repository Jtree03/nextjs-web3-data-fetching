terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "cloudflare_pages_project" "next_project" {
  account_id        = var.cloudflare_account_id
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

resource "cloudflare_pages_domain" "pages_domain" {
  account_id   = var.cloudflare_account_id
  project_name = cloudflare_pages_project.next_project.name
  domain       = var.domain
}

data "aws_route53_zone" "route_zone" {
  name = var.aws_route53_name
}

resource "aws_route53_record" "cname_domain" {
  zone_id = data.aws_route53_zone.route_zone.zone_id
  name    = var.domain
  type    = "CNAME"
  ttl     = 86400
  records = [cloudflare_pages_project.next_project.domains[0]] # abc.pages.dev
}

output "domains" {
  value = cloudflare_pages_project.next_project.domains
}

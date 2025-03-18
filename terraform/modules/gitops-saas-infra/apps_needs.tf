################################################################################
# ECR repositories for Utilities
################################################################################
resource "aws_ecr_repository" "tenant_helm_chart" {
  name                 = var.tenant_helm_chart_repo
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "application_helm_chart" {
  name                 = var.application_helm_chart_repo
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "argoworkflow_container" {
  name                 = var.argoworkflow_container_repo
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

################################################################################
# Microsservices, ECR, CodeBuild and CodePipeline
################################################################################
resource "random_uuid" "this" {}

resource "aws_s3_bucket" "codeartifacts" {
  bucket        = "codestack-artifacts-bucket-${random_uuid.this.result}"
  force_destroy = true
}

# CodeCommit repositories (created when use_github = false)
module "codecommit" {
  source   = "lgallard/codecommit/aws"
  version  = "0.2.1"
  for_each = var.use_github ? {} : var.microservices

  repository_name = each.key
  description     = each.value.description
  default_branch  = try(each.value.default_branch, "main")
}

# GitHub repositories (created when use_github = true)
module "git_hub_repositories" {
  source       = "../git"
  for_each     = var.use_github ? var.microservices : {}
  name         = each.key
  description  = each.value.description
  visibility   = "private"
  github_token = var.github_token
}



resource "aws_ecr_repository" "microservice_container" {
  for_each = var.microservices

  name                 = each.key
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = each.key
    Description = each.value.description
  }
}

module "codebuild_project" {
  source   = "../codebuild"
  for_each = var.microservices

  vpc_id                 = var.vpc_id
  codebuild_project_name = each.value.codebuild_project_name
  private_subnet_list    = var.private_subnets
  bucket_id              = aws_s3_bucket.codeartifacts.id
  repo_uri               = aws_ecr_repository.microservice_container[each.key].repository_url
}

module "codepipeline" {
  source   = "../codepipeline"
  for_each = var.microservices

  pipeline_name      = each.value.pipeline_name
  codebuild_project  = module.codebuild_project[each.key].name
  repo_name          = var.use_github ? module.git_hub_repositories[each.key].name : module.codecommit[each.key].name
  bucket_id          = aws_s3_bucket.codeartifacts.id
  github_oauth_token = var.use_github ? var.github_token : null
  github_owner       = var.use_github ? var.github_owner : null
  use_github         = var.use_github
  branch_name        = "main"
}

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

module "codecommit" {
  source   = "lgallard/codecommit/aws"
  version  = "0.2.1"
  for_each = merge(var.microservices, { "${var.flux_repository_name}" = { description = "Flux GitOps repository", default_branch = "main" } })

  repository_name = each.key
  description     = each.value.description
  default_branch  = try(each.value.default_branch, "main")
}


module "git_hub_repositories" {
  source       = "../git"
  for_each     = var.microservices
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
  repo_name          = module.codecommit[each.key].name
  bucket_id          = aws_s3_bucket.codeartifacts.id
  github_oauth_token = var.github_token
  github_owner       = var.github_owner
  use_github         = var.use_github
  branch_name        = "main"
}

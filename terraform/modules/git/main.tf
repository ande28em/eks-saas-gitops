module "git_repository" {
  source  = "ksatirli/repository/github"
  name        = var.name
  description = var.description
  visibility = var.visibility
}
output "git_ssh_clone_url" {
  value = module.git_repository.github_repository.ssh_clone_url
}

output "git_https_clone_url" {
  value = module.git_repository.github_repository.http_clone_url
}


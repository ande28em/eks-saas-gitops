output "git_ssh_clone_url" {
  value = github_repository.main.ssh_clone_url
}

output "git_https_clone_url" {
  value = github_repository.main.http_clone_url
}

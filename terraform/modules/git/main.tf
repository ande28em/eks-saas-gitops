resource "github_repository" "main" {
  name        = var.name
  description = var.description
  visibility  = var.visibility
  auto_init   = true

  lifecycle {
    ignore_changes = [
      description,
      auto_init,
      visibility
    ]
  }
}

variable "name" {
  description = "Stack name"
  type        = string
  default     = "eks-saas-gitops"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "Amazon VPC CIDR Block"
  type        = string
  default     = "10.35.0.0/16"
}

variable "cluster_version" {
  description = "Amazon EKS Cluster version"
  type        = string
  default     = "1.30"
}

variable "public_key_file_path" {
  description = "Public key file path, used for clone CodeCommit repo, you should have private key locally"
  type        = string
  default     = ""
}

variable "clone_directory" {
  description = "Directory to clone CodeCommit repos"
  type        = string
  default     = "/tmp"
}

variable "flux2_sync_secret_values" {
  description = "This is created by install.sh script during execution"
  default     = "./flux-secrets.yaml"
}

variable "git_branch" {
  description = "Branch of the Git repository"
  type        = string
  default     = "main"
}

variable "kustomization_path" {
  description = "Path for Kustomization tool"
  type        = string
  default     = "gitops/clusters/production"
}

###### Git Provider
variable "github_owner" {
  default = "lusoal"
}

variable "github_personal_token" {
  description = "GitHub Personal Access Token"
  type        = string
  default     = ""
}
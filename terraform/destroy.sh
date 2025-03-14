#!/bin/bash

# Set the base directory to the parent directory of this script
BASE_DIR=$(dirname "$0")

# Parse the first argument for GitHub configuration
if [ -z "$1" ]; then
    read -p "Use GitHub? (true/false): " use_github_flag
else
    IFS=',' read -r use_github_flag github_token github_owner <<< "$1"
fi

USE_GITHUB=$(echo "$use_github_flag" | tr '[:upper:]' '[:lower:]')

if [ "$USE_GITHUB" = "true" ]; then
    # GitHub only needs token, owner, and clone directory
    if [ -z "$2" ]; then
        read -p "Enter the clone directory: " clone_directory
    else
        clone_directory=$2
    fi

    if [ -z "$github_token" ] || [ -z "$github_owner" ] || [ -z "$clone_directory" ]; then
        echo "GitHub token, owner, and clone directory are required when using GitHub."
        exit 1
    fi
else
    # CodeCommit needs SSH keys, known_hosts, and clone directory
    if [ -z "$2" ]; then
        read -p "Enter the path to your public key file: " public_key_file_path
    else
        public_key_file_path=$2
    fi

    if [ -z "$3" ]; then
        read -p "Enter the path to your private key file: " private_key_file_path
    else
        private_key_file_path=$3
    fi

    if [ -z "$4" ]; then
        read -p "Enter the path to your known hosts file: " known_hosts
    else
        known_hosts=$4
    fi

    if [ -z "$5" ]; then
        read -p "Enter the clone directory: " clone_directory
    else
        clone_directory=$5
    fi

    if [ -z "$public_key_file_path" ] || [ -z "$private_key_file_path" ] || [ -z "$clone_directory" ] || [ -z "$known_hosts" ]; then
        echo "SSH keys, clone directory, and known hosts are required for CodeCommit."
        exit 1
    fi
fi

# Navigate to the workshop directory
cd "$BASE_DIR/workshop" || exit

# Initialize Terraform first
echo "Initializing Terraform..."
terraform init

# Build the var arguments
VAR_ARGS="-var clone_directory=$clone_directory -var aws_region=${AWS_REGION:-us-east-1}"

if [ "$USE_GITHUB" = "true" ]; then
    VAR_ARGS="$VAR_ARGS -var use_github=true -var github_token=$github_token -var github_owner=$github_owner"
else
    VAR_ARGS="$VAR_ARGS -var use_github=false -var public_key_file_path=$public_key_file_path"
fi

# Run Terraform destroy
echo "Running Terraform destroy with arguments: $VAR_ARGS"
terraform destroy $VAR_ARGS -auto-approve

echo "Terraform destroy completed."

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


# Validate inputs based on GitHub vs CodeCommit
if [ "$USE_GITHUB" = true ]; then
    # GitHub only needs token, owner, and clone directory
    if [ -z "$GITHUB_TOKEN" ] || [ -z "$GITHUB_OWNER" ] || [ -z "$clone_directory" ]; then
        echo "GitHub token, owner, and clone directory are required when using GitHub."
        exit 1
    fi
else
    # CodeCommit needs SSH keys, known_hosts, and clone directory
    if [ -z "$public_key_file_path" ] || [ -z "$private_key_file_path" ] || [ -z "$clone_directory" ] || [ -z "$known_hosts" ]; then
        echo "SSH keys, clone directory, and known hosts are required for CodeCommit."
        exit 1
    fi
fi


# Path where values.yaml will be created
values_yaml_path="$BASE_DIR/workshop/flux-secrets.yaml"

# Create values.yaml with the provided information
cat <<EOF > "$values_yaml_path"
secret:
  create: true
  data:
    identity: |-
$(sed 's/^/      /' "$private_key_file_path")
    identity.pub: |-
$(sed 's/^/      /' "$public_key_file_path")
    known_hosts: |-
$(sed 's/^/      /' "$known_hosts")
EOF

echo "$values_yaml_path"

# Navigate to the workshop directory where the module implementations are
cd "$BASE_DIR/workshop" || exit

# Initialize Terraform
terraform init
terraform validate

# Define the list of modules and resources to apply in order
declare -a terraform_targets=(
    "module.vpc"
    "module.ebs_csi_irsa_role"
    "module.eks"
    "module.gitops_saas_infra"
    "null_resource.execute_templating_script"
    "module.flux_v2"
)

echo "Debug: USE_GITHUB = $USE_GITHUB"
if [ "$USE_GITHUB" = true ]; then
    echo "Debug: GITHUB_TOKEN = ${GITHUB_TOKEN:0:5}..." # Only show first 5 chars for security
    echo "Debug: GITHUB_OWNER = $GITHUB_OWNER"
fi
sleep 5
        
# Apply the Terraform configurations in the specified order
for target in "${terraform_targets[@]}"; do
    echo "Applying: $target"
    
    # Attempt counter
    attempt=1
    while [ $attempt -le 1 ]; do
        echo "Attempt $attempt of applying $target..."
        

                # Build the var arguments
        VAR_ARGS="-var public_key_file_path=$public_key_file_path \
                  -var clone_directory=$clone_directory \
                  -var aws_region=${AWS_REGION:-us-east-1}"
                  
                # Add GitHub-specific vars if using GitHub
        if [ "$USE_GITHUB" = true ]; then
            VAR_ARGS="$VAR_ARGS \
                      -var use_github=true \
                      -var github_token=$GITHUB_TOKEN \
                      -var github_owner=$GITHUB_OWNER"
        else
            VAR_ARGS="$VAR_ARGS -var use_github=false"
        fi

        # Run Terraform apply
        terraform apply -target="$target" $VAR_ARGS -auto-approve
        
        # Check if Terraform apply was successful
        if [ $? -eq 0 ]; then
            echo "$target applied successfully."
            break # Exit the loop if apply was successful
        else
            echo "Failed to apply $target, retrying..."
            ((attempt++)) # Increment attempt counter
            
            # Optional: Add a sleep here if you want to wait before retrying
            # sleep 10
        fi
        
        # If reached maximum attempts and still failed
        if [ $attempt -gt 1 ]; then
            echo "Failed to apply $target after 1 attempt."
            exit 1 # Exit script with error
        fi
    done
done

echo "All specified Terraform modules and resources have been applied."

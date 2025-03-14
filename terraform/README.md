# How to Provision This Stack

This comprehensive guide is designed to assist you in efficiently setting up and provisioning the necessary stack. By adhering to the outlined steps and recommendations, you'll facilitate a seamless setup experience.

## Prerequisites

Before initiating the setup process, please ensure the following tools are installed and configured on your system:


- **AWS Credentials**: Essential for authenticating AWS CLI and Terraform commands. [Configuration Guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
- **Key Pairs (Private and Public)**: Secure your connections with SSH keys. [SSH Key Generation Guide](https://en.wikibooks.org/wiki/Cryptography/Generate_a_keypair_using_OpenSSL)
- **GitHub Access Token** (if using GitHub repositories): The token will need the following permissions:
    - `repo`        "Full control of private repositories"
    - `delete_repo` "Delete repositories"
- **Helm**: The package manager for Kubernetes. [Installation Guide](https://helm.sh/docs/intro/install/)
- **Docker**: Docker is an open platform for developing, shipping, and running applications. [Installation Guide](https://docs.docker.com/engine/install/)
- **Terraform**: Automate infrastructure management with ease. [Installation Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- **Kubectl**: Interact with your Kubernetes cluster. [Installation Guide](https://kubernetes.io/docs/tasks/tools/)
- **Flux CLI**: Manage GitOps for your cluster. [Installation Guide](https://fluxcd.io/flux/installation/)
- **AWS CLI**: Control AWS services directly from your terminal. [Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

## Installation Steps

### Step 1: Configure SSH Known Hosts
To securely clone repositories, you must add AWS CodeCommit to your `known_hosts`. Replace `AWS_REGION` with your target AWS region:

```bash
export AWS_REGION=""
ssh-keyscan "git-codecommit.$AWS_REGION.amazonaws.com" >> ~/.ssh/known_hosts
```

### Step 2a: Run Install with GitHub (Recommended)
Use this option if you are provisioning within your own AWS account outside of an AWS event.

Replace the following variables with your own values:

- `REPO_PATH`: Where to clone the created CodeCommit repositories locally. eg. `/tmp/workshop`
- `GITHUB_TOKEN`: The access token you created.
- `GITHUB_OWNER`: Your GitHub username. 

```bash
export REPO_PATH=""
export GITHUB_TOKEN=""
export GITHUB_OWNER=""
```

Run `install.sh` with the environment variables. The `true` flag is setting a `use_github` flag.
```bash
sh install.sh "true,$GITHUB_TOKEN,$GITHUB_OWNER" $REPO_PATH
```

### Step 2b: Run Install with CodeCommit
This option is only meant for AWS provisioned environments. Do not use the CodeBuild options if you are running this outside of an AWS event.
```bash
export REPO_PATH=""
export PUBLIC_KEY=""
export PRIVATE_KEY=""
export KNOWN_HOSTS=""
```
Run `install.sh` with the environment variables. The `false` flag is setting a `use_github` flag.
```bash
sh install.sh "false" $PUBLIC_KEY $PRIVATE_KEY $REPO_PATH $KNOWN_HOSTS
```

### Step 3: Accessing the Environment

Post-installation, use the `configure_kubectl` Terraform output to connect to your Kubernetes cluster:

```bash
aws eks --region $AWS_REGION update-kubeconfig --name eks-saas-gitops
```

### Step 4: Create git ssh keys in EKS for Argo Workflows

Argo Workflows needs access to the git repository. Create a secret to store the private keys that Argo will use to clone and push changes to git during workflows.

```bash
kubectl create secret generic github-ssh-key --from-file=ssh-privatekey= ~/.ssh/id_rsa --from-literal=ssh-privatekey.mode=0600 -nargo-workflows --kubeconfig ~/.kube/config
```

## Ensuring Smooth Installation

To guarantee a smooth installation:

- Confirm the installation and configuration of all prerequisites.
- Verify the AWS region in `echo $AWS_REGION` matches your intended provision region.
- Ensure AWS credentials are correctly set to prevent any access or permission issues.

## Troubleshooting with quick_fix_flux.sh

Occasionally, you might encounter errors due to race conditions during the provisioning process, such as failed Helm releases. Typical errors include:

- Helm install failures due to webhook service unavailability.
- Artifacts not being stored correctly for certain Helm releases.

Should these or similar errors arise, run the `quick_fix_flux.sh` script to resolve them swiftly:

```bash
./quick_fix_flux.sh
```

This script dynamically identifies and deletes failed Helm releases, then reconciles your `flux-system` source to reattempt their installation. Running `quick_fix_flux.sh` ensures your environment stabilizes by rectifying transient errors that commonly occur due to race conditions during initial setup.

### How to Test the Architecture

For a detailed guide on deploying and testing the architecture, including the deployment of tenants, setting up SQS queues, and managing Kubernetes deployments, please refer to the following Workshop:

[Building SaaS applications on Amazon EKS using GitOps](https://catalog.workshops.aws/eks-saas-gitops).

## Cleanup
Follow the instructions below based on whether you are using GitHub or CodeCommit:
### GitHub:
```bash
sh destroy.sh "true,$GITHUB_TOKEN,$GITHUB_OWNER" $REPO_PATH
```
### CodeCommit
```bash
sh destroy.sh "false" $PUBLIC_KEY $PRIVATE_KEY $REPO_PATH $KNOWN_HOSTS
```
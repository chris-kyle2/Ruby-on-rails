# Makerble - Rails Application on Kubernetes

This repository contains the complete infrastructure and application code for deploying a Rails application on Kubernetes using GitOps principles.

## Project Structure

- `infrastructure/`: Terraform configurations for provisioning EC2-based Kubernetes cluster
- `docker/`: Docker configurations for containerizing the Rails application
- `rails-app/`: Rails application source code
- `k8s/`: Kubernetes manifests for application deployment
- `gitops/`: ArgoCD configurations for GitOps-based deployment
- `tekton/`: CI/CD pipeline configurations using Tekton
- `scripts/`: Helper scripts for cluster setup and management
- `assets/`: Visual documentation and resources

## Prerequisites

- AWS Account and configured AWS CLI
- Terraform
- Docker
- kubectl
- Helm
- kubeadm
- ArgoCD CLI
- Tekton CLI

## Getting Started

1. Set up infrastructure:
   ```bash
   cd infrastructure
   terraform init
   terraform apply
   ```

2. Build and push Docker image:
   ```bash
   cd docker
   docker-compose build
   docker push your-registry/rails-app:latest
   ```

3. Deploy ArgoCD:
   ```bash
   ./scripts/deploy-argocd.sh
   ```

4. Access ArgoCD UI:
   ```bash
   ./scripts/port-forward-argo.sh
   ```

5. Configure Tekton pipelines:
   ```bash
   kubectl apply -f tekton/
   ```

## Architecture

[Architecture diagram will be added here]

## Contributing

Please read CONTRIBUTING.md for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the LICENSE file for details. 
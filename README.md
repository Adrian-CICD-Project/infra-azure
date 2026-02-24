# Infrastructure – Azure DevOps Project

Provisioning AKS, ACR, VNet, ArgoCD (via script), and automation.

---

## Overview

This repository contains the complete Terraform IaC code responsible for provisioning the underlying Azure infrastructure required for the DevOps project:

- Azure Resource Group
- Virtual Network + AKS subnet
- Azure Container Registry (ACR)
- AKS clusters:
  - **devops-poc01-test**
  - **devops-poc01-prod**
- Automation Account + Runbook for daily cluster shutdown
- Output values for automation and CI/CD integration

> **Note:** ArgoCD is intentionally **NOT** deployed by Terraform.  
> Instead, it is provisioned using a post-deployment script (`install_argocd.sh`) to avoid Helm provider dependency cycles in Terraform and ensure stable AKS connectivity.

---

## Repository Structure

```
infra-azure/
├── main.tf
├── providers.tf
├── variables.tf
├── outputs.tf
├── envs/
│   ├── test.tfvars
│   └── prod.tfvars
├── modules/
│   ├── resource-group/
│   ├── network/
│   ├── acr/
│   ├── aks/
│   ├── auto-shutdown/
│   └── key-vault/
├── docs/
│   └── key-vault-external-secrets-setup.md
├── scripts/
│   ├── deploy.sh
│   ├── destroy.sh
│   ├── install-argocd.sh
│   └── check-infra.sh
```

---

## Deployment Flow

### Quick Start (Recommended)

1. **Login to Azure**
   ```bash
   az login
   ```

2. **Initialize Terraform**
   ```bash
   terraform init
   ```

3. **Run full deployment** (Terraform + ArgoCD + Verification)
   ```bash
   ./scripts/deploy.sh
   ```

This single command will:
- Deploy TEST cluster
- Deploy PROD cluster
- Install ArgoCD on both clusters
- Verify infrastructure status

### Manual Deployment

1. Deploy TEST cluster: `terraform apply -var-file=envs/test.tfvars -auto-approve`
2. Deploy PROD cluster: `terraform apply -var-file=envs/prod.tfvars -auto-approve`
3. Install ArgoCD: `./scripts/install-argocd.sh`
4. Verify status: `./scripts/check-infra.sh`

---

## Scripts

### deploy.sh

Full infrastructure deployment pipeline:
- Phase 1: Terraform plan/apply for TEST and PROD environments
- Phase 2: ArgoCD installation on both clusters
- Phase 3: Infrastructure verification

```bash
./scripts/deploy.sh
```

### destroy.sh

Destroys test + prod infrastructure:

```bash
./scripts/destroy.sh
```

### install-argocd.sh

Performs the following tasks:

- Fetch kubeconfig for both AKS clusters
- Create required namespaces
- Install/upgrade ArgoCD via Helm
- Wait for LoadBalancer IP
- Extract ArgoCD admin password
- Validate pods + services
- Validate ArgoCD Applications (if CRD exists)

```bash
./scripts/install-argocd.sh
```

ArgoCD UI will be available at: `http://<ARGOCD_PUBLIC_IP>`

| Credential | Value                    |
| ---------- | ------------------------ |
| username   | admin                    |
| password   | auto-fetched by script   |

### check-infra.sh

Validates:

- Resource Group
- ACR
- AKS state (Running/Stopped)
- ArgoCD pod health
- ArgoCD LB IP
- ArgoCD Applications (sync/health status)

```bash
./scripts/check-infra.sh
```

---

## Required Namespaces

The script automatically creates:

| Cluster            | Namespaces                        |
| ------------------ | --------------------------------- |
| devops-poc01-test  | environment-dev, environment-test |
| devops-poc01-prod  | environment-prod                  |

---

## Modules

### resource-group

Creates the Azure Resource Group.

### network

Creates:

- VNet `10.0.0.0/16`
- AKS Subnet `10.0.1.0/24`

### acr

Creates Azure Container Registry.

### aks

Creates AKS clusters with:

- Azure CNI
- Fixed service CIDR (no conflicts with VNet)
- Role assignment for ACR (AcrPull)

### auto-shutdown

Creates:

- Automation Account
- Runbook
- Schedule
- Daily shutdown of AKS clusters at 22:00 (Central European Time)

### key-vault

Creates:

- Azure Key Vault with RBAC authorization
- Role assignment `Key Vault Secrets User` for AKS kubelet identities
- Role assignment `Key Vault Secrets Officer` for Terraform identity

Used together with External Secrets Operator on AKS to securely deliver secrets (GitHub App keys, tokens) to Kubernetes without storing them in Git.

> **Full setup guide:** [docs/key-vault-external-secrets-setup.md](docs/key-vault-external-secrets-setup.md)

---

## Secrets

Application secrets (GitHub App keys, tokens) are stored in **Azure Key Vault** and delivered to AKS clusters via **External Secrets Operator**.

No secrets are stored in this repository or in Git history.

---

## Requirements

- Azure CLI
- Terraform >= 1.6
- Helm >= 3.x
- Bash (Linux/macOS or Git Bash on Windows)

---

## Cleanup

To remove everything:

```bash
./destroy.sh
```

Terraform will remove:

- AKS test
- AKS prod
- ACR
- VNet
- Automation account
- Resource group

---

## Author

Infrastructure code prepared as part of DevOps final project.  
Multi-environment IaC following GitOps-ready structure.

#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "========================================="
echo "  FULL INFRASTRUCTURE DEPLOYMENT"
echo "========================================="
echo ""

# ================================
# PHASE 1: TERRAFORM
# ================================
echo "=== PHASE 1: TERRAFORM ===" 
echo ""

echo "→ TEST PLAN"
terraform plan -var-file=envs/test.tfvars || exit 1

echo ""
echo "→ TEST APPLY"
terraform apply -var-file=envs/test.tfvars -auto-approve || exit 1

echo ""
echo "→ PROD PLAN"
terraform plan -var-file=envs/prod.tfvars || exit 1

echo ""
echo "→ PROD APPLY"
terraform apply -var-file=envs/prod.tfvars -auto-approve || exit 1

echo ""
echo "✅ Terraform deployment completed!"

# ================================
# PHASE 2: ARGOCD INSTALLATION
# ================================
echo ""
echo "=== PHASE 2: ARGOCD INSTALLATION ==="
echo ""

if [ -f "$SCRIPT_DIR/install-argocd.sh" ]; then
    bash "$SCRIPT_DIR/install-argocd.sh"
elif [ -f "$SCRIPT_DIR/install_argocd.sh" ]; then
    # Fallback for old naming
    bash "$SCRIPT_DIR/install_argocd.sh"
else
    echo "❌ ArgoCD installation script not found!"
    exit 1
fi

echo ""
echo "✅ ArgoCD installation completed!"

# ================================
# PHASE 3: VERIFICATION
# ================================
echo ""
echo "=== PHASE 3: INFRASTRUCTURE VERIFICATION ==="
echo ""

if [ -f "$SCRIPT_DIR/check-infra.sh" ]; then
    bash "$SCRIPT_DIR/check-infra.sh"
elif [ -f "$SCRIPT_DIR/check_infra.sh" ]; then
    # Fallback for old naming
    bash "$SCRIPT_DIR/check_infra.sh"
else
    echo "⚠️ Verification script not found, skipping..."
fi

echo ""
echo "========================================="
echo "  DEPLOYMENT COMPLETE!"
echo "========================================="
echo ""
echo "Next steps:"
echo "  1. Open ArgoCD UI (IP from check_infra output)"
echo "  2. Apply bootstrap manifests from platform-apps"
echo "  3. Configure GitHub App for repositories"
echo ""


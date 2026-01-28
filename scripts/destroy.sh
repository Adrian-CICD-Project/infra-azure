#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "========================================="
echo "  INFRASTRUCTURE DESTROY"
echo "========================================="
echo ""

echo "⚠️  WARNING: This will destroy ALL infrastructure!"
echo "    - TEST cluster"
echo "    - PROD cluster"
echo "    - ACR, VNet, Resource Group"
echo ""
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo "→ TEST DESTROY"
terraform destroy -var-file=envs/test.tfvars -auto-approve || exit 1

echo ""
echo "→ PROD DESTROY"
terraform destroy -var-file=envs/prod.tfvars -auto-approve || exit 1

echo ""
echo "========================================="
echo "  DESTROY COMPLETE"
echo "========================================="


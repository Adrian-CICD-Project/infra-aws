#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

echo "========================================="
echo "  FULL INFRASTRUCTURE DEPLOYMENT (AWS)"
echo "========================================="

# ================================
# PHASE 1: TERRAFORM
# (jeden stan tworzy oba klastry EKS – test + prod, jak w infra-azure)
# ================================
echo "=== PHASE 1: TERRAFORM ==="
terraform init
terraform plan  -var-file=envs/test.tfvars || exit 1
terraform apply -var-file=envs/test.tfvars -auto-approve || exit 1
echo "✅ Terraform deployment completed!"

# ================================
# PHASE 2: ARGOCD INSTALLATION
# ================================
echo "=== PHASE 2: ARGOCD INSTALLATION ==="
bash "$SCRIPT_DIR/install-argocd.sh"

# ================================
# PHASE 3: VERIFICATION
# ================================
echo "=== PHASE 3: INFRASTRUCTURE VERIFICATION ==="
bash "$SCRIPT_DIR/check-infra.sh" || true

echo "========================================="
echo "  DEPLOYMENT COMPLETE!"
echo "========================================="
